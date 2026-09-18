import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:homemate_mobile/core/network/api_exception.dart';
import 'package:homemate_mobile/core/providers.dart';
import 'package:homemate_mobile/design/theme.dart';
import 'package:homemate_mobile/features/auth/data/auth_repository.dart';
import 'package:homemate_mobile/features/auth/data/customer.dart';
import 'package:homemate_mobile/features/auth/data/session_store.dart';
import 'package:homemate_mobile/features/shared/activity_repository.dart';
import 'package:homemate_mobile/features/shared/catalogue_repository.dart';
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
  }) async {
    if (_takeFailure() case final failure?) throw failure;
    customer = customer.copyWith(
      fullName: fullName,
      email: email,
      preferredLanguage: preferredLanguage,
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
  })  : auth = auth ?? FakeAuthRepository(),
        catalogue = catalogue ?? FakeCatalogueRepository(),
        activity = activity ?? FakeActivityRepository();

  final FakeAuthRepository auth;
  final FakeCatalogueRepository catalogue;
  final FakeActivityRepository activity;
  final SessionStore store = InMemorySessionStore();

  List<Override> get overrides => [
        authRepositoryProvider.overrideWithValue(auth),
        catalogueRepositoryProvider.overrideWithValue(catalogue),
        activityRepositoryProvider.overrideWithValue(activity),
        sessionStoreProvider.overrideWithValue(store),
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
  Widget wrap(Widget child, {List<GoRoute> extraRoutes = const []}) {
    final container = ProviderContainer(overrides: overrides);
    container.read(authControllerProvider.notifier).restore();

    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: buildHomeMateTheme(),
        routerConfig: GoRouter(
          routes: [
            GoRoute(path: '/', builder: (_, __) => child),
            ...extraRoutes,
          ],
        ),
      ),
    );
  }
}

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
