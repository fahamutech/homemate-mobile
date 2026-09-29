import 'dart:typed_data';

import 'package:homemate_mobile/core/contact/contact_launcher.dart';
import 'package:homemate_mobile/core/media/photo_source.dart';
import 'package:homemate_mobile/core/media/picked_photo.dart';
import 'package:homemate_mobile/core/media/webp_encoder.dart';
import 'package:homemate_mobile/core/network/api_exception.dart';
import 'package:homemate_mobile/features/partner_shared/data/enquiries_repository.dart';
import 'package:homemate_mobile/features/partner_shared/data/listings_repository.dart';
import 'package:homemate_mobile/features/partner_shared/data/money_repository.dart';
import 'package:homemate_mobile/features/partner_shared/data/onboarding_repository.dart';
import 'package:homemate_mobile/features/partner_shared/data/partner_application.dart';
import 'package:homemate_mobile/features/partner_shared/data/partner_enquiry.dart';
import 'package:homemate_mobile/features/partner_shared/data/partner_listing.dart';
import 'package:homemate_mobile/features/partner_shared/data/partner_money.dart';
import 'package:homemate_mobile/features/profile/data/identity_repository.dart';
import 'package:homemate_mobile/features/shared/models.dart';

/// The partner backend in memory (T03–T06), with the server's refusals.

ApiException _invalid(String message, [Map<String, dynamic> details = const {}]) =>
    ApiException(code: 'VALIDATION_FAILED', message: message, statusCode: 422, details: details);

/// The person's identity documents, shared by the customer and every role.
class FakeIdentityRepository implements IdentityRepository {
  String kycStatus = 'not_started';
  final List<IdentityDocument> documents = [];
  final List<String> uploads = [];

  bool has(String type) => documents.any((d) => d.documentType == type && d.status != 'rejected');

  @override
  Future<IdentityStatus> identity() async => IdentityStatus(kycStatus: kycStatus, documents: List.of(documents));

  @override
  Future<IdentityDocument> uploadDocument({
    required String documentType,
    required Uint8List bytes,
    required String contentType,
    String? filename,
  }) async {
    uploads.add(documentType);
    documents.removeWhere((d) => d.documentType == documentType);
    final document = IdentityDocument(id: 'doc-${documents.length + 1}', documentType: documentType, status: 'pending');
    documents.add(document);
    if (kycStatus == 'not_started') kycStatus = 'in_review';
    return document;
  }

  @override
  Future<void> setPhoto({required Uint8List bytes, required String contentType, String? filename}) async {}

  @override
  Future<CustomerPreferences> preferences() async => const CustomerPreferences();

  @override
  Future<CustomerPreferences> savePreferences(CustomerPreferences preferences) async => preferences;
}

class FakeOnboardingRepository implements OnboardingRepository {
  FakeOnboardingRepository({FakeIdentityRepository? identity}) : identity = identity ?? FakeIdentityRepository();

  final FakeIdentityRepository identity;
  PartnerProfile profile = const PartnerProfile(fullName: 'Baraka Mwinyi', nationalIdNumber: null);
  final Map<String, String> statuses = {};
  final Map<String, bool> details = {};
  final Map<String, String?> agreements = {};
  List<Remediation> remediations = [];
  String currentAgreementVersion = 'v1.0';
  final List<String> submitted = [];

  static const _brokerSteps = ['details', 'identity', 'payout', 'agreement'];
  static const _landlordSteps = ['details', 'identity', 'ownership', 'payout', 'agreement'];

  bool _complete(String role, String step) => switch (step) {
        'details' => details[role] ?? false,
        'identity' => profile.identityVerified || (identity.has('national_id') || identity.has('passport')) && identity.has('selfie'),
        'ownership' => identity.has('title_deed') || identity.has('utility_bill'),
        'payout' => profile.payout != null,
        'agreement' => agreements[role] == currentAgreementVersion,
        _ => false,
      };

  PartnerApplication application(String role) {
    final names = role == 'landlord' ? _landlordSteps : _brokerSteps;
    final steps = [for (final s in names) ApplicationStep(step: s, complete: _complete(role, s))];
    final missing = [for (final s in steps) if (!s.complete) s.step];
    final status = statuses[role] ?? 'not_started';
    return PartnerApplication(
      role: role,
      status: status,
      steps: steps,
      nextStep: missing.isEmpty ? null : missing.first,
      missingSteps: missing,
      canSubmit: missing.isEmpty && const {'applied', 'invited'}.contains(status),
      canDraftListings: status != 'not_started' && status != 'rejected' && status != 'suspended',
      canSubmitListings: status == 'active',
      identityVerified: profile.identityVerified,
      agreementVersion: agreements[role],
      currentAgreementVersion: currentAgreementVersion,
    );
  }

  @override
  Future<ApplicationsOverview> overview() async => ApplicationsOverview(
        profile: profile,
        applications: [application('broker'), application('landlord')],
        remediations: remediations,
        feeExample: const FeeExample(
          rent: 1200000,
          tenantFee: 600000,
          tenantFeePercentage: 50,
          platformAmount: 60000,
          platformPercentage: 10,
          youReceive: 540000,
        ),
      );

  @override
  Future<PartnerApplication> saveDetails(String role, PartnerDetails input) async {
    if (input.fullName.trim().isEmpty) throw _invalid('Please enter your full name');
    if (const {'pending_review', 'active'}.contains(statuses[role])) {
      throw ApiException(code: 'CONFLICT', message: 'This application is being reviewed', statusCode: 409);
    }
    profile = PartnerProfile(
      fullName: input.fullName,
      dateOfBirth: input.dateOfBirth,
      nationalIdNumber: input.nationalIdNumber,
      tinNumber: input.tinNumber,
      physicalAddress: input.physicalAddress,
      kycStatus: profile.kycStatus,
      payout: profile.payout,
    );
    details[role] = input.dateOfBirth != null && (input.nationalIdNumber ?? '').isNotEmpty && (input.physicalAddress ?? '').isNotEmpty;
    statuses[role] = statuses[role] == 'action_needed' ? 'action_needed' : 'applied';
    return application(role);
  }

  @override
  Future<PayoutAccount> savePayout(PayoutAccount payout) async {
    if ((payout.accountNumber ?? '').trim().isEmpty) throw _invalid('Enter the account number');
    if ((payout.accountName ?? '').trim().isEmpty) throw _invalid('Enter the name on the account');
    profile = PartnerProfile(
      fullName: profile.fullName,
      dateOfBirth: profile.dateOfBirth,
      nationalIdNumber: profile.nationalIdNumber,
      tinNumber: profile.tinNumber,
      physicalAddress: profile.physicalAddress,
      kycStatus: profile.kycStatus,
      payout: payout,
    );
    return payout;
  }

  @override
  Future<PartnerApplication> acceptAgreement(String role, String version) async {
    if (version != currentAgreementVersion) throw _invalid('Please accept the current agreement');
    agreements[role] = version;
    return application(role);
  }

  @override
  Future<PartnerApplication> submit(String role) async {
    final current = application(role);
    if (current.missingSteps.isNotEmpty) {
      throw _invalid('Finish these steps first: ${current.missingSteps.join(', ')}', {'missingSteps': current.missingSteps});
    }
    submitted.add(role);
    statuses[role] = 'pending_review';
    return application(role);
  }
}

class FakeListingsRepository implements ListingsRepository {
  final Map<String, PartnerListing> listings = {};
  final List<Map<String, dynamic>> saves = [];
  final Map<String, LandlordCard> landlords = {
    '+255754221908': const LandlordCard(userId: 'landlord-1', name: 'Hassan J.', phone: '+255 75* *** 908', homes: 3, status: 'active'),
  };
  final List<String> invited = [];
  bool roleActive = false;
  String viewer = 'broker';
  int _next = 1;

  PartnerListing _withRules(PartnerListing l) {
    final blockers = <SubmitBlocker>[
      if (!l.hasPin) const SubmitBlocker(code: 'missing_location', message: 'Drop the pin on the map.'),
      if (l.photos.isEmpty) const SubmitBlocker(code: 'no_photos', message: 'Add at least one photo.'),
      if (!roleActive) const SubmitBlocker(code: 'role_not_active', message: 'Your partner account is still being verified — you can submit once it is approved.'),
      if (viewer == 'broker' && l.landlord == null) const SubmitBlocker(code: 'no_landlord', message: 'Add the landlord of this home.'),
    ];
    final editable = const {'draft', 'changes_requested'}.contains(l.status);
    return _copy(l, submitBlockers: editable ? blockers : const [], canSubmit: editable && blockers.isEmpty, editable: editable);
  }

  /// A listing already in the fake, e.g. one "Changes requested".
  PartnerListing seed(PartnerListing listing) => listings[listing.id] = _withRules(listing);

  @override
  Future<List<PartnerListingSummary>> list({String? status}) async => [
        for (final l in listings.values)
          if (status == null || l.status == status)
            PartnerListingSummary(
              id: l.id,
              title: l.title,
              status: l.status,
              price: l.price,
              referenceCode: l.referenceCode,
              rejectionReason: l.rejectionReason,
              coverPhotoUrl: l.photos.isEmpty ? null : '/app/media/${l.photos.first.id}/raw',
            ),
      ];

  @override
  Future<PartnerListing> get(String id) async => listings[id] ?? (throw ApiException(code: 'NOT_FOUND', message: 'Listing not found', statusCode: 404));

  @override
  Future<PartnerListing> create(Map<String, dynamic> fields) async {
    if ('${fields['title'] ?? ''}'.trim().isEmpty) throw _invalid('Give the home a title');
    final id = 'listing-${_next++}';
    saves.add({'create': fields});
    final listing = _apply(PartnerListing(id: id, status: 'draft', referenceCode: 'HM-P-00000$id'), fields);
    return listings[id] = _withRules(listing);
  }

  @override
  Future<PartnerListing> update(String id, Map<String, dynamic> fields) async {
    final current = await get(id);
    if (!current.editable) throw ApiException(code: 'CONFLICT', message: 'This listing is with HomeMate', statusCode: 409);
    saves.add({id: fields});
    return listings[id] = _withRules(_apply(current, fields));
  }

  @override
  Future<PartnerListing> addPhoto(String id, PhotoUpload photo) async {
    final current = await get(id);
    final photos = [...current.photos, ListingPhoto(id: 'media-${current.photos.length + 1}', isCover: current.photos.isEmpty, position: current.photos.length)];
    return listings[id] = _withRules(_copy(current, photos: photos));
  }

  @override
  Future<PartnerListing> removePhoto(String id, String mediaId) async {
    final current = await get(id);
    final photos = [for (final p in current.photos) if (p.id != mediaId) p];
    return listings[id] = _withRules(_copy(current, photos: photos));
  }

  @override
  Future<PartnerListing> submit(String id) async {
    final current = await get(id);
    if (current.submitBlockers.isNotEmpty) {
      throw _invalid(current.submitBlockers.map((b) => b.message).join(' '), {
        'reasons': [for (final b in current.submitBlockers) {'code': b.code, 'message': b.message}],
      });
    }
    return listings[id] = _withRules(_copy(current, status: 'pending_review', submittedAt: DateTime(2026, 9, 27)));
  }

  @override
  Future<PartnerListing> archive(String id) async => listings[id] = _withRules(_copy(await get(id), status: 'archived'));

  @override
  Future<LandlordCard?> lookupLandlord(String phone) async => landlords[phone];

  @override
  Future<LandlordCard> inviteLandlord({required String fullName, required String phone}) async {
    invited.add(phone);
    return landlords[phone] = LandlordCard(userId: 'invited-${invited.length}', name: fullName, phone: phone, status: 'invited');
  }

  /// What the server's moneyPreview would say (fees.mjs), fixed for tests.
  static MoneyPreview _preview(double rent, double depositMonths, double advanceMonths) {
    final deposit = rent * depositMonths;
    final advance = rent * advanceMonths;
    final firstRent = advance > 0 ? advance : rent;
    final fee = rent * 0.5;
    return MoneyPreview(
      rent: rent,
      deposit: deposit,
      advance: advance,
      firstRent: firstRent,
      tenantFee: fee,
      tenantFeePercentage: 50,
      total: deposit + firstRent + fee,
      feeShare: fee * 0.9,
      youEarn: fee * 0.9,
    );
  }

  PartnerListing _apply(PartnerListing l, Map<String, dynamic> f) {
    T pick<T>(String key, T current) => f.containsKey(key) ? f[key] as T : current;
    final price = f.containsKey('price') ? (f['price'] as num).toDouble() : l.price;
    final deposit = f.containsKey('depositMonths') ? (f['depositMonths'] as num).toDouble() : l.depositMonths;
    final advance = f.containsKey('advanceRentMonths') ? (f['advanceRentMonths'] as num).toDouble() : l.advanceRentMonths;
    LandlordCard? landlord;
    if (f['landlordUserId'] is String) {
      landlord = landlords.values.firstWhere((c) => c.userId == f['landlordUserId']);
    }
    return _copy(
      l,
      title: pick<String?>('title', l.title),
      description: pick<String?>('description', l.description),
      listingType: pick<String?>('listingType', l.listingType),
      propertyTypeId: pick<String?>('propertyTypeId', l.propertyTypeId),
      bedrooms: pick<int?>('bedrooms', l.bedrooms),
      bathrooms: pick<int?>('bathrooms', l.bathrooms),
      furnishing: pick<String?>('furnishing', l.furnishing),
      regionId: pick<String?>('regionId', l.regionId),
      districtId: pick<String?>('districtId', l.districtId),
      wardId: pick<String?>('wardId', l.wardId),
      addressLine: pick<String?>('addressLine', l.addressLine),
      latitude: f.containsKey('latitude') ? (f['latitude'] as num?)?.toDouble() : l.latitude,
      longitude: f.containsKey('longitude') ? (f['longitude'] as num?)?.toDouble() : l.longitude,
      price: price,
      paymentFrequency: pick<String?>('paymentFrequency', l.paymentFrequency),
      depositMonths: deposit,
      advanceRentMonths: advance,
      minLeaseMonths: pick<int?>('minLeaseMonths', l.minLeaseMonths),
      amenityIds: f.containsKey('amenityIds') ? [for (final a in f['amenityIds'] as List) '$a'] : l.amenityIds,
      charges: f.containsKey('charges')
          ? [for (final c in f['charges'] as List) ListingCharge(name: '${c['name']}', amount: (c['amount'] as num).toDouble())]
          : l.charges,
      landlord: landlord == null ? l.landlord : ListingLandlord(userId: landlord.userId, name: landlord.name, confirmationStatus: 'pending'),
      moneyPreview: _preview(price, deposit, advance),
    );
  }

  PartnerListing _copy(
    PartnerListing l, {
    String? status,
    String? title,
    String? description,
    String? listingType,
    String? propertyTypeId,
    int? bedrooms,
    int? bathrooms,
    String? furnishing,
    String? regionId,
    String? districtId,
    String? wardId,
    String? addressLine,
    double? latitude,
    double? longitude,
    double? price,
    String? paymentFrequency,
    double? depositMonths,
    double? advanceRentMonths,
    int? minLeaseMonths,
    List<String>? amenityIds,
    List<ListingCharge>? charges,
    List<ListingPhoto>? photos,
    ListingLandlord? landlord,
    DateTime? submittedAt,
    bool? editable,
    List<SubmitBlocker>? submitBlockers,
    bool? canSubmit,
    MoneyPreview? moneyPreview,
  }) =>
      PartnerListing(
        id: l.id,
        status: status ?? l.status,
        referenceCode: l.referenceCode,
        title: title ?? l.title,
        description: description ?? l.description,
        listingType: listingType ?? l.listingType,
        propertyTypeId: propertyTypeId ?? l.propertyTypeId,
        bedrooms: bedrooms ?? l.bedrooms,
        bathrooms: bathrooms ?? l.bathrooms,
        furnishing: furnishing ?? l.furnishing,
        regionId: regionId ?? l.regionId,
        districtId: districtId ?? l.districtId,
        wardId: wardId ?? l.wardId,
        addressLine: addressLine ?? l.addressLine,
        latitude: latitude ?? l.latitude,
        longitude: longitude ?? l.longitude,
        price: price ?? l.price,
        paymentFrequency: paymentFrequency ?? l.paymentFrequency,
        depositMonths: depositMonths ?? l.depositMonths,
        advanceRentMonths: advanceRentMonths ?? l.advanceRentMonths,
        minLeaseMonths: minLeaseMonths ?? l.minLeaseMonths,
        amenityIds: amenityIds ?? l.amenityIds,
        charges: charges ?? l.charges,
        photos: photos ?? l.photos,
        landlord: landlord ?? l.landlord,
        rejectionReason: l.rejectionReason,
        createdAt: l.createdAt,
        submittedAt: submittedAt ?? l.submittedAt,
        reviewedAt: l.reviewedAt,
        editable: editable ?? l.editable,
        submitBlockers: submitBlockers ?? l.submitBlockers,
        canSubmit: canSubmit ?? l.canSubmit,
        moneyPreview: moneyPreview ?? l.moneyPreview,
      );
}

class FakeEnquiriesRepository implements EnquiriesRepository {
  final Map<String, PartnerEnquiry> enquiries = {};
  final List<(String, EnquiryOutcome, String?, String?)> responses = [];

  static const _tabs = {
    'new': {'pending'},
    'replied': {'responded'},
    'accepted': {'accepted'},
    'closed': {'rejected', 'withdrawn', 'closed'},
  };

  @override
  Future<List<PartnerEnquiry>> list({String? tab}) async =>
      [for (final e in enquiries.values) if (tab == null || _tabs[tab]!.contains(e.status)) e];

  @override
  Future<PartnerEnquiry> get(String id) async =>
      enquiries[id] ?? (throw ApiException(code: 'NOT_FOUND', message: 'Enquiry not found', statusCode: 404));

  @override
  Future<PartnerEnquiry> respond(String id, {required EnquiryOutcome outcome, String? response, String? rejectionReason}) async {
    final current = await get(id);
    if (!current.canAnswer) throw ApiException(code: 'FORBIDDEN', message: 'The broker who listed this home answers its enquiries', statusCode: 403);
    if (outcome == EnquiryOutcome.decline && (rejectionReason ?? '').trim().isEmpty) {
      throw _invalid('Say why you are declining');
    }
    responses.add((id, outcome, response, rejectionReason));
    return enquiries[id] = PartnerEnquiry(
      id: current.id,
      status: outcome.status,
      reference: current.reference,
      message: current.message,
      moveInDate: current.moveInDate,
      occupants: current.occupants,
      budgetAmount: current.budgetAmount,
      contactPreference: current.contactPreference,
      response: response,
      rejectionReason: rejectionReason,
      createdAt: current.createdAt,
      propertyId: current.propertyId,
      propertyTitle: current.propertyTitle,
      customerName: current.customerName,
      customerIdVerified: current.customerIdVerified,
      customerPhone: current.customerPhone,
      canAnswer: current.canAnswer,
    );
  }

  @override
  Future<EnquiryJourney> journey(String id) async {
    final enquiry = await get(id);
    final accepted = enquiry.status == 'accepted';
    return EnquiryJourney(
      enquiry: enquiry,
      steps: [
        EnquiryStep(key: 'enquiry_received', title: 'Enquiry received', state: 'done', at: enquiry.createdAt),
        EnquiryStep(key: 'decision', title: accepted ? 'Accepted' : 'Waiting for your answer', state: accepted ? 'done' : 'current'),
        EnquiryStep(key: 'awaiting_payment', title: 'Customer to pay', state: accepted ? 'current' : 'upcoming'),
        const EnquiryStep(key: 'payment_verified', title: 'Payment verified', state: 'upcoming'),
        const EnquiryStep(key: 'moved_in', title: 'Moved in', state: 'upcoming'),
        const EnquiryStep(key: 'ended', title: 'Tenancy ended', state: 'upcoming'),
      ],
      yourShare: 540000,
      firstRent: 1200000,
      deposit: 1200000,
      tenantFee: 600000,
      tenantFeePercentage: 50,
      total: 3000000,
    );
  }
}

class FakeMoneyRepository implements MoneyRepository {
  EarningsOverview overview = const EarningsOverview();
  final Map<String, EarningDetail> details = {};
  PayoutsOverview payoutList = const PayoutsOverview();
  PartnerSummary summaryResult = const PartnerSummary();
  final List<String> summaryCalls = [];

  @override
  Future<EarningsOverview> earnings(String role) async => overview;

  @override
  Future<EarningDetail> earning(String id) async =>
      details[id] ?? (throw ApiException(code: 'NOT_FOUND', message: 'Earning not found', statusCode: 404));

  @override
  Future<PayoutsOverview> payouts(String role) async => payoutList;

  @override
  Future<PartnerSummary> summary(String role) async {
    summaryCalls.add(role);
    return summaryResult;
  }
}

/// A camera roll with as many photos as a test asks for.
class FakePhotoSource implements PhotoSource {
  int picks = 0;
  bool cancelled = false;
  int many = 2;

  PickedPhoto _photo() => PickedPhoto(bytes: Uint8List.fromList([1, 2, 3, ++picks]), name: 'photo-$picks.jpg', contentType: 'image/jpeg');

  @override
  Future<PickedPhoto?> pick({bool camera = false}) async => cancelled ? null : _photo();

  @override
  Future<List<PickedPhoto>> pickMany() async => cancelled ? const [] : [for (var i = 0; i < many; i++) _photo()];
}

/// Pretends to re-encode, so a test can see the upload went through it.
class FakeWebpEncoder implements WebpEncoder {
  int encoded = 0;

  @override
  Future<Uint8List> encode(Uint8List bytes, {int maxSide = 1600}) async {
    encoded++;
    return bytes;
  }
}

/// Records calls and chats instead of leaving the app.
class FakeContactLauncher implements ContactLauncher {
  final List<String> calls = [];
  final List<String> chats = [];

  @override
  Future<bool> call(String phone) async {
    calls.add(phone);
    return true;
  }

  @override
  Future<bool> whatsApp(String phone, {String? message}) async {
    chats.add(phone);
    return true;
  }
}
