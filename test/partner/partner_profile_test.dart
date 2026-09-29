import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:homemate_mobile/features/partner_shared/data/partner_application.dart';
import 'package:homemate_mobile/features/partner_shared/presentation/partner_profile_screen.dart';
import 'package:homemate_mobile/features/roles/data/app_role.dart';

import '../support/fakes.dart';

/// BRK-060: the broker's profile — details, identity, where payouts go, the
/// agreement, help — each row leading to where it is changed.
void main() {
  Future<TestHarness> open(WidgetTester tester, void Function(TestHarness) arrange) async {
    tester.view.physicalSize = TestHarness.phone * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final harness = TestHarness(roles: FakeRoleRepository.withPartner(AppRole.broker));
    arrange(harness);
    await tester.pumpWidget(harness.wrap(const PartnerProfileScreen(role: AppRole.broker), extraRoutes: [
      GoRoute(path: '/broker/setup', builder: (_, s) => Scaffold(body: Text('SETUP ${s.uri.queryParameters['step']}'))),
      GoRoute(path: '/broker/payouts', builder: (_, __) => const Scaffold(body: Text('PAYOUTS'))),
    ]));
    await tester.pumpAndSettle();
    return harness;
  }

  Future<void> tapRow(WidgetTester tester, String label) async {
    final finder = find.text(label);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('the payout account is shown masked and opens the payouts', (tester) async {
    await open(tester, (h) {
      h.onboarding.profile = const PartnerProfile(
        fullName: 'Baraka Mwinyi',
        kycStatus: 'verified',
        payout: PayoutAccount(method: 'mobile_money', provider: 'mpesa', accountName: 'BARAKA MWINYI', accountNumber: '+255712345678'),
      );
      h.onboarding.agreements['broker'] = 'v1.0';
    });
    expect(find.text('M-Pesa •••• 678'), findsOneWidget);
    expect(find.text('Accepted'), findsOneWidget);
    await tapRow(tester, 'Payout account');
    expect(find.text('PAYOUTS'), findsOneWidget);
  });

  testWidgets('with no payout account yet, the row leads to setting one up', (tester) async {
    await open(tester, (_) {});
    await tapRow(tester, 'Payout account');
    expect(find.text('SETUP payout'), findsOneWidget);
  });

  testWidgets('details and identity open their setup steps', (tester) async {
    await open(tester, (_) {});
    await tapRow(tester, 'Edit your details');
    expect(find.text('SETUP details'), findsOneWidget);
  });

  testWidgets('identity opens its step', (tester) async {
    await open(tester, (_) {});
    await tapRow(tester, 'Identity verification');
    expect(find.text('SETUP identity'), findsOneWidget);
  });

  testWidgets('help says how to reach a person', (tester) async {
    await open(tester, (_) {});
    await tester.ensureVisible(find.text('Help & support'));
    expect(find.text('Call 0800 000 000 or email help@homemate.co.tz'), findsOneWidget);
  });
}
