import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:homemate_mobile/features/partner_shared/data/partner_money.dart';
import 'package:homemate_mobile/features/partner_shared/presentation/money/earning_detail_screen.dart';
import 'package:homemate_mobile/features/partner_shared/presentation/money/earning_state.dart';
import 'package:homemate_mobile/features/partner_shared/presentation/money/earnings_screen.dart';
import 'package:homemate_mobile/features/partner_shared/presentation/money/payouts_screen.dart';
import 'package:homemate_mobile/core/i18n/app_locale.dart';
import 'package:homemate_mobile/core/i18n/app_text.dart';
import 'package:homemate_mobile/design/widgets/hm_badge.dart';
import 'package:homemate_mobile/features/roles/data/app_role.dart';

import '../support/fakes.dart';

/// BRK-050 earnings, BRK-051 one earning, BRK-052 payouts.
void main() {
  Future<TestHarness> open(WidgetTester tester, Widget screen, void Function(TestHarness) arrange) async {
    tester.view.physicalSize = TestHarness.phone * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final harness = TestHarness(roles: FakeRoleRepository.withPartner(AppRole.broker));
    arrange(harness);
    await tester.pumpWidget(harness.wrap(screen, extraRoutes: [
      GoRoute(path: '/broker/earnings/:id', builder: (_, s) => Scaffold(body: Text('EARNING ${s.pathParameters['id']}'))),
      GoRoute(path: '/broker/payouts', builder: (_, __) => const Scaffold(body: Text('PAYOUTS'))),
      GoRoute(path: '/broker/setup', builder: (_, __) => const Scaffold(body: Text('SETUP'))),
    ]));
    await tester.pumpAndSettle();
    return harness;
  }

  test('every earning state has its words and colour', () {
    const en = AppText(AppLocale.english);
    expect(earningStateLabel(en, 'being_checked'), 'Being checked');
    expect(earningStateTone('ready'), HmBadgeTone.success);
    expect(earningStateTone('being_checked'), HmBadgeTone.info);
    expect(earningStateTone('in_payout'), HmBadgeTone.info);
    expect(earningStateTone('paid'), HmBadgeTone.neutral);
    expect(earningStateTone('on_hold'), HmBadgeTone.warning);
    expect(earningStateTone('reversed'), HmBadgeTone.error);
    expect(payoutStatusTone('scheduled'), HmBadgeTone.info);
    expect(payoutStatusTone('on_hold'), HmBadgeTone.warning);
  });

  testWidgets('earnings: ready for payout, being checked, paid this year, each earning with its state', (tester) async {
    await open(tester, const EarningsScreen(role: AppRole.broker), (h) {
      h.money.overview = const EarningsOverview(
        totals: {'ready': 810000, 'being_checked': 270000},
        paidThisYear: 3240000,
        items: [
          Earning(id: 'e1', amount: 810000, state: 'ready', propertyTitle: 'Oyster Bay Reef Residence'),
          Earning(id: 'e2', amount: 270000, state: 'being_checked', propertyTitle: 'Kariakoo Market Flat'),
          Earning(id: 'e3', amount: -315000, state: 'reversed', propertyTitle: 'Upanga Studio'),
        ],
      );
    });
    expect(find.text('Ready for payout'), findsOneWidget);
    expect(find.text('TZS 810,000'), findsOneWidget);
    expect(find.text('TZS 270,000'), findsOneWidget);
    expect(find.text('TZS 3,240,000'), findsOneWidget);
    expect(find.text('Being checked'), findsWidgets);
    expect(find.text('Reversed'), findsOneWidget);
    expect(find.text('+TZS 810,000'), findsOneWidget);
    expect(find.text('−TZS 315,000'), findsOneWidget);

    await tester.tap(find.text('Oyster Bay Reef Residence'));
    await tester.pumpAndSettle();
    expect(find.text('EARNING e1'), findsOneWidget);
  });

  testWidgets('no earnings yet says what brings them', (tester) async {
    await open(tester, const EarningsScreen(role: AppRole.broker), (_) {});
    expect(find.text('Your earnings appear here once a customer pays for a home you listed.'), findsOneWidget);
  });

  testWidgets('one earning: how it was worked out, where the rest went, the timeline', (tester) async {
    await open(tester, const EarningDetailScreen(role: AppRole.broker, earningId: 'e1'), (h) {
      h.money.details['e1'] = EarningDetail(
        earning: const Earning(id: 'e1', amount: 810000, state: 'ready', propertyTitle: 'Oyster Bay Reef Residence', paymentReference: 'HM-PAY-000931', tenantName: 'Rehema Kisanga'),
        monthlyRent: 1800000,
        feePercentage: 50,
        feeAmount: 900000,
        platformPercentage: 10,
        platformAmount: 90000,
        yourShare: 810000,
        split: const [
          SplitLine(beneficiary: 'broker', amount: 810000, you: true),
          SplitLine(beneficiary: 'landlord', amount: 5400000, purpose: 'rent_and_deposit'),
          SplitLine(beneficiary: 'homemate', amount: 90000),
        ],
        timeline: [
          TimelinePoint(key: 'paid', at: DateTime(2026, 9, 26), done: true),
          TimelinePoint(key: 'verified', at: DateTime(2026, 9, 27), done: true),
          const TimelinePoint(key: 'payout_created'),
          const TimelinePoint(key: 'paid_out'),
        ],
      );
    });
    expect(find.text('Your earning'), findsOneWidget);
    expect(find.text('TZS 1,800,000'), findsOneWidget);
    expect(find.text('Tenant fee (50% of one month)'), findsOneWidget);
    expect(find.text('− TZS 90,000'), findsOneWidget);
    expect(find.text('Rent and deposit to the landlord'), findsOneWidget);
    expect(find.text('TZS 5,400,000'), findsOneWidget);
    expect(find.text('Rehema Kisanga paid'), findsOneWidget);
  });

  testWidgets('payouts: the account, each payout, why one is held and how to fix it', (tester) async {
    await open(tester, const PayoutsScreen(role: AppRole.broker), (h) {
      h.money.payoutList = PayoutsOverview(
        accountMethod: 'mobile_money',
        accountProvider: 'mpesa',
        accountName: 'BARAKA MWINYI',
        accountNumber: '•••• 5678',
        items: [
          Payout(id: 'po1', amount: 810000, status: 'scheduled', reference: 'HM-PO-000044', scheduledFor: DateTime(2026, 9, 30)),
          const Payout(id: 'po2', amount: 315000, status: 'on_hold', reference: 'HM-PO-000031', holdReason: "the name on your payout account doesn't match your ID."),
          const Payout(id: 'po3', amount: 652500, status: 'paid', reference: 'HM-PO-000039', providerReference: 'QJ72KD9LX'),
        ],
      );
    });
    expect(find.text('M-Pesa •••• 5678'), findsOneWidget);
    expect(find.text('Scheduled'), findsOneWidget);
    expect(find.text("On hold: the name on your payout account doesn't match your ID."), findsOneWidget);
    expect(find.text('Receipt QJ72KD9LX'), findsOneWidget);
    await tester.tap(find.text('Update payout details'));
    await tester.pumpAndSettle();
    expect(find.text('SETUP'), findsOneWidget);
  });
}
