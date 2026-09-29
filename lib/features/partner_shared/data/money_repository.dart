import '../../../core/network/api_client.dart';
import 'partner_money.dart';

/// Earnings, payouts and the home summaries (T06).
abstract class MoneyRepository {
  Future<EarningsOverview> earnings(String role);
  Future<EarningDetail> earning(String id);
  Future<PayoutsOverview> payouts(String role);

  /// `GET /app/broker/summary` or `/app/landlord/summary`; the role must be
  /// active and in use.
  Future<PartnerSummary> summary(String role);
}

class HttpMoneyRepository implements MoneyRepository {
  HttpMoneyRepository(this._api);

  final ApiClient _api;

  @override
  Future<EarningsOverview> earnings(String role) async =>
      EarningsOverview.fromJson(await _api.get('/app/partner/earnings', query: {'role': role}));

  @override
  Future<EarningDetail> earning(String id) async => EarningDetail.fromJson(await _api.get('/app/partner/earnings/$id'));

  @override
  Future<PayoutsOverview> payouts(String role) async =>
      PayoutsOverview.fromJson(await _api.get('/app/partner/payouts', query: {'role': role}));

  @override
  Future<PartnerSummary> summary(String role) async => PartnerSummary.fromJson(await _api.get('/app/$role/summary'));
}
