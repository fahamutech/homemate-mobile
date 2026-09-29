import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:homemate_mobile/features/partner_shared/data/partner_money.dart';
import 'package:homemate_mobile/features/partner_shared/presentation/money/earning_detail_screen.dart';
import 'package:homemate_mobile/features/partner_shared/presentation/money/earnings_screen.dart';
import 'package:homemate_mobile/features/roles/data/app_role.dart';

import '../support/fakes.dart';

/// LND-040 money, LND-041 one payment with its full split.
void main() {
  Future<TestHarness> open(WidgetTester tester, Widget screen, void Function(TestHarness) arrange) async {
    tester.view.physicalSize = TestHarness.phone * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final harness = TestHarness(roles: FakeRoleRepository.withPartner(AppRole.landlord));
    arrange(harness);
    await tester.pumpWidget(harness.wrap(screen, extraRoutes: [
      GoRoute(path: '/landlord/money/:id', builder: (_, s) => Scaffold(body: Text('PAYMENT ${s.pathParameters['id']}'))),
      GoRoute(path: '/landlord/payouts', builder: (_, __) => const Scaffold(body: Text('PAYOUTS'))),
    ]));
    await tester.pumpAndSettle();
    return harness;
  }

  testWidgets('money: rent on its way in every state, and the rule about rent', (tester) async {
    await open(tester, const EarningsScreen(role: AppRole.landlord), (h) {
      h.money.overview = const EarningsOverview(
        totals: {'ready': 2400000, 'being_checked': 1600000},
        paidThisYear: 9600000,
        items: [
          Earning(id: 'e1', amount: 2400000, state: 'ready', propertyTitle: 'Masaki Heights', purpose: 'rent_and_deposit'),
          Earning(id: 'e2', amount: 1600000, state: 'being_checked', propertyTitle: 'Mikocheni House'),
          Earning(id: 'e3', amount: 800000, state: 'paid', propertyTitle: 'Sinza Flat'),
          Earning(id: 'e4', amount: 800000, state: 'on_hold', propertyTitle: 'Upanga Flat'),
        ],
      );
    });
    expect(find.text('Money'), findsOneWidget);
    expect(find.text('TZS 2,400,000'), findsOneWidget);
    expect(find.text('Ready'), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);
    expect(find.text('On hold'), findsOneWidget);
    expect(find.textContaining('Rent and deposit come to you in full'), findsOneWidget);

    await tester.tap(find.text('Masaki Heights'));
    await tester.pumpAndSettle();
    expect(find.text('PAYMENT e1'), findsOneWidget);
  });

  testWidgets('no money yet says what brings it', (tester) async {
    await open(tester, const EarningsScreen(role: AppRole.landlord), (_) {});
    expect(find.text('Rent and deposit appear here once a tenant pays for one of your homes.'), findsOneWidget);
  });

  testWidgets('a payment on a broker-listed home shows the whole split', (tester) async {
    await open(tester, const EarningDetailScreen(role: AppRole.landlord, earningId: 'e1'), (h) {
      h.money.details['e1'] = const EarningDetail(
        earning: Earning(id: 'e1', amount: 3600000, state: 'on_hold', holdReason: 'the payment is being re-checked', propertyTitle: 'Masaki Heights'),
        split: [
          SplitLine(beneficiary: 'landlord', amount: 3600000, purpose: 'rent_and_deposit', you: true),
          SplitLine(beneficiary: 'broker', amount: 540000),
          SplitLine(beneficiary: 'homemate', amount: 60000),
        ],
      );
    });
    expect(find.text('Fee share to the broker'), findsOneWidget);
    expect(find.text('TZS 540,000'), findsOneWidget);
    expect(find.text("HomeMate's share"), findsOneWidget);
    expect(find.text('On hold: the payment is being re-checked'), findsOneWidget);
    expect(find.text('Rent and deposit to the landlord'), findsNothing, reason: 'that line is the landlord’s own');
  });
}
