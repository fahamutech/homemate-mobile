import 'json_read.dart';

/// A row of "My listings" (BRK-020 / LND-020).
class PartnerListingSummary {
  const PartnerListingSummary({
    required this.id,
    required this.title,
    required this.status,
    this.referenceCode,
    this.price = 0,
    this.currency = 'TZS',
    this.coverPhotoUrl,
    this.openEnquiries = 0,
    this.landlordConfirmation,
    this.listedByYou = true,
    this.listedByName,
    this.rejectionReason,
    this.submittedAt,
  });

  final String id;
  final String title;

  /// `draft`, `pending_review`, `changes_requested`, `approved`, `rejected`,
  /// `rented`, `archived`.
  final String status;
  final String? referenceCode;
  final double price;
  final String currency;
  final String? coverPhotoUrl;
  final int openEnquiries;
  final String? landlordConfirmation;
  final bool listedByYou;
  final String? listedByName;
  final String? rejectionReason;
  final DateTime? submittedAt;

  factory PartnerListingSummary.fromJson(Map<String, dynamic> json) => PartnerListingSummary(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        status: json['status'] as String? ?? 'draft',
        referenceCode: json['referenceCode'] as String?,
        price: readNum(json['price']),
        currency: json['currency'] as String? ?? 'TZS',
        coverPhotoUrl: json['coverPhotoUrl'] as String?,
        openEnquiries: readInt(json['openEnquiries']),
        landlordConfirmation: json['landlordConfirmation'] as String?,
        listedByYou: readMap(json['listedBy'])['you'] as bool? ?? true,
        listedByName: readMap(json['listedBy'])['name'] as String?,
        rejectionReason: json['rejectionReason'] as String?,
        submittedAt: readDate(json['submittedAt']),
      );
}

class ListingPhoto {
  const ListingPhoto({required this.id, this.isCover = false, this.position = 0, this.url, this.thumbnailUrl});

  final String id;
  final bool isCover;
  final int position;
  final String? url;
  final String? thumbnailUrl;

  factory ListingPhoto.fromJson(Map<String, dynamic> json) => ListingPhoto(
        id: json['id'] as String? ?? '',
        isCover: json['isCover'] as bool? ?? false,
        position: readInt(json['position']),
        url: json['url'] as String?,
        thumbnailUrl: json['thumbnailUrl'] as String?,
      );
}

/// A charge on top of rent (service charge, garbage…).
class ListingCharge {
  const ListingCharge({required this.name, required this.amount, this.frequency = 'monthly', this.isMandatory = true});

  final String name;
  final double amount;
  final String frequency;
  final bool isMandatory;

  factory ListingCharge.fromJson(Map<String, dynamic> json) => ListingCharge(
        name: json['name'] as String? ?? '',
        amount: readNum(json['amount']),
        frequency: json['frequency'] as String? ?? 'monthly',
        isMandatory: json['isMandatory'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {'name': name, 'amount': amount, 'frequency': frequency, 'isMandatory': isMandatory};
}

/// Why a listing cannot be sent yet, in the server's words.
class SubmitBlocker {
  const SubmitBlocker({required this.code, required this.message});

  final String code;
  final String message;

  factory SubmitBlocker.fromJson(Map<String, dynamic> json) =>
      SubmitBlocker(code: json['code'] as String? ?? '', message: json['message'] as String? ?? '');
}

/// BRK-030c: what the tenant pays to move in and what the viewer earns, both
/// from the server (never worked out in the app).
class MoneyPreview {
  const MoneyPreview({
    this.rent = 0,
    this.deposit = 0,
    this.advance = 0,
    this.firstRent = 0,
    this.tenantFee = 0,
    this.tenantFeePercentage = 0,
    this.total = 0,
    this.feeShare = 0,
    this.rentAndDeposit = 0,
    this.youEarn = 0,
  });

  final double rent;
  final double deposit;
  final double advance;
  final double firstRent;
  final double tenantFee;
  final double tenantFeePercentage;
  final double total;
  final double feeShare;
  final double rentAndDeposit;
  final double youEarn;

  static MoneyPreview? fromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final earn = readMap(raw['youEarn']);
    return MoneyPreview(
      rent: readNum(raw['rent']),
      deposit: readNum(raw['deposit']),
      advance: readNum(raw['advance']),
      firstRent: readNum(raw['firstRent']),
      tenantFee: readNum(raw['tenantFee']),
      tenantFeePercentage: readNum(raw['tenantFeePercentage']),
      total: readNum(raw['total']),
      feeShare: readNum(earn['feeShare']),
      rentAndDeposit: readNum(earn['rentAndDeposit']),
      youEarn: readNum(earn['total']),
    );
  }
}

/// The landlord attached to a listing, as a broker sees them (masked).
class ListingLandlord {
  const ListingLandlord({required this.userId, this.name, this.phone, this.confirmationStatus, this.disputeReason});

  final String userId;
  final String? name;
  final String? phone;
  final String? confirmationStatus;
  final String? disputeReason;

  static ListingLandlord? fromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    return ListingLandlord(
      userId: raw['userId'] as String? ?? '',
      name: raw['name'] as String?,
      phone: raw['phone'] as String?,
      confirmationStatus: raw['confirmationStatus'] as String?,
      disputeReason: raw['disputeReason'] as String?,
    );
  }
}

/// One listing, as the wizard and the listing screen need it.
class PartnerListing {
  const PartnerListing({
    required this.id,
    required this.status,
    this.referenceCode,
    this.title = '',
    this.description,
    this.listingType = 'rent',
    this.propertyTypeId,
    this.propertyTypeName,
    this.bedrooms,
    this.bathrooms,
    this.sizeSqm,
    this.furnishing = 'unfurnished',
    this.regionId,
    this.regionName,
    this.districtId,
    this.districtName,
    this.wardId,
    this.wardName,
    this.addressLine,
    this.latitude,
    this.longitude,
    this.price = 0,
    this.currency = 'TZS',
    this.paymentFrequency = 'monthly',
    this.customPaymentMonths,
    this.depositMonths = 0,
    this.advanceRentMonths = 0,
    this.minLeaseMonths = 1,
    this.noticePeriodDays = 30,
    this.availableFrom,
    this.petsAllowed = false,
    this.smokingAllowed = false,
    this.maxOccupants,
    this.amenityIds = const [],
    this.charges = const [],
    this.photos = const [],
    this.landlord,
    this.brokerName,
    this.listedByYou = true,
    this.listedByName,
    this.landlordConfirmationStatus,
    this.rejectionReason,
    this.createdAt,
    this.submittedAt,
    this.reviewedAt,
    this.editable = true,
    this.submitBlockers = const [],
    this.canSubmit = false,
    this.moneyPreview,
  });

  final String id;
  final String status;
  final String? referenceCode;
  final String title;
  final String? description;
  final String listingType;
  final String? propertyTypeId;
  final String? propertyTypeName;
  final int? bedrooms;
  final int? bathrooms;
  final double? sizeSqm;
  final String furnishing;
  final String? regionId;
  final String? regionName;
  final String? districtId;
  final String? districtName;
  final String? wardId;
  final String? wardName;
  final String? addressLine;
  final double? latitude;
  final double? longitude;
  final double price;
  final String currency;
  final String paymentFrequency;
  final int? customPaymentMonths;
  final double depositMonths;
  final double advanceRentMonths;
  final int minLeaseMonths;
  final int noticePeriodDays;
  final DateTime? availableFrom;
  final bool petsAllowed;
  final bool smokingAllowed;
  final int? maxOccupants;
  final List<String> amenityIds;
  final List<ListingCharge> charges;
  final List<ListingPhoto> photos;
  final ListingLandlord? landlord;
  final String? brokerName;
  final bool listedByYou;
  final String? listedByName;
  final String? landlordConfirmationStatus;
  final String? rejectionReason;
  final DateTime? createdAt;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final bool editable;
  final List<SubmitBlocker> submitBlockers;
  final bool canSubmit;
  final MoneyPreview? moneyPreview;

  bool get hasPin => latitude != null && longitude != null;

  static int? _intOrNull(Object? v) => v == null ? null : readInt(v);
  static double? _numOrNull(Object? v) => v == null ? null : readNum(v);

  factory PartnerListing.fromJson(Map<String, dynamic> json) => PartnerListing(
        id: json['id'] as String? ?? '',
        status: json['status'] as String? ?? 'draft',
        referenceCode: json['referenceCode'] as String?,
        title: json['title'] as String? ?? '',
        description: json['description'] as String?,
        listingType: json['listingType'] as String? ?? 'rent',
        propertyTypeId: json['propertyTypeId'] as String?,
        propertyTypeName: json['propertyTypeName'] as String?,
        bedrooms: _intOrNull(json['bedrooms']),
        bathrooms: _intOrNull(json['bathrooms']),
        sizeSqm: _numOrNull(json['sizeSqm']),
        furnishing: json['furnishing'] as String? ?? 'unfurnished',
        regionId: json['regionId'] as String?,
        regionName: json['regionName'] as String?,
        districtId: json['districtId'] as String?,
        districtName: json['districtName'] as String?,
        wardId: json['wardId'] as String?,
        wardName: json['wardName'] as String?,
        addressLine: json['addressLine'] as String?,
        latitude: _numOrNull(json['latitude']),
        longitude: _numOrNull(json['longitude']),
        price: readNum(json['price']),
        currency: json['currency'] as String? ?? 'TZS',
        paymentFrequency: json['paymentFrequency'] as String? ?? 'monthly',
        customPaymentMonths: _intOrNull(json['customPaymentMonths']),
        depositMonths: readNum(json['depositMonths']),
        advanceRentMonths: readNum(json['advanceRentMonths']),
        minLeaseMonths: readInt(json['minLeaseMonths'] ?? 1),
        noticePeriodDays: readInt(json['noticePeriodDays'] ?? 30),
        availableFrom: readDate(json['availableFrom']),
        petsAllowed: json['petsAllowed'] as bool? ?? false,
        smokingAllowed: json['smokingAllowed'] as bool? ?? false,
        maxOccupants: _intOrNull(json['maxOccupants']),
        amenityIds: [for (final a in (json['amenities'] as List? ?? const [])) if (a is Map) '${a['id']}'],
        charges: readList(json['charges'], ListingCharge.fromJson),
        photos: readList(json['photos'], ListingPhoto.fromJson)..sort((a, b) => a.position.compareTo(b.position)),
        landlord: ListingLandlord.fromJson(json['landlord']),
        brokerName: readMap(json['broker'])['name'] as String?,
        listedByYou: readMap(json['listedBy'])['you'] as bool? ?? true,
        listedByName: readMap(json['listedBy'])['name'] as String?,
        landlordConfirmationStatus: readMap(json['landlordConfirmation'])['status'] as String?,
        rejectionReason: json['rejectionReason'] as String?,
        createdAt: readDate(readMap(json['statusHistory'])['createdAt'] ?? json['createdAt']),
        submittedAt: readDate(json['submittedAt']),
        reviewedAt: readDate(json['reviewedAt']),
        editable: json['editable'] as bool? ?? false,
        submitBlockers: readList(json['submitBlockers'], SubmitBlocker.fromJson),
        canSubmit: json['canSubmit'] as bool? ?? false,
        moneyPreview: MoneyPreview.fromJson(json['moneyPreview']),
      );
}

/// A landlord found by phone (masked), or just invited.
class LandlordCard {
  const LandlordCard({required this.userId, this.name, this.phone, this.homes = 0, this.status});

  final String userId;
  final String? name;
  final String? phone;
  final int homes;
  final String? status;

  static LandlordCard? fromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    return LandlordCard(
      userId: raw['userId'] as String? ?? '',
      name: raw['name'] as String?,
      phone: raw['phone'] as String?,
      homes: readInt(raw['homes']),
      status: raw['status'] as String?,
    );
  }
}

/// A new photo, already a WebP, as base64 (every app upload is JSON).
class PhotoUpload {
  const PhotoUpload({required this.bytes, this.name = 'photo.webp', this.contentType = 'image/webp'});

  final List<int> bytes;
  final String name;
  final String contentType;
}
