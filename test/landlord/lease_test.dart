import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:homemate_mobile/core/i18n/app_locale.dart';
import 'package:homemate_mobile/features/landlord/data/landlord_lease.dart';
import 'package:homemate_mobile/features/landlord/data/tenancy.dart';
import 'package:homemate_mobile/features/landlord/presentation/tenants/tenancy_lease_screen.dart';
import 'package:homemate_mobile/features/landlord/presentation/tenants/tenancy_screen.dart';
import 'package:homemate_mobile/features/rental/presentation/lease_details.dart';
import 'package:homemate_mobile/features/roles/data/app_role.dart';
import 'package:homemate_mobile/features/shared/journey_models.dart';

import '../support/fakes.dart';

/// LND-033: the landlord reads the lease behind a tenancy, the same view the
/// tenant has (CUS-012c), from the landlord's own endpoint.
void main() {
  final withAgreement = {
    'agreement': {
      'id': 'la1',
      'reference': 'HM-LA-000007',
      'version': 'v2',
      'leaseType': 'fixed_term',
      'noticePeriodDays': 60,
      'terms': 'Rent is due on the 1st.',
      'houseRules': 'No smoking indoors.',
      'acceptedAt': '2026-09-20T10:00:00Z',
    },
    'bookingReference': 'HM-BK-000031',
    'leaseStartDate': '2026-10-01',
    'leaseEndDate': '2027-09-30',
    'leaseMonths': 12,
    'monthlyRent': '800000.00',
    'currency': 'TZS',
    'depositAmount': '1600000.00',
    'propertyTitle': 'Masaki Heights Residence',
    'propertyAddress': 'Plot 12, Haile Selassie Rd',
    'tenantName': 'Neema Mushi',
  };

  group('reading the landlord endpoint', () {
    test('a drawn-up agreement', () {
      final lease = leaseFromLandlordJson(withAgreement);
      expect(lease.exists, isTrue);
      expect(lease.reference, 'HM-LA-000007');
      expect(lease.noticePeriodDays, 60);
      expect(lease.acceptedAt, DateTime.utc(2026, 9, 20, 10));
      expect(lease.monthlyRent, 800000);
      expect(lease.depositAmount, 1600000);
      expect(lease.leaseMonths, 12);
      expect(lease.leaseStartDate, DateTime(2026, 10, 1));
      expect(lease.tenantName, 'Neema Mushi');
      expect(lease.bookingReference, 'HM-BK-000031');
    });

    test('no agreement yet: the terms recorded at booking still show', () {
      final lease = leaseFromLandlordJson({...withAgreement, 'agreement': null});
      expect(lease.exists, isFalse);
      expect(lease.terms, isNull);
      expect(lease.monthlyRent, 800000);
    });
  });

  Future<TestHarness> open(WidgetTester tester, Widget screen, {AppLocale? locale, void Function(TestHarness)? arrange}) async {
    tester.view.physicalSize = TestHarness.phone * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final harness = TestHarness(roles: FakeRoleRepository.withPartner(AppRole.landlord));
    arrange?.call(harness);
    await tester.pumpWidget(harness.wrap(screen, locale: locale, extraRoutes: [
      GoRoute(path: '/landlord/tenants/:id/lease', builder: (_, s) => Scaffold(body: Text('LEASE ${s.pathParameters['id']}'))),
    ]));
    await tester.pumpAndSettle();
    return harness;
  }

  testWidgets('the landlord sees the parties, the term, the money and the rules', (tester) async {
    await open(tester, const TenancyLeaseScreen(tenancyId: 'b1'), arrange: (h) => h.tenancies.leases['b1'] = leaseFromLandlordJson(withAgreement));
    expect(find.text('Lease contract'), findsOneWidget);
    expect(find.text('Neema Mushi'), findsOneWidget);
    expect(find.text('TZS 800,000'), findsOneWidget);
    expect(find.text('60 days'), findsOneWidget);
    expect(find.text('12 months'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('No smoking indoors.'), 200);
    expect(find.text('HM-LA-000007'), findsOneWidget);
  });

  testWidgets('without an agreement it says so, and offers no download', (tester) async {
    await open(tester, const TenancyLeaseScreen(tenancyId: 'b1'),
        arrange: (h) => h.tenancies.leases['b1'] = leaseFromLandlordJson({...withAgreement, 'agreement': null}));
    expect(find.textContaining('The signed agreement is not ready yet'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Contract PDF not ready'), 200);
    expect(find.text('Contract PDF not ready'), findsOneWidget);
  });

  testWidgets('the shared lease view speaks Kiswahili', (tester) async {
    await open(tester, const Scaffold(body: LeaseDetails(lease: LeaseAgreement(bookingReference: 'HM-BK-1', leaseMonths: 1))),
        locale: AppLocale.swahili);
    expect(find.text('Wahusika'), findsOneWidget);
    expect(find.text('Mwezi 1'), findsOneWidget);
  });

  testWidgets('a tenancy links to its lease', (tester) async {
    await open(tester, const TenancyScreen(tenancyId: 'b1'),
        arrange: (h) => h.tenancies.tenancies['b1'] = const Tenancy(id: 'b1', stage: TenancyStage.current, tenantName: 'Neema Mushi'));
    await tester.scrollUntilVisible(find.text('Lease contract'), 200);
    await tester.tap(find.text('Lease contract'));
    await tester.pumpAndSettle();
    expect(find.text('LEASE b1'), findsOneWidget);
  });
}
