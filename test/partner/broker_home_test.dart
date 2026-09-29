import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:homemate_mobile/features/broker/presentation/broker_home_screen.dart';
import 'package:homemate_mobile/features/partner_shared/data/partner_application.dart';
import 'package:homemate_mobile/features/partner_shared/data/partner_listing.dart';
import 'package:homemate_mobile/features/partner_shared/data/partner_money.dart';
import 'package:homemate_mobile/features/roles/data/app_role.dart';
import 'package:homemate_mobile/routing/routes.dart';

import '../support/fakes.dart';

/// BRK-010 / BRK-010b: the broker home in each state of the account.
void main() {
  GoRoute stub(String path, String label) => GoRoute(path: path, builder: (_, __) => Scaffold(body: Text(label)));

  Future<TestHarness> open(WidgetTester tester, void Function(TestHarness) arrange) async {
    tester.view.physicalSize = TestHarness.phone * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final harness = TestHarness(roles: FakeRoleRepository.withPartner(AppRole.broker, status: 'applied'));
    arrange(harness);
    await tester.pumpWidget(harness.wrap(const BrokerHomeScreen(), extraRoutes: [
      stub(Routes.partnerIntro(AppRole.broker), 'INTRO'),
      stub('/broker/setup', 'SETUP'),
      stub(Routes.partnerApplication(AppRole.broker), 'APPLICATION'),
      stub(Routes.partnerListingNew(AppRole.broker), 'NEW LISTING'),
      stub('/broker/enquiries/:id', 'ENQUIRY'),
    ]));
    await tester.pumpAndSettle();
    return harness;
  }

  testWidgets('not started: straight to the broker intro', (tester) async {
    await open(tester, (h) => h.onboarding.statuses.remove('broker'));
    expect(find.text('INTRO'), findsOneWidget);
  });

  testWidgets('setting up: the setup banner, the checklist, drafting allowed', (tester) async {
    await open(tester, (h) {
      h.onboarding.details['broker'] = true;
      h.onboarding.profile = const PartnerProfile(
        fullName: 'Baraka Mwinyi',
        payout: PayoutAccount(method: 'mobile_money', provider: 'mpesa', accountNumber: '+255712345678'),
      );
    });
    expect(find.text('Finish setting up'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('M-Pesa •••• 678'), findsOneWidget);
    expect(find.text('Your ID and a selfie'), findsOneWidget);

    await tester.tap(find.text('Draft a listing'));
    await tester.pumpAndSettle();
    expect(find.text('NEW LISTING'), findsOneWidget);
  });

  testWidgets('under review: "Verification in progress" opens the application', (tester) async {
    await open(tester, (h) => h.onboarding.statuses['broker'] = 'pending_review');
    expect(find.text('Verification in progress'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('verification-banner')));
    await tester.pumpAndSettle();
    expect(find.text('APPLICATION'), findsOneWidget);
  });

  testWidgets('action needed: the red banner', (tester) async {
    await open(tester, (h) => h.onboarding.statuses['broker'] = 'action_needed');
    expect(find.text('Action needed'), findsOneWidget);
  });

  testWidgets('verified: counts, what needs the broker, the listings', (tester) async {
    await open(tester, (h) {
      h.onboarding.statuses['broker'] = 'active';
      h.money.summaryResult = const PartnerSummary(
        counts: {'liveListings': 12, 'openEnquiries': 5, 'earnedThisMonth': 1080000},
        needsYou: [
          NeedsYouItem(kind: 'enquiry', title: 'New enquiry', subtitle: 'Masaki Heights — Amina Juma', targetId: 'i1'),
          NeedsYouItem(kind: 'payment_verified', title: 'Payment verified', subtitle: 'Oyster Bay', targetId: 'e1'),
        ],
      );
      h.listings.seed(const PartnerListing(id: 'p1', status: 'approved', title: 'Masaki Heights Residence', price: 1200000));
    });

    expect(find.text('12'), findsOneWidget);
    expect(find.text('1.08M'), findsOneWidget);
    expect(find.text('Needs you'), findsOneWidget);
    expect(find.text('Payment verified'), findsOneWidget);
    expect(find.text('Masaki Heights Residence'), findsOneWidget);
    expect(find.text('Live'), findsOneWidget);

    await tester.tap(find.text('Masaki Heights — Amina Juma'));
    await tester.pumpAndSettle();
    expect(find.text('ENQUIRY'), findsOneWidget);
  });
}
