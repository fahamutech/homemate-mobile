import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:homemate_mobile/core/i18n/app_locale.dart';
import 'package:homemate_mobile/core/i18n/app_text.dart';
import 'package:homemate_mobile/core/i18n/locale_controller.dart';
import 'package:homemate_mobile/core/i18n/locale_store.dart';
import 'package:homemate_mobile/core/network/api_exception.dart';
import 'package:homemate_mobile/core/providers.dart';
import 'package:homemate_mobile/design/theme.dart';
import 'package:homemate_mobile/features/auth/data/auth_repository.dart';
import 'package:homemate_mobile/features/auth/data/customer.dart';
import 'package:homemate_mobile/features/auth/data/session_store.dart';
import 'package:homemate_mobile/features/shared/activity_repository.dart';
import 'package:homemate_mobile/core/location/location_providers.dart';
import 'package:homemate_mobile/core/location/location_service.dart';
import 'package:homemate_mobile/features/shared/catalogue_repository.dart';
import 'package:homemate_mobile/features/shared/journey_models.dart';
import 'package:homemate_mobile/features/shared/journey_repository.dart';
import 'package:homemate_mobile/features/shared/models.dart';

/// A whole backend, in memory.
///
/// The app talks to two repositories and an auth repository, so a fake of each
/// is the entire surface — no HTTP stubs, no golden JSON files. The fakes
/// mirror the *server's* rules, including the refusals, so a screen that looks
/// right on a happy path but mishandles a conflict fails here.

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.code = '123456'});

  final String code;

  /// Numbers that already have a PIN, so login succeeds.
  final Map<String, String> pins = {};
  Customer customer = const Customer(
    id: 'cust-1',
    phoneNumber: '+255712345678',
    fullName: 'Neema Kileo',
    hasPin: true,
    onboardingComplete: true,
  );

  final List<String> sentTo = [];
  int failedLogins = 0;

  /// Set to make the next call fail, the way the server would.
  ApiException? nextFailure;

  ApiException? _takeFailure() {
    final failure = nextFailure;
    nextFailure = null;
    return failure;
  }

  @override
  Future<OtpChallenge> requestOtp({required String phoneNumber, String purpose = 'login'}) async {
    if (_takeFailure() case final failure?) throw failure;
    // A reset for an unknown number answers identically but sends nothing.
    if (purpose == 'reset_pin' && !pins.containsKey(phoneNumber)) {
      return const OtpChallenge(challengeId: null);
    }
    sentTo.add(phoneNumber);
    return const OtpChallenge(challengeId: 'challenge-1', resendAfterSeconds: 60);
  }

  @override
  Future<PhoneVerification> verifyOtp({required String challengeId, required String code}) async {
    if (_takeFailure() case final failure?) throw failure;
    if (code != this.code) {
      throw ApiException(
        code: 'VALIDATION_FAILED',
        message: 'That code is not right — 4 tries left',
        statusCode: 422,
      );
    }
    return const PhoneVerification(
      verificationToken: 'verify-token',
      hasPin: false,
      onboardingComplete: false,
    );
  }

  @override
  Future<AuthSession> setPin({
    required String verificationToken,
    required String pin,
    required String confirmPin,
  }) async {
    if (_takeFailure() case final failure?) throw failure;
    pins[customer.phoneNumber] = pin;
    return AuthSession(token: 'session-token', customer: customer);
  }

  @override
  Future<AuthSession> resetPin({
    required String verificationToken,
    required String pin,
    required String confirmPin,
  }) =>
      setPin(verificationToken: verificationToken, pin: pin, confirmPin: confirmPin);

  @override
  Future<AuthSession> login({required String phoneNumber, required String pin}) async {
    if (_takeFailure() case final failure?) throw failure;
    if (pins[phoneNumber] != pin) {
      failedLogins++;
      throw ApiException(
        code: 'UNAUTHORIZED',
        message: 'That phone number and PIN do not match',
        statusCode: 401,
      );
    }
    return AuthSession(token: 'session-token', customer: customer);
  }

  @override
  Future<Customer> me() async {
    if (_takeFailure() case final failure?) throw failure;
    return customer;
  }

  @override
  Future<Customer> completeProfile({
    required String fullName,
    String? email,
    String preferredLanguage = 'en',
    DateTime? dateOfBirth,
    String? gender,
  }) async {
    if (_takeFailure() case final failure?) throw failure;
    customer = customer.copyWith(
      fullName: fullName,
      email: email,
      preferredLanguage: preferredLanguage,
      dateOfBirth: dateOfBirth,
      gender: gender,
      onboardingComplete: true,
    );
    return customer;
  }

  @override
  Future<void> changePin({
    required String currentPin,
    required String pin,
    required String confirmPin,
  }) async {
    if (_takeFailure() case final failure?) throw failure;
    if (pins[customer.phoneNumber] != currentPin) {
      throw ApiException(
        code: 'UNAUTHORIZED',
        message: 'Your current PIN is not right',
        statusCode: 401,
      );
    }
    pins[customer.phoneNumber] = pin;
  }
}

PropertySummary fakeProperty({
  String id = 'prop-1',
  String title = 'Masaki 2BR Apartment',
  double price = 800000,
  bool isSaved = false,
  double? latitude = -6.7576,
  double? longitude = 39.2768,
  double? distanceMetres,
}) =>
    PropertySummary(
      id: id,
      referenceCode: 'HM-P-000001',
      title: title,
      price: price,
      bedrooms: 2,
      bathrooms: 1,
      addressLine: 'Masaki, Kinondoni',
      districtName: 'Kinondoni',
      wardName: 'Masaki',
      regionName: 'Dar es Salaam',
      isSaved: isSaved,
      latitude: latitude,
      longitude: longitude,
      distanceMetres: distanceMetres,
    );

class FakeCatalogueRepository implements CatalogueRepository {
  FakeCatalogueRepository({List<PropertySummary>? properties})
      : properties = properties ?? [fakeProperty()];

  List<PropertySummary> properties;
  final Set<String> savedIds = {};
  final List<PropertyFilters> searches = [];
  ApiException? nextFailure;

  ApiException? _takeFailure() {
    final failure = nextFailure;
    nextFailure = null;
    return failure;
  }

  @override
  Future<Paged<PropertySummary>> search(
    PropertyFilters filters, {
    int limit = 20,
    int offset = 0,
  }) async {
    if (_takeFailure() case final failure?) throw failure;
    searches.add(filters);

    // Enough of the server's filtering to make a filter test mean something.
    final matches = properties.where((property) {
      if (filters.query case final query? when query.isNotEmpty) {
        if (!property.title.toLowerCase().contains(query.toLowerCase())) return false;
      }
      if (filters.minPrice case final min? when (property.price ?? 0) < min) return false;
      if (filters.maxPrice case final max? when (property.price ?? 0) > max) return false;
      if (filters.bedrooms case final bedrooms? when (property.bedrooms ?? 0) < bedrooms) {
        return false;
      }
      return true;
    }).map((property) => property.copyWith(isSaved: savedIds.contains(property.id)));

    return Paged(items: matches.toList(), total: matches.length);
  }

  @override
  Future<PropertyDetail> detail(String propertyId) async {
    if (_takeFailure() case final failure?) throw failure;
    final property = properties.firstWhere(
      (candidate) => candidate.id == propertyId,
      orElse: () => throw ApiException(
        code: 'NOT_FOUND',
        message: 'Property not found',
        statusCode: 404,
      ),
    );
    return PropertyDetail(
      summary: property,
      description: 'Bright and airy, close to the sea.',
      amenities: const [NamedItem(id: 'a1', name: 'Parking')],
      landlordName: 'Baraka Mushi',
      isSaved: savedIds.contains(propertyId),
      depositMonths: 2,
      minLeaseMonths: 12,
      paymentFrequency: 'monthly',
    );
  }

  @override
  Future<Paged<PropertySummary>> saved({int limit = 20, int offset = 0}) async {
    final items = properties.where((property) => savedIds.contains(property.id)).toList();
    return Paged(items: items, total: items.length);
  }

  @override
  Future<void> save(String propertyId, {String? note}) async {
    if (_takeFailure() case final failure?) throw failure;
    savedIds.add(propertyId);
  }

  @override
  Future<void> unsave(String propertyId) async => savedIds.remove(propertyId);

  @override
  Future<ReferenceData> reference() async => referenceData;

  /// The dictionaries the pickers are built from. Two of each is enough for a
  /// test to prove a chip filters; a fixture that mirrors the seed data would
  /// just be the seed data, maintained twice.
  ReferenceData referenceData = const ReferenceData(
    propertyTypes: [
      ReferenceItem(id: 'type-apartment', name: 'Apartment', code: 'apartment'),
      ReferenceItem(id: 'type-house', name: 'House', code: 'house'),
    ],
    amenities: [
      ReferenceItem(id: 'amenity-wifi', name: 'Wi-Fi', code: 'wifi'),
      ReferenceItem(id: 'amenity-parking', name: 'Parking', code: 'parking'),
    ],
    regions: [ReferenceItem(id: 'region-dar', name: 'Dar es Salaam', code: 'dar')],
    districts: [
      ReferenceItem(
        id: 'district-kinondoni',
        name: 'Kinondoni',
        code: 'kinondoni',
        parentId: 'region-dar',
      ),
    ],
    wards: [
      ReferenceItem(
        id: 'ward-masaki',
        name: 'Masaki',
        code: 'masaki',
        parentId: 'district-kinondoni',
      ),
    ],
  );

  @override
  Future<List<GeoPlace>> searchPlaces(String query) async => [
        GeoPlace(displayName: '$query, Dar es Salaam', latitude: -6.79, longitude: 39.2),
      ];

  @override
  String imageUrl(String mediaId, {bool thumbnail = false}) => 'https://example.test/$mediaId';
}

class FakeActivityRepository implements ActivityRepository {
  final List<Inquiry> inquiryList = [];
  final List<Viewing> viewingList = [];
  final List<Booking> bookingList = [];
  final List<CustomerPayment> paymentList = [];
  final List<AppNotification> notificationList = [];

  ActivitySummary summaryValue = const ActivitySummary();
  ApiException? nextFailure;
  int sequence = 0;

  ApiException? _takeFailure() {
    final failure = nextFailure;
    nextFailure = null;
    return failure;
  }

  @override
  Future<Paged<Inquiry>> inquiries({String? status, int limit = 20, int offset = 0}) async {
    if (_takeFailure() case final failure?) throw failure;
    final items = inquiryList.where((i) => status == null || i.status == status).toList();
    return Paged(items: items, total: items.length);
  }

  @override
  Future<Inquiry> inquiry(String id) async =>
      inquiryList.firstWhere((candidate) => candidate.id == id);

  @override
  Future<Inquiry> createInquiry({
    required String propertyId,
    required String message,
    DateTime? moveInDate,
    double? budgetAmount,
    int? occupants,
    String? contactPreference,
    String? preferredContactTime,
  }) async {
    if (_takeFailure() case final failure?) throw failure;
    // The server refuses a second open enquiry for the same property.
    if (inquiryList.any((i) => i.propertyId == propertyId && i.isOpen)) {
      throw ApiException(
        code: 'CONFLICT',
        message: 'You already have an open enquiry for this property',
        statusCode: 409,
      );
    }
    final inquiry = Inquiry(
      id: 'inq-${++sequence}',
      reference: 'HM-INQ-00000$sequence',
      status: 'pending',
      message: message,
      createdAt: DateTime.now(),
      propertyId: propertyId,
      propertyTitle: 'Masaki 2BR Apartment',
      moveInDate: moveInDate,
      occupants: occupants,
    );
    inquiryList.add(inquiry);
    return inquiry;
  }

  @override
  Future<Inquiry> withdrawInquiry(String id) async {
    final index = inquiryList.indexWhere((candidate) => candidate.id == id);
    final existing = inquiryList[index];
    final updated = Inquiry(
      id: existing.id,
      reference: existing.reference,
      status: 'withdrawn',
      message: existing.message,
      createdAt: existing.createdAt,
      propertyId: existing.propertyId,
      propertyTitle: existing.propertyTitle,
    );
    inquiryList[index] = updated;
    return updated;
  }

  @override
  Future<Paged<Viewing>> viewings({
    String? status,
    bool upcomingOnly = false,
    int limit = 20,
    int offset = 0,
  }) async {
    if (_takeFailure() case final failure?) throw failure;
    final items =
        viewingList.where((v) => !upcomingOnly || v.scheduledFor.isAfter(DateTime.now())).toList();
    return Paged(items: items, total: items.length);
  }

  @override
  Future<Viewing> viewing(String id) async =>
      viewingList.firstWhere((candidate) => candidate.id == id);

  @override
  Future<Viewing> requestViewing({
    required String propertyId,
    required DateTime scheduledFor,
    String? inquiryId,
    int? durationMinutes,
    String? meetingPoint,
    String? note,
  }) async {
    if (_takeFailure() case final failure?) throw failure;
    if (scheduledFor.isBefore(DateTime.now())) {
      throw ApiException(
        code: 'VALIDATION_FAILED',
        message: 'A viewing cannot be scheduled in the past',
        statusCode: 422,
      );
    }
    final viewing = Viewing(
      id: 'vw-${++sequence}',
      reference: 'HM-VW-00000$sequence',
      status: 'requested',
      scheduledFor: scheduledFor,
      propertyId: propertyId,
      propertyTitle: 'Masaki 2BR Apartment',
      hostName: 'Baraka Mushi',
      meetingPoint: meetingPoint,
      isUpcoming: true,
    );
    viewingList.add(viewing);
    return viewing;
  }

  @override
  Future<Viewing> cancelViewing(String id, String reason) async {
    final index = viewingList.indexWhere((candidate) => candidate.id == id);
    final existing = viewingList[index];
    final updated = Viewing(
      id: existing.id,
      reference: existing.reference,
      status: 'cancelled',
      scheduledFor: existing.scheduledFor,
      propertyId: existing.propertyId,
      propertyTitle: existing.propertyTitle,
      cancellationReason: reason,
    );
    viewingList[index] = updated;
    return updated;
  }

  @override
  Future<Paged<Booking>> bookings({String? status, int limit = 20, int offset = 0}) async {
    if (_takeFailure() case final failure?) throw failure;
    return Paged(items: bookingList, total: bookingList.length);
  }

  @override
  Future<Booking> booking(String id) async =>
      bookingList.firstWhere((candidate) => candidate.id == id);

  @override
  Future<Booking> createBooking({
    required String propertyId,
    String? inquiryId,
    String? viewingId,
    DateTime? moveInDate,
    int? leaseMonths,
    String? notes,
  }) async {
    if (_takeFailure() case final failure?) throw failure;
    final payment = CustomerPayment(
      id: 'pay-${++sequence}',
      reference: 'HM-PAY-00000$sequence',
      amount: 2400000,
      currency: 'TZS',
      status: 'pending',
      customerState: 'awaiting_instructions',
      purpose: 'deposit',
      bookingId: 'bk-$sequence',
    );
    paymentList.add(payment);

    final booking = Booking(
      id: 'bk-$sequence',
      reference: 'HM-BK-00000$sequence',
      status: 'awaiting_payment',
      monthlyRent: 800000,
      totalDue: 2400000,
      amountPaid: 0,
      amountOutstanding: 2400000,
      depositAmount: 1600000,
      propertyId: propertyId,
      propertyTitle: 'Masaki 2BR Apartment',
      moveInDate: moveInDate,
      leaseMonths: leaseMonths,
      payments: [payment],
    );
    bookingList.add(booking);
    return booking;
  }

  @override
  Future<Booking> cancelBooking(String id, String reason) async {
    final index = bookingList.indexWhere((candidate) => candidate.id == id);
    final existing = bookingList[index];
    final updated = Booking(
      id: existing.id,
      reference: existing.reference,
      status: 'cancelled',
      monthlyRent: existing.monthlyRent,
      totalDue: existing.totalDue,
      amountPaid: existing.amountPaid,
      amountOutstanding: existing.amountOutstanding,
      propertyTitle: existing.propertyTitle,
      cancellationReason: reason,
      payments: existing.payments,
    );
    bookingList[index] = updated;
    return updated;
  }

  @override
  Future<Paged<CustomerPayment>> payments({String? state, int limit = 20, int offset = 0}) async =>
      Paged(items: paymentList, total: paymentList.length);

  @override
  Future<CustomerPayment> payment(String id) async =>
      paymentList.firstWhere((candidate) => candidate.id == id);

  /// Mirrors the server: a claim never settles anything, and it is refused
  /// until an operator has published where to pay.
  @override
  Future<CustomerPayment> declarePaid(String id, {String? reference, String? note}) async {
    if (_takeFailure() case final failure?) throw failure;
    final index = paymentList.indexWhere((candidate) => candidate.id == id);
    final existing = paymentList[index];

    if (!existing.hasInstructions) {
      throw ApiException(
        code: 'VALIDATION_FAILED',
        message: 'Payment details are not ready yet — please check back shortly',
        statusCode: 400,
      );
    }

    final updated = CustomerPayment(
      id: existing.id,
      reference: existing.reference,
      amount: existing.amount,
      currency: existing.currency,
      // Still pending: only the backoffice can settle it.
      status: 'pending',
      customerState: 'awaiting_verification',
      purpose: existing.purpose,
      bookingId: existing.bookingId,
      payToName: existing.payToName,
      payToAccountNumber: existing.payToAccountNumber,
      payReference: existing.payReference,
      payInstructions: existing.payInstructions,
      declaredAt: DateTime.now(),
      declaredReference: reference,
    );
    paymentList[index] = updated;
    return updated;
  }

  /// Stands in for an operator publishing the account details in the portal.
  void publishInstructions(String paymentId) {
    final index = paymentList.indexWhere((candidate) => candidate.id == paymentId);
    final existing = paymentList[index];
    paymentList[index] = CustomerPayment(
      id: existing.id,
      reference: existing.reference,
      amount: existing.amount,
      currency: existing.currency,
      status: existing.status,
      customerState: 'awaiting_payment',
      purpose: existing.purpose,
      bookingId: existing.bookingId,
      payToName: 'HomeMate Africa Ltd',
      payToAccountName: 'HomeMate Africa',
      payToAccountNumber: '5566778',
      payReference: 'HM-BK-000001',
      payInstructions: 'Send to Lipa Namba 5566778 and quote the reference.',
      paymentMethodName: 'M-Pesa',
    );
  }

  @override
  Future<Paged<AppNotification>> notifications({
    bool unreadOnly = false,
    int limit = 20,
    int offset = 0,
  }) async {
    final items = notificationList.where((n) => !unreadOnly || n.isUnread).toList();
    return Paged(items: items, total: items.length);
  }

  @override
  Future<void> markNotificationRead(String id) async {
    final index = notificationList.indexWhere((candidate) => candidate.id == id);
    final existing = notificationList[index];
    notificationList[index] = AppNotification(
      id: existing.id,
      title: existing.title,
      kind: existing.kind,
      createdAt: existing.createdAt,
      body: existing.body,
      readAt: DateTime.now(),
    );
  }

  @override
  Future<void> markAllNotificationsRead() async {
    for (var i = 0; i < notificationList.length; i++) {
      await markNotificationRead(notificationList[i].id);
    }
  }

  @override
  Future<ActivitySummary> summary() async => summaryValue;
}

/// Puts a screen on the tree with the fakes wired in.
///
/// Every test uses this, so no test invents its own provider graph — and a new
/// dependency is added in one place rather than twenty.
class TestHarness {
  TestHarness({
    FakeAuthRepository? auth,
    FakeCatalogueRepository? catalogue,
    FakeActivityRepository? activity,
    FakeJourneyRepository? journey,
    FakeLocationService? location,
    this.locale = AppLocale.english,
  })  : auth = auth ?? FakeAuthRepository(),
        catalogue = catalogue ?? FakeCatalogueRepository(),
        activity = activity ?? FakeActivityRepository(),
        journey = journey ?? FakeJourneyRepository(),
        location = location ?? FakeLocationService();

  final FakeAuthRepository auth;
  final FakeCatalogueRepository catalogue;
  final FakeActivityRepository activity;
  final FakeJourneyRepository journey;

  /// Defaults to `unknown` — nobody has been asked — which is the state the
  /// soft-ask card exists for, and the one a fresh install is really in.
  final FakeLocationService location;
  final SessionStore store = InMemorySessionStore();

  /// The language the tree under test starts in.
  ///
  /// English, although the app itself opens in Kiswahili: these tests assert on
  /// the English copy, and a test about the Kiswahili build says so by setting
  /// this rather than by being the default everything else inherits.
  AppLocale locale;

  List<Override> get overrides => [
        authRepositoryProvider.overrideWithValue(auth),
        catalogueRepositoryProvider.overrideWithValue(catalogue),
        activityRepositoryProvider.overrideWithValue(activity),
        journeyRepositoryProvider.overrideWithValue(journey),
        locationServiceProvider.overrideWithValue(location),
        sessionStoreProvider.overrideWithValue(store),
        localeStoreProvider.overrideWithValue(InMemoryLocaleStore(locale)),
      ];

  /// The viewport the designs were drawn for. The test default is 800x600,
  /// which is a shape no phone has — layout problems found there are often not
  /// real, and real ones hide.
  static const Size phone = Size(390, 844);

  /// One screen, with a router just rich enough for pushes to work.
  ///
  /// The session is restored first, exactly as `HomeMateApp` does at launch —
  /// otherwise a screen under test sees a half-built world it never meets in
  /// the real app.
  /// The container the last [wrap] built, so a test can seed or read shared
  /// state — the search filters, say — that a screen only reflects rather than
  /// owns.
  ProviderContainer? container;

  Widget wrap(Widget child, {List<GoRoute> extraRoutes = const [], AppLocale? locale}) {
    if (locale != null) this.locale = locale;
    final container = ProviderContainer(overrides: overrides);
    this.container = container;
    container.read(authControllerProvider.notifier).restore();

    return UncontrolledProviderScope(
      container: container,
      child: testApp(
        GoRouter(
          routes: [
            GoRoute(path: '/', builder: (_, __) => child),
            ...extraRoutes,
          ],
        ),
      ),
    );
  }
}

/// A session to hand to `AuthController.adopt`, for a test that needs to start
/// with somebody already signed in.
class AuthSessionStub extends AuthSession {
  AuthSessionStub({required super.token, required super.customer});
}

/// The app under test, localised exactly as `HomeMateApp` localises it.
///
/// English by default: these tests assert on the English copy, and a test about
/// the Kiswahili build should say so rather than inherit it.
/// Watches [localeProvider] exactly as the real app does, so a test that
/// changes the language sees the tree change with it.
Widget testApp(RouterConfig<Object> router) => Consumer(
      builder: (_, ref, __) => MaterialApp.router(
        theme: buildHomeMateTheme(),
        locale: ref.watch(localeProvider).locale,
        supportedLocales: AppLocale.supportedLocales,
        localizationsDelegates: const [
          AppTextDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
      ),
    );

/// A stand-in for the payment screen, so a checkout that navigates on success
/// lands somewhere rather than throwing.
GoRoute payScreenRoute() => GoRoute(
      path: '/payment/:id',
      builder: (_, __) => const Scaffold(body: Text('Payment instructions')),
    );

/// Finds a string whether it is rendered as [Text] or [SelectableText].
///
/// Account numbers and references are selectable on purpose — a customer needs
/// to copy them — and `find.text` does not see a [SelectableText]. A test
/// should not have to know which one a screen chose.
Finder findValue(String value) => find.byWidgetPredicate(
      (widget) =>
          (widget is Text && widget.data == value) ||
          (widget is SelectableText && widget.data == value),
      description: 'text "$value"',
    );

/// Scrolls until `finder` is on screen.
///
/// A `ListView` builds its children lazily, so something below the fold has no
/// element at all and `ensureVisible` cannot find it — the page has to be
/// scrolled until it is instantiated. When it is already built, a plain
/// `ensureVisible` is enough.
Future<void> reveal(WidgetTester tester, Finder finder) async {
  // Settle first: typing into a field rebuilds the form, and measuring before
  // that lands scrolls to a position the widget is no longer at.
  await tester.pumpAndSettle();
  if (finder.evaluate().isNotEmpty) {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    return;
  }
  await tester.scrollUntilVisible(
    finder,
    200,
    // The page's own scrollable, not a text field's or a chip row's.
    scrollable: find
        .descendant(of: find.byType(Scaffold), matching: find.byType(Scrollable))
        .first,
  );
  await tester.pumpAndSettle();
}

Future<void> tapAfterScroll(WidgetTester tester, Finder finder) async {
  await reveal(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// The journey: holds, checkout, tenancies
// ---------------------------------------------------------------------------

PropertyHold fakeHold({
  String id = 'hold-1',
  String propertyId = 'prop-1',
  int secondsRemaining = 600,
  bool isLive = true,
  String? bookingId,
  String? paymentId,
}) =>
    PropertyHold(
      id: id,
      reference: 'HM-HLD-000001',
      propertyId: propertyId,
      secondsRemaining: secondsRemaining,
      isLive: isLive,
      bookingId: bookingId,
      paymentId: paymentId,
    );

/// A fake that refuses the same things the server refuses.
///
/// That is the whole point of it: a hold already taken by somebody else comes
/// back as a 409, a nudge inside its cooldown fails, and `payNow` returns a
/// payment that is still `pending`. A screen that ignores any of those fails
/// here rather than in a customer's hands.
class FakeJourneyRepository implements JourneyRepository {
  FakeJourneyRepository({
    SavedOverview? overview,
    CheckoutEligibility? eligibility,
    this.paymentMethodOptions = const [
      PaymentMethodOption(id: 'pm-1', code: 'mpesa', name: 'M-Pesa', kind: 'mobile_money'),
      PaymentMethodOption(id: 'pm-2', code: 'bank', name: 'Bank Transfer', kind: 'bank_transfer'),
    ],
  })  : overview = overview ?? const SavedOverview(),
        eligibility = eligibility ??
            const CheckoutEligibility(propertyId: 'prop-1', available: true, canPay: true);

  SavedOverview overview;
  CheckoutEligibility eligibility;
  List<PaymentMethodOption> paymentMethodOptions;
  List<JourneyEvent> events = const [];
  List<Rental> rentalList = const [];
  RentalDetail? rentalDetail;
  LeaseAgreement? leaseAgreement;

  /// Thrown by the next call that can fail, then cleared — so a test can make
  /// exactly one request fail without holding the fake in a broken state.
  ApiException? nextFailure;

  /// What the screens actually did, for a test to assert against.
  final List<String> heldPropertyIds = [];
  final List<String> releasedHoldIds = [];
  final List<String> nudgedInquiryIds = [];
  final List<({String paymentId, String methodId, String? phone})> payments = [];
  PropertyHold currentHold = fakeHold();

  ApiException? _takeFailure() {
    final failure = nextFailure;
    nextFailure = null;
    return failure;
  }

  @override
  Future<SavedOverview> savedOverview({int sectionLimit = 6}) async {
    if (_takeFailure() case final failure?) throw failure;
    return overview;
  }

  @override
  Future<CheckoutEligibility> checkoutEligibility(String propertyId) async {
    if (_takeFailure() case final failure?) throw failure;
    return eligibility;
  }

  @override
  Future<PropertyHold> hold(String propertyId) async {
    if (_takeFailure() case final failure?) throw failure;
    heldPropertyIds.add(propertyId);
    return currentHold;
  }

  @override
  Future<List<PropertyHold>> myHolds() async => [if (currentHold.isLive) currentHold];

  @override
  Future<void> releaseHold(String holdId, {String? reason}) async {
    releasedHoldIds.add(holdId);
  }

  @override
  Future<CheckoutSession> startCheckout(
    String propertyId, {
    int? leaseMonths,
    DateTime? moveInDate,
    String? notes,
  }) async {
    if (_takeFailure() case final failure?) throw failure;
    heldPropertyIds.add(propertyId);
    return CheckoutSession(
      hold: currentHold,
      bookingId: 'booking-1',
      paymentId: 'pay-1',
      summary: fakeCheckoutSummary(),
    );
  }

  @override
  Future<CheckoutSummary> checkoutSummary(String bookingId) async => fakeCheckoutSummary();

  @override
  Future<List<PaymentMethodOption>> paymentMethods(String propertyId) async {
    if (_takeFailure() case final failure?) throw failure;
    return paymentMethodOptions;
  }

  @override
  Future<PaymentAttempt> payNow(
    String paymentId, {
    required String paymentMethodId,
    String? payerPhone,
  }) async {
    if (_takeFailure() case final failure?) throw failure;
    payments.add((paymentId: paymentId, methodId: paymentMethodId, phone: payerPhone));
    return PaymentAttempt(
      // Still pending, and deliberately so: BR-005 means nothing here can
      // settle a payment, and a screen that celebrates on this response is
      // lying to the customer.
      payment: fakePayment(id: paymentId, customerState: 'awaiting_payment'),
      hold: currentHold,
    );
  }

  @override
  Future<List<JourneyEvent>> propertyJourney(String propertyId) async => events;

  @override
  Future<List<JourneyEvent>> inquiryJourney(String inquiryId) async => events;

  @override
  Future<Inquiry> nudgeInquiry(String inquiryId) async {
    if (_takeFailure() case final failure?) throw failure;
    nudgedInquiryIds.add(inquiryId);
    return fakeInquiry(id: inquiryId);
  }

  @override
  Future<Paged<Rental>> rentals({int limit = 20, int offset = 0}) async =>
      Paged(items: rentalList, total: rentalList.length);

  @override
  Future<RentalDetail> rental(String bookingId) async =>
      rentalDetail ?? RentalDetail(rental: fakeRental(id: bookingId));

  @override
  Future<LeaseAgreement> lease(String bookingId) async =>
      leaseAgreement ?? const LeaseAgreement(bookingReference: 'HM-BK-000001');
}

Viewing fakeViewing({
  String id = 'view-1',
  String status = 'confirmed',
  DateTime? scheduledFor,
}) =>
    Viewing(
      id: id,
      reference: 'HM-VW-000001',
      status: status,
      scheduledFor: scheduledFor ?? DateTime(2026, 1, 18, 10),
      propertyId: 'prop-1',
      propertyTitle: 'Masaki 2BR Apartment',
      propertyAddress: 'Masaki, Dar es Salaam',
      hostName: 'Baraka Landlord',
      hostPhone: '+255 712 345 678',
    );

Inquiry fakeInquiry({
  String id = 'inq-1',
  String status = 'pending',
  String message = 'Is this still available?',
  String? response,
  String? rejectionReason,
}) =>
    Inquiry(
      id: id,
      reference: 'HM-INQ-000001',
      status: status,
      message: message,
      createdAt: DateTime(2026, 1, 8, 10, 30),
      response: response,
      rejectionReason: rejectionReason,
      respondedAt: response == null && rejectionReason == null ? null : DateTime(2026, 1, 9),
      propertyId: 'prop-1',
      propertyTitle: 'Masaki 2BR Apartment',
      propertyReference: 'HM-P-000001',
    );

CustomerPayment fakePayment({
  String id = 'pay-1',
  double amount = 2400000,
  String status = 'pending',
  String customerState = 'awaiting_payment',
}) =>
    CustomerPayment(
      id: id,
      reference: 'HM-PAY-000001',
      amount: amount,
      currency: 'TZS',
      status: status,
      customerState: customerState,
      purpose: 'deposit',
      bookingId: 'booking-1',
      propertyTitle: 'Masaki 2BR Apartment',
      payToName: 'HomeMate Collections',
      payToAccountNumber: '0123456789',
      payReference: 'HM-PAY-000001',
      paymentMethodName: 'M-Pesa',
      createdAt: DateTime(2026, 1, 10),
    );

Booking fakeBooking({
  String id = 'booking-1',
  String status = 'awaiting_payment',
  double totalDue = 2400000,
}) =>
    Booking(
      id: id,
      reference: 'HM-BK-000001',
      status: status,
      monthlyRent: 800000,
      totalDue: totalDue,
      amountPaid: 0,
      amountOutstanding: totalDue,
      depositAmount: 1600000,
      leaseMonths: 12,
      moveInDate: DateTime(2026, 2, 1),
      propertyId: 'prop-1',
      propertyTitle: 'Masaki 2BR Apartment',
      propertyAddress: 'Masaki, Dar es Salaam',
      landlordName: 'Baraka Landlord',
      createdAt: DateTime(2026, 1, 10),
    );

CheckoutSummary fakeCheckoutSummary({double totalDue = 2400000}) => CheckoutSummary(
      booking: fakeBooking(),
      breakdown: const [
        CostLine(key: 'first_period', label: 'First month rent', amount: 800000),
        CostLine(key: 'deposit', label: 'Security deposit (2x)', amount: 1600000),
        CostLine(key: 'agency_fee', label: 'Agency fee', amount: 0, waived: true),
      ],
      totalDue: totalDue,
      amountPaid: 0,
      amountOutstanding: totalDue,
      payments: [fakePayment()],
    );

Rental fakeRental({
  String id = 'booking-1',
  String title = 'Masaki 2BR Apartment',
  double monthlyRent = 800000,
  int? daysRemaining = 300,
  int? monthsRemaining = 9,
  DateTime? nextPaymentDate,
}) =>
    Rental(
      id: id,
      reference: 'HM-BK-000001',
      status: 'active',
      monthlyRent: monthlyRent,
      propertyId: 'prop-1',
      propertyTitle: title,
      propertyAddress: 'Masaki, Dar es Salaam',
      depositAmount: 1600000,
      leaseMonths: 12,
      leaseStartDate: DateTime(2026, 1, 1),
      leaseEndDate: DateTime(2026, 12, 31),
      nextPaymentDate: nextPaymentDate ?? DateTime(2026, 11, 1),
      daysRemaining: daysRemaining,
      monthsRemaining: monthsRemaining,
      noticePeriodDays: 90,
      landlordName: 'Baraka Landlord',
      landlordPhone: '+255 712 345 678',
    );

InquirySummary fakeInquirySummary({
  String id = 'inq-1',
  String status = 'pending',
  String? displayStatus,
  String title = 'Masaki 2BR Apartment',
}) =>
    InquirySummary(
      id: id,
      reference: 'HM-INQ-000001',
      status: status,
      displayStatus: displayStatus ?? status,
      createdAt: DateTime(2026, 1, 8),
      propertyId: 'prop-1',
      propertyTitle: title,
    );

ViewingSummary fakeViewingSummary({
  String id = 'view-1',
  String status = 'confirmed',
  String title = 'Masaki 2BR Apartment',
}) =>
    ViewingSummary(
      id: id,
      reference: 'HM-VW-000001',
      status: status,
      scheduledFor: DateTime(2026, 1, 18, 10),
      propertyId: 'prop-1',
      propertyTitle: title,
    );

/// A location service a test can put into any of its five states without a
/// device — which is the only way the permission screens get tested at all.
class FakeLocationService implements LocationService {
  FakeLocationService({
    this.state = LocationAvailability.unknown,
    this.grantOnRequest = true,
    this.latitude = -6.7576,
    this.longitude = 39.2768,
  });

  LocationAvailability state;

  /// What the OS prompt "answers" when [request] is called.
  bool grantOnRequest;
  double latitude;
  double longitude;

  int requestCount = 0;
  int settingsOpenedCount = 0;

  @override
  Future<LocationAvailability> availability() async => state;

  @override
  Future<LocationResult> request() async {
    requestCount++;
    if (state == LocationAvailability.serviceDisabled ||
        state == LocationAvailability.deniedForever) {
      return LocationResult.unavailable(state);
    }
    if (!grantOnRequest) {
      state = LocationAvailability.denied;
      return const LocationResult.unavailable(LocationAvailability.denied);
    }
    state = LocationAvailability.granted;
    return current();
  }

  @override
  Future<LocationResult> current() async => LocationResult(
        availability: LocationAvailability.granted,
        latitude: latitude,
        longitude: longitude,
      );

  @override
  Future<bool> openSettings({bool appSettings = true}) async {
    settingsOpenedCount++;
    return true;
  }
}
