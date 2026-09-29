import 'package:flutter_test/flutter_test.dart';
import 'package:homemate_mobile/core/i18n/app_locale.dart';
import 'package:homemate_mobile/core/i18n/app_text.dart';
import 'package:homemate_mobile/features/partner_shared/data/partner_application.dart';
import 'package:homemate_mobile/features/partner_shared/presentation/payout_labels.dart';
import 'package:homemate_mobile/features/partner_shared/presentation/setup/setup_step.dart';
import 'package:homemate_mobile/features/roles/data/app_role.dart';
import 'package:homemate_mobile/routing/routes.dart';

void main() {
  const en = AppText(AppLocale.english);

  test('brokers have three setup screens, landlords four', () {
    expect(SetupStep.forRole(AppRole.broker), [SetupStep.details, SetupStep.identity, SetupStep.payout]);
    expect(SetupStep.forRole(AppRole.landlord), [SetupStep.details, SetupStep.identity, SetupStep.ownership, SetupStep.payout]);
    expect(SetupStep.fromName('payout'), SetupStep.payout);
    expect(SetupStep.fromName('nope'), isNull);
  });

  test('the server’s missing steps, in words, once each', () {
    expect(missingStepsSentence(en, ['identity', 'payout', 'agreement']), 'Identity, Getting paid');
    expect(missingStepsSentence(en, ['ownership']), 'Proof of ownership');
  });

  test('payout lines are masked to the last three digits', () {
    expect(payoutAccountLine(const PayoutAccount(method: 'mobile_money', provider: 'mpesa', accountNumber: '+255712345678')), 'M-Pesa •••• 678');
    expect(payoutAccountLine(const PayoutAccount(method: 'bank', provider: 'crdb', accountNumber: '0150123456789'), bankName: (_) => 'CRDB Bank'), 'CRDB Bank •••• 789');
    expect(payoutAccountLine(null), '');
    expect(payoutProviderLabel('mixx_by_yas'), 'Mixx by Yas');
  });

  test('setup paths stay inside the role’s space', () {
    expect(Routes.partnerIntro(AppRole.broker), '/broker/intro');
    expect(Routes.partnerSetup(AppRole.landlord, step: 'payout'), '/landlord/setup?step=payout');
    expect(Routes.partnerApplication(AppRole.broker), '/broker/application');
  });
}
