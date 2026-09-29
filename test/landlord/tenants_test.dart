import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:homemate_mobile/features/landlord/data/tenancy.dart';
import 'package:homemate_mobile/features/landlord/presentation/tenants/tenancy_screen.dart';
import 'package:homemate_mobile/features/landlord/presentation/tenants/tenants_screen.dart';
import 'package:homemate_mobile/features/roles/data/app_role.dart';
import 'package:homemate_mobile/features/shared/models.dart';

import '../support/fakes.dart';

/// LND-030 tenants, LND-031 moving in, LND-032 confirm move-in, LND-033
/// living here, and ending a tenancy.
void main() {
  final today = DateTime.now();
  final day = DateTime(today.year, today.month, today.day);

  Tenancy tenancy(String id, TenancyStage stage, {String name = 'Neema Mushi'}) => Tenancy(
        id: id,
        stage: stage,
        status: switch (stage) { TenancyStage.movingIn => 'confirmed', TenancyStage.current => 'active', TenancyStage.past => 'completed' },
        reference: 'HM-BK-$id',
        tenantName: name,
        tenantPhone: '+255712000009',
        propertyId: 'p1',
        propertyTitle: 'Masaki Heights Residence',
        monthlyRent: 800000,
        depositAmount: 1600000,
        leaseMonths: 12,
        leaseStartDate: day.subtract(const Duration(days: 3)),
        leaseEndDate: day.add(const Duration(days: 362)),
        moveInDate: stage == TenancyStage.movingIn ? null : day.subtract(const Duration(days: 3)),
        endedOn: stage == TenancyStage.past ? DateTime(2026, 9, 30) : null,
        nextPaymentDate: stage == TenancyStage.current ? DateTime(2026, 11, 1) : null,
        amountPaid: 2400000,
        payments: const [
          CustomerPayment(id: 'pay1', reference: 'HM-PAY-1', amount: 2400000, currency: 'TZS', status: 'successful', customerState: 'paid', purpose: 'checkout'),
        ],
      );

  Future<TestHarness> open(WidgetTester tester, Widget screen, void Function(TestHarness) arrange) async {
    tester.view.physicalSize = TestHarness.phone * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final harness = TestHarness(roles: FakeRoleRepository.withPartner(AppRole.landlord));
    arrange(harness);
    await tester.pumpWidget(harness.wrap(screen, extraRoutes: [
      GoRoute(path: '/landlord/tenants/:id', builder: (_, s) => Scaffold(body: Text('TENANCY ${s.pathParameters['id']}'))),
    ]));
    await tester.pumpAndSettle();
    return harness;
  }

  Future<void> tapText(WidgetTester tester, String label) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    final finder = find.text(label).last;
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  group('the list (LND-030)', () {
    testWidgets('moving in, living here and past; only moving-in offers the move-in', (tester) async {
      await open(tester, const TenantsScreen(), (h) {
        h.tenancies.tenancies['b1'] = tenancy('b1', TenancyStage.movingIn);
        h.tenancies.tenancies['b2'] = tenancy('b2', TenancyStage.current, name: 'Grace Mollel');
        h.tenancies.tenancies['b3'] = tenancy('b3', TenancyStage.past, name: 'Baraka Said');
      });
      expect(find.text('Neema Mushi'), findsOneWidget);
      expect(find.text('Grace Mollel'), findsNothing);
      expect(find.text('Confirm move-in'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('tenants-tab-current')));
      await tester.pumpAndSettle();
      expect(find.text('Grace Mollel'), findsOneWidget);
      expect(find.text('Next rent 1 Nov'), findsOneWidget);
      expect(find.text('Confirm move-in'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('tenants-tab-past')));
      await tester.pumpAndSettle();
      expect(find.text('Ended 30 Sep'), findsOneWidget);

      await tester.tap(find.text('Baraka Said'));
      await tester.pumpAndSettle();
      expect(find.text('TENANCY b3'), findsOneWidget);
    });

    testWidgets('an empty stage says what brings a tenant here', (tester) async {
      await open(tester, const TenantsScreen(), (_) {});
      expect(find.text('No one is moving in yet. A tenant appears here once their payment is verified.'), findsOneWidget);
    });
  });

  group('one tenancy', () {
    testWidgets('moving in: the move-in needs a day, then starts the tenancy (LND-031/032)', (tester) async {
      final harness = await open(tester, const TenancyScreen(tenancyId: 'b1'), (h) => h.tenancies.tenancies['b1'] = tenancy('b1', TenancyStage.movingIn));
      expect(find.text('TZS 800,000'), findsOneWidget);
      expect(find.text('End tenancy'), findsNothing);

      await tapText(tester, 'Confirm move-in');
      await tapText(tester, 'Confirm and start tenancy');
      expect(find.text('Pick the day they moved in.'), findsOneWidget);
      expect(harness.tenancies.movedIn, isEmpty);

      await tapText(tester, 'Pick a day');
      await tapText(tester, 'OK');
      await tapText(tester, 'Confirm and start tenancy');
      expect(harness.tenancies.movedIn.single.$1, 'b1');
      expect(harness.tenancies.movedIn.single.$2, day);
      expect(find.text('Confirm move-in'), findsNothing);
      expect(find.text('End tenancy'), findsOneWidget, reason: 'the tenancy has started');
    });

    testWidgets('living here: ending needs a day; the reason is optional (LND-033)', (tester) async {
      final harness = await open(tester, const TenancyScreen(tenancyId: 'b2'), (h) => h.tenancies.tenancies['b2'] = tenancy('b2', TenancyStage.current));
      expect(find.text('Confirm move-in'), findsNothing);
      expect(find.text('HM-PAY-1'), findsOneWidget);

      await tapText(tester, 'End tenancy');
      await tapText(tester, 'End tenancy');
      expect(find.text('Pick the day it ended.'), findsOneWidget);
      expect(harness.tenancies.ended, isEmpty);

      await tapText(tester, 'Pick a day');
      await tapText(tester, 'OK');
      await tester.enterText(find.byKey(const ValueKey('end-reason')), 'Moved out at the end of the lease');
      await tapText(tester, 'End tenancy');
      expect(harness.tenancies.ended.single, ('b2', day, 'Moved out at the end of the lease'));
      expect(find.text('End tenancy'), findsNothing);
    });

    testWidgets('past: nothing left to do', (tester) async {
      await open(tester, const TenancyScreen(tenancyId: 'b3'), (h) => h.tenancies.tenancies['b3'] = tenancy('b3', TenancyStage.past));
      expect(find.text('Confirm move-in'), findsNothing);
      expect(find.text('End tenancy'), findsNothing);
      expect(find.text('Ended 30 Sep'), findsOneWidget);
    });

    testWidgets('the tenant can be called or messaged', (tester) async {
      final harness = await open(tester, const TenancyScreen(tenancyId: 'b2'), (h) => h.tenancies.tenancies['b2'] = tenancy('b2', TenancyStage.current));
      await tester.tap(find.byTooltip('Call'));
      await tester.tap(find.byTooltip('WhatsApp'));
      expect(harness.contact.calls, ['+255712000009']);
      expect(harness.contact.chats, ['+255712000009']);
    });
  });
}
