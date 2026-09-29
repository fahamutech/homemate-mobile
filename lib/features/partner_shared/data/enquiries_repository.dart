import '../../../core/network/api_client.dart';
import 'partner_enquiry.dart';

/// Enquiries on the partner's listings (T05).
abstract class EnquiriesRepository {
  /// [tab]: `new`, `replied`, `accepted`, `closed`.
  Future<List<PartnerEnquiry>> list({String? tab});
  Future<PartnerEnquiry> get(String id);
  Future<PartnerEnquiry> respond(String id, {required EnquiryOutcome outcome, String? response, String? rejectionReason});
  Future<EnquiryJourney> journey(String id);
}

class HttpEnquiriesRepository implements EnquiriesRepository {
  HttpEnquiriesRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<PartnerEnquiry>> list({String? tab}) async {
    final json = await _api.get('/app/partner/inquiries', query: {'status': tab});
    return [for (final row in (json['items'] as List? ?? const [])) PartnerEnquiry.fromJson(row as Map<String, dynamic>)];
  }

  @override
  Future<PartnerEnquiry> get(String id) async => PartnerEnquiry.fromJson(await _api.get('/app/partner/inquiries/$id'));

  @override
  Future<PartnerEnquiry> respond(String id, {required EnquiryOutcome outcome, String? response, String? rejectionReason}) async =>
      PartnerEnquiry.fromJson(await _api.post('/app/partner/inquiries/$id/respond', body: {
        'status': outcome.status,
        'response': response,
        'rejectionReason': rejectionReason,
      }));

  @override
  Future<EnquiryJourney> journey(String id) async =>
      EnquiryJourney.fromJson(await _api.get('/app/partner/inquiries/$id/journey'));
}
