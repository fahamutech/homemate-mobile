import '../../core/network/api_client.dart';
import 'models.dart';

/// Everything a customer has in flight: what they asked, what they owe, and
/// what they were told.
///
/// These belong together because the screens do — the activity timeline
/// (CUS-013b) and the transaction dashboard (CUS-016) each draw on more than
/// one of them, and splitting them into four repositories would mean four
/// near-identical files and a screen wiring them back together anyway.
abstract class ActivityRepository {
  Future<Paged<Inquiry>> inquiries({String? status, int limit, int offset});
  Future<Inquiry> inquiry(String id);
  Future<Inquiry> createInquiry({
    required String propertyId,
    required String message,
    DateTime? moveInDate,
    double? budgetAmount,
    int? occupants,
    String? contactPreference,
    String? preferredContactTime,
  });
  Future<Inquiry> withdrawInquiry(String id);

  Future<Paged<CustomerPayment>> payments({String? state, int limit, int offset});
  Future<CustomerPayment> payment(String id);
  Future<CustomerPayment> declarePaid(String id, {String? reference, String? note});

  Future<Paged<AppNotification>> notifications({bool unreadOnly, int limit, int offset});
  Future<void> markNotificationRead(String id);
  Future<void> markAllNotificationsRead();

  Future<ActivitySummary> summary();
}

class HttpActivityRepository implements ActivityRepository {
  HttpActivityRepository(this._api);

  final ApiClient _api;

  /// Dates go to the API as calendar days, not instants — a lease starts on a
  /// date, and sending a timestamp lets a timezone move it.
  static String? _day(DateTime? value) => value?.toIso8601String().substring(0, 10);

  // --- inquiries -------------------------------------------------------------

  @override
  Future<Paged<Inquiry>> inquiries({String? status, int limit = 20, int offset = 0}) async =>
      Paged.fromJson(
        await _api.get('/app/inquiries', query: {'status': status, 'limit': limit, 'offset': offset}),
        Inquiry.fromJson,
      );

  @override
  Future<Inquiry> inquiry(String id) async => Inquiry.fromJson(await _api.get('/app/inquiries/$id'));

  @override
  Future<Inquiry> createInquiry({
    required String propertyId,
    required String message,
    DateTime? moveInDate,
    double? budgetAmount,
    int? occupants,
    String? contactPreference,
    String? preferredContactTime,
  }) async =>
      Inquiry.fromJson(await _api.post('/app/inquiries', body: {
        'propertyId': propertyId,
        'message': message,
        'moveInDate': _day(moveInDate),
        'budgetAmount': budgetAmount,
        'occupants': occupants,
        'contactPreference': contactPreference,
        'preferredContactTime': preferredContactTime,
      }));

  @override
  Future<Inquiry> withdrawInquiry(String id) async =>
      Inquiry.fromJson(await _api.post('/app/inquiries/$id/withdraw'));

  // --- payments --------------------------------------------------------------

  @override
  Future<Paged<CustomerPayment>> payments({String? state, int limit = 20, int offset = 0}) async =>
      Paged.fromJson(
        await _api.get('/app/payments', query: {'state': state, 'limit': limit, 'offset': offset}),
        CustomerPayment.fromJson,
      );

  @override
  Future<CustomerPayment> payment(String id) async =>
      CustomerPayment.fromJson(await _api.get('/app/payments/$id'));

  @override
  Future<CustomerPayment> declarePaid(String id, {String? reference, String? note}) async =>
      CustomerPayment.fromJson(
        await _api.post('/app/payments/$id/declare', body: {'reference': reference, 'note': note}),
      );

  // --- notifications and summary ----------------------------------------------

  @override
  Future<Paged<AppNotification>> notifications({
    bool unreadOnly = false,
    int limit = 20,
    int offset = 0,
  }) async =>
      Paged.fromJson(
        await _api.get('/app/notifications', query: {
          'unreadOnly': unreadOnly ? 'true' : null,
          'limit': limit,
          'offset': offset,
        }),
        AppNotification.fromJson,
      );

  @override
  Future<void> markNotificationRead(String id) async {
    await _api.post('/app/notifications/$id/read');
  }

  @override
  Future<void> markAllNotificationsRead() async {
    await _api.post('/app/notifications/read-all');
  }

  @override
  Future<ActivitySummary> summary() async =>
      ActivitySummary.fromJson(await _api.get('/app/summary'));
}
