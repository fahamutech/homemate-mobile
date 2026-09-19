import '../../core/network/api_client.dart';
import 'journey_models.dart';
import 'models.dart';

/// Reserving a home, paying for it, and living in it afterwards.
///
/// This is deliberately separate from [ActivityRepository]: that one is about
/// things a customer has *asked for*, and this one is about the point where an
/// asking becomes a commitment — a ten-minute hold, a charge with a provider, a
/// lease with an end date. The screens behind those two ideas barely overlap,
/// and neither should have to load the other's endpoints to render.
abstract class JourneyRepository {
  // --- the Favourites screen ------------------------------------------------

  Future<SavedOverview> savedOverview({int sectionLimit});

  // --- reserving ------------------------------------------------------------

  Future<CheckoutEligibility> checkoutEligibility(String propertyId);
  Future<PropertyHold> hold(String propertyId);
  Future<List<PropertyHold>> myHolds();
  Future<void> releaseHold(String holdId, {String? reason});

  // --- paying ---------------------------------------------------------------

  Future<CheckoutSession> startCheckout(
    String propertyId, {
    int? leaseMonths,
    DateTime? moveInDate,
    String? notes,
  });
  Future<CheckoutSummary> checkoutSummary(String bookingId);
  Future<List<PaymentMethodOption>> paymentMethods(String propertyId);
  Future<PaymentAttempt> payNow(String paymentId, {required String paymentMethodId, String? payerPhone});

  // --- the timeline and the nudge -------------------------------------------

  Future<List<JourneyEvent>> propertyJourney(String propertyId);
  Future<List<JourneyEvent>> inquiryJourney(String inquiryId);
  Future<Inquiry> nudgeInquiry(String inquiryId);

  // --- tenancies ------------------------------------------------------------

  Future<Paged<Rental>> rentals({int limit, int offset});
  Future<RentalDetail> rental(String bookingId);
  Future<LeaseAgreement> lease(String bookingId);
}

class HttpJourneyRepository implements JourneyRepository {
  HttpJourneyRepository(this._api);

  final ApiClient _api;

  /// Dates go as calendar days, not instants — a lease starts on a date, and
  /// sending a timestamp lets a timezone move it.
  static String? _day(DateTime? value) => value?.toIso8601String().substring(0, 10);

  static List<T> _items<T>(Map<String, dynamic> json, T Function(Map<String, dynamic>) parse) =>
      (json['items'] as List? ?? const []).map((row) => parse(row as Map<String, dynamic>)).toList();

  @override
  Future<SavedOverview> savedOverview({int sectionLimit = 6}) async =>
      SavedOverview.fromJson(await _api.get('/app/saved/overview', query: {'sectionLimit': sectionLimit}));

  @override
  Future<CheckoutEligibility> checkoutEligibility(String propertyId) async =>
      CheckoutEligibility.fromJson(await _api.get('/app/properties/$propertyId/checkout'));

  @override
  Future<PropertyHold> hold(String propertyId) async =>
      PropertyHold.fromJson(await _api.post('/app/properties/$propertyId/hold'));

  @override
  Future<List<PropertyHold>> myHolds() async =>
      _items(await _api.get('/app/holds'), PropertyHold.fromJson);

  @override
  Future<void> releaseHold(String holdId, {String? reason}) async {
    await _api.delete('/app/holds/$holdId');
  }

  @override
  Future<CheckoutSession> startCheckout(
    String propertyId, {
    int? leaseMonths,
    DateTime? moveInDate,
    String? notes,
  }) async =>
      CheckoutSession.fromJson(await _api.post('/app/properties/$propertyId/checkout', body: {
        'leaseMonths': leaseMonths,
        'moveInDate': _day(moveInDate),
        'notes': notes,
      }));

  @override
  Future<CheckoutSummary> checkoutSummary(String bookingId) async =>
      CheckoutSummary.fromJson(await _api.get('/app/bookings/$bookingId/summary'));

  @override
  Future<List<PaymentMethodOption>> paymentMethods(String propertyId) async =>
      _items(await _api.get('/app/properties/$propertyId/payment-methods'), PaymentMethodOption.fromJson);

  @override
  Future<PaymentAttempt> payNow(
    String paymentId, {
    required String paymentMethodId,
    String? payerPhone,
  }) async =>
      PaymentAttempt.fromJson(await _api.post('/app/payments/$paymentId/pay', body: {
        'paymentMethodId': paymentMethodId,
        'payerPhone': payerPhone,
      }));

  @override
  Future<List<JourneyEvent>> propertyJourney(String propertyId) async =>
      _items(await _api.get('/app/properties/$propertyId/journey'), JourneyEvent.fromJson);

  @override
  Future<List<JourneyEvent>> inquiryJourney(String inquiryId) async =>
      _items(await _api.get('/app/inquiries/$inquiryId/journey'), JourneyEvent.fromJson);

  @override
  Future<Inquiry> nudgeInquiry(String inquiryId) async =>
      Inquiry.fromJson(await _api.post('/app/inquiries/$inquiryId/nudge'));

  @override
  Future<Paged<Rental>> rentals({int limit = 20, int offset = 0}) async => Paged.fromJson(
        await _api.get('/app/rentals', query: {'limit': limit, 'offset': offset}),
        Rental.fromJson,
      );

  @override
  Future<RentalDetail> rental(String bookingId) async =>
      RentalDetail.fromJson(await _api.get('/app/rentals/$bookingId'));

  @override
  Future<LeaseAgreement> lease(String bookingId) async =>
      LeaseAgreement.fromJson(await _api.get('/app/rentals/$bookingId/lease'));
}
