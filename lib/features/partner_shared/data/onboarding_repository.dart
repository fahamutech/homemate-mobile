import '../../../core/network/api_client.dart';
import 'partner_application.dart';

/// Partner setup (T03): details, payout, agreement, submit. Identity
/// documents go through the customer's IdentityRepository — they belong to
/// the person, not the role.
abstract class OnboardingRepository {
  Future<ApplicationsOverview> overview();
  Future<PartnerApplication> saveDetails(String role, PartnerDetails details);
  Future<PayoutAccount> savePayout(PayoutAccount payout);
  Future<PartnerApplication> acceptAgreement(String role, String version);

  /// 422 with `details.missingSteps` while something is still missing.
  Future<PartnerApplication> submit(String role);
}

class HttpOnboardingRepository implements OnboardingRepository {
  HttpOnboardingRepository(this._api);

  final ApiClient _api;

  @override
  Future<ApplicationsOverview> overview() async =>
      ApplicationsOverview.fromJson(await _api.get('/app/partner/applications'));

  @override
  Future<PartnerApplication> saveDetails(String role, PartnerDetails details) async =>
      PartnerApplication.fromJson(await _api.put('/app/partner/applications/$role', body: details.toJson()));

  @override
  Future<PayoutAccount> savePayout(PayoutAccount payout) async {
    final json = await _api.put('/app/me/payout', body: payout.toJson());
    return PayoutAccount.fromJson(json['payout']) ?? payout;
  }

  @override
  Future<PartnerApplication> acceptAgreement(String role, String version) async => PartnerApplication.fromJson(
        await _api.post('/app/partner/applications/$role/agreement', body: {'version': version}),
      );

  @override
  Future<PartnerApplication> submit(String role) async =>
      PartnerApplication.fromJson(await _api.post('/app/partner/applications/$role/submit'));
}
