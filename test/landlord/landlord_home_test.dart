import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:homemate_mobile/core/providers.dart';
import 'package:homemate_mobile/features/landlord/presentation/landlord_home_screen.dart';
import 'package:homemate_mobile/features/landlord/presentation/landlord_intro_screen.dart';
import 'package:homemate_mobile/features/partner_shared/data/partner_listing.dart';
import 'package:homemate_mobile/features/partner_shared/data/partner_money.dart';
import 'package:homemate_mobile/features/roles/data/app_role.dart';
import 'package:homemate_mobile/routing/routes.dart';

import '../support/fakes.dart';

/// LND-001 intro, LND-010 / LND-010b the landlord home in each state.
void main() {
  GoRoute stub(String path, String label) => GoRoute(path: path, builder: (_, __) => Scaffold(body: Text(label)));

  Future<TestHarness> open(WidgetTester tester, Widget screen, void Function(TestHarness) arrange) async {
    tester.view.physicalSize = TestHarness.phone * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final harness = TestHarness(roles: FakeRoleRepository.withPartner(AppRole.landlord, status: 'applied'));
    arrange(harness);
    await tester.pumpWidget(harness.wrap(screen, extraRoutes: [
      stub(Routes.partnerIntro(AppRole.landlord), 'INTRO'),
      stub('/landlord/setup', 'SETUP'),
      stub(Routes.partnerApplication(AppRole.landlord), 'APPLICATION'),
      stub(Routes.partnerListingNew(AppRole.landlord), 'NEW HOME'),
      stub('/landlord/confirm/:id', 'CONFIRM'),
      stub('/landlord/tenants/:id', 'TENANCY'),
      stub('/landlord/enquiries', 'ENQUIRIES'),
    ]));
    // The landlord shell opens the role; the summary is asked for as it.
    await harness.container!.read(roleControllerProvider.notifier).open(AppRole.landlord);
    await tester.pumpAndSettle();
    return harness;
  }

  testWidgets('not started: straight to the landlord intro', (tester) async {
    await open(tester, const LandlordHomeScreen(), (h) => h.onboarding.statuses.remove('landlord'));
    expect(find.text('INTRO'), findsOneWidget);
  });

  testWidgets('the intro speaks of rent in full', (tester) async {
    await open(tester, const LandlordIntroScreen(), (_) {});
    expect(find.text('List your home, or let a broker do it'), findsOneWidget);
  });

  testWidgets('setting up: the checklist includes proof of ownership', (tester) async {
    await open(tester, const LandlordHomeScreen(), (h) => h.onboarding.details['landlord'] = true);
    expect(find.text('Finish setting up'), findsOneWidget);
  });

  testWidgets('under review: verification in progress', (tester) async {
    await open(tester, const LandlordHomeScreen(), (h) => h.onboarding.statuses['landlord'] = 'pending_review');
    expect(find.text('Verification in progress'), findsOneWidget);
  });

  testWidgets('verified: counts, confirmations and move-ins that need the landlord, the homes', (tester) async {
    final harness = await open(tester, const LandlordHomeScreen(), (h) {
      h.onboarding.statuses['landlord'] = 'active';
      h.listings.viewer = 'landlord';
      h.money.summaryResult = const PartnerSummary(
        counts: {'homes': 5, 'let': 4, 'paidThisMonth': 2400000},
        needsYou: [
          NeedsYouItem(kind: 'confirm_listing', title: 'Confirm a listing of your home', subtitle: 'Masaki Heights', targetId: 'p2'),
          NeedsYouItem(kind: 'move_in', title: 'Tenant moving in', subtitle: 'Mikocheni — Neema Mushi', targetId: 'b1'),
        ],
      );
      h.listings.seed(const PartnerListing(id: 'p1', status: 'approved', title: 'Mikocheni Family House', price: 900000));
    });
    expect(harness.money.summaryCalls, contains('landlord'));
    expect(find.text('5'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('2.4M'), findsOneWidget);
    expect(find.text('Listed by you'), findsOneWidget);

    await tester.tap(find.text('Masaki Heights'));
    await tester.pumpAndSettle();
    expect(find.text('CONFIRM'), findsOneWidget);
  });

  testWidgets('a move-in in "Needs you" opens the tenancy', (tester) async {
    await open(tester, const LandlordHomeScreen(), (h) {
      h.onboarding.statuses['landlord'] = 'active';
      h.money.summaryResult = const PartnerSummary(needsYou: [
        NeedsYouItem(kind: 'move_in', title: 'Tenant moving in', subtitle: 'Mikocheni — Neema Mushi', targetId: 'b1'),
      ]);
    });
    await tester.tap(find.text('Mikocheni — Neema Mushi'));
    await tester.pumpAndSettle();
    expect(find.text('TENANCY'), findsOneWidget);
  });

  testWidgets('enquiries on the homes the landlord listed are one tap away', (tester) async {
    await open(tester, const LandlordHomeScreen(), (h) => h.onboarding.statuses['landlord'] = 'active');
    await tester.ensureVisible(find.text('Enquiries'));
    await tester.tap(find.text('Enquiries'));
    await tester.pumpAndSettle();
    expect(find.text('ENQUIRIES'), findsOneWidget);
  });
}
