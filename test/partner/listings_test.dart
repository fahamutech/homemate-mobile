import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:homemate_mobile/features/partner_shared/data/partner_listing.dart';
import 'package:homemate_mobile/features/partner_shared/presentation/listings/listing_sent_screen.dart';
import 'package:homemate_mobile/features/partner_shared/presentation/listings/partner_listing_screen.dart';
import 'package:homemate_mobile/features/partner_shared/presentation/listings/partner_listings_screen.dart';
import 'package:homemate_mobile/features/roles/data/app_role.dart';
import 'package:homemate_mobile/routing/routes.dart';

import '../support/fakes.dart';

/// BRK-020 My listings, BRK-021 a listing with changes requested, BRK-031 sent.
void main() {
  GoRoute stub(String path, String label) => GoRoute(path: path, builder: (_, __) => Scaffold(body: Text(label)));

  Future<TestHarness> open(WidgetTester tester, Widget screen, {void Function(TestHarness)? arrange}) async {
    tester.view.physicalSize = TestHarness.phone * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final harness = TestHarness(roles: FakeRoleRepository.withPartner(AppRole.broker));
    arrange?.call(harness);
    await tester.pumpWidget(harness.wrap(screen, extraRoutes: [
      stub(Routes.partnerListingNew(AppRole.broker), 'WIZARD NEW'),
      stub('/broker/listings/:id/edit', 'WIZARD EDIT'),
      stub('/broker/listings/:id', 'DETAIL'),
      stub(Routes.brokerListings, 'LISTINGS'),
    ]));
    await tester.pumpAndSettle();
    return harness;
  }

  void seedAll(TestHarness h) {
    h.listings.seed(const PartnerListing(id: 'a', status: 'approved', title: 'Masaki Heights Residence', price: 1200000));
    h.listings.seed(const PartnerListing(id: 'b', status: 'changes_requested', title: 'Mikocheni Cosy Studio', price: 850000));
    h.listings.seed(const PartnerListing(id: 'c', status: 'draft', title: 'Mbezi Beach Villa', price: 2500000));
  }

  group('My listings (BRK-020)', () {
    testWidgets('every listing with its status; the filter narrows it', (tester) async {
      await open(tester, const PartnerListingsScreen(role: AppRole.broker), arrange: seedAll);
      expect(find.text('My listings'), findsOneWidget);
      expect(find.text('Masaki Heights Residence'), findsOneWidget);
      expect(find.text('Needs changes'), findsWidgets);
      expect(find.text('Draft'), findsWidgets);

      await tester.tap(find.byKey(const ValueKey('filter-approved')));
      await tester.pumpAndSettle();
      expect(find.text('Masaki Heights Residence'), findsOneWidget);
      expect(find.text('Mbezi Beach Villa'), findsNothing);
    });

    testWidgets('nothing yet: says so, and + adds a home', (tester) async {
      await open(tester, const PartnerListingsScreen(role: AppRole.broker));
      expect(find.text('Add your first home — it takes a few minutes.'), findsOneWidget);
      await tester.tap(find.byTooltip('Add a home'));
      await tester.pumpAndSettle();
      expect(find.text('WIZARD NEW'), findsOneWidget);
    });

    testWidgets('a listing opens its page', (tester) async {
      await open(tester, const PartnerListingsScreen(role: AppRole.broker), arrange: seedAll);
      await tester.tap(find.text('Mbezi Beach Villa'));
      await tester.pumpAndSettle();
      expect(find.text('DETAIL'), findsOneWidget);
    });
  });

  group('a listing (BRK-021)', () {
    PartnerListing changes() => PartnerListing(
          id: 'b',
          status: 'changes_requested',
          referenceCode: 'HM-P-000131',
          title: 'Mikocheni Cosy Studio',
          price: 850000,
          paymentFrequency: 'quarterly',
          depositMonths: 2,
          availableFrom: DateTime(2026, 10, 1),
          rejectionReason: 'Please add a clear photo of the kitchen.',
          landlord: const ListingLandlord(userId: 'l1', name: 'Hassan Juma'),
          createdAt: DateTime(2026, 9, 22),
          submittedAt: DateTime(2026, 9, 24),
          reviewedAt: DateTime(2026, 9, 26),
        );

    testWidgets('changes requested: the note, the summary, the history, fix and resubmit', (tester) async {
      await open(tester, const PartnerListingScreen(role: AppRole.broker, listingId: 'b'), arrange: (h) => h.listings.seed(changes()));
      expect(find.text('Mikocheni Cosy Studio'), findsOneWidget);
      expect(find.text('HM-P-000131'), findsOneWidget);
      expect(find.text('Changes requested'), findsWidgets);
      expect(find.text('Please add a clear photo of the kitchen.'), findsOneWidget);
      expect(find.text('TZS 850,000 / month'), findsOneWidget);
      expect(find.text('Every 3 months'), findsOneWidget);
      expect(find.text('Hassan Juma'), findsOneWidget);
      await tester.ensureVisible(find.text('Fix and resubmit'));
      await tester.tap(find.text('Fix and resubmit'));
      await tester.pumpAndSettle();
      expect(find.text('WIZARD EDIT'), findsOneWidget);
    });

    testWidgets('archiving asks first', (tester) async {
      final harness = await open(tester, const PartnerListingScreen(role: AppRole.broker, listingId: 'b'), arrange: (h) => h.listings.seed(changes()));
      await tester.ensureVisible(find.text('Archive listing'));
      await tester.tap(find.text('Archive listing'));
      await tester.pumpAndSettle();
      expect(find.text('Take this home off HomeMate? Customers will no longer see it.'), findsOneWidget);
      await tester.tap(find.text('Archive listing').last);
      await tester.pumpAndSettle();
      expect(harness.listings.listings['b']!.status, 'archived');
    });

    testWidgets('in review: nothing to edit', (tester) async {
      await open(tester, const PartnerListingScreen(role: AppRole.broker, listingId: 'p'), arrange: (h) {
        h.listings.seed(const PartnerListing(id: 'p', status: 'pending_review', title: 'Sinza Family House', price: 700000));
      });
      expect(find.text('In review'), findsOneWidget);
      expect(find.text('Fix and resubmit'), findsNothing);
      expect(find.text('Continue editing'), findsNothing);
    });

    testWidgets('a landlord dispute is shown to the broker', (tester) async {
      await open(tester, const PartnerListingScreen(role: AppRole.broker, listingId: 'd'), arrange: (h) {
        h.listings.seed(const PartnerListing(
          id: 'd',
          status: 'draft',
          title: 'Upanga Flat',
          landlord: ListingLandlord(userId: 'l1', name: 'Hassan Juma', confirmationStatus: 'disputed', disputeReason: 'This is not my house'),
        ));
      });
      expect(find.text('The landlord disputed this listing: This is not my house'), findsOneWidget);
    });
  });

  testWidgets('sent for review (BRK-031)', (tester) async {
    await open(tester, const ListingSentScreen(role: AppRole.broker, listingId: 'b'), arrange: (h) {
      h.listings.seed(const PartnerListing(id: 'b', status: 'pending_review', title: 'Mikocheni Cosy Studio', referenceCode: 'HM-P-000131'));
    });
    expect(find.text('Sent for review'), findsOneWidget);
    expect(find.text('HM-P-000131'), findsOneWidget);
    await tester.tap(find.text('Go to my listings'));
    await tester.pumpAndSettle();
    expect(find.text('LISTINGS'), findsOneWidget);
  });
}
