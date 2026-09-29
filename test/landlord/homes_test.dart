import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:homemate_mobile/features/partner_shared/data/partner_listing.dart';
import 'package:homemate_mobile/features/partner_shared/presentation/listings/partner_listing_screen.dart';
import 'package:homemate_mobile/features/partner_shared/presentation/listings/partner_listings_screen.dart';
import 'package:homemate_mobile/features/roles/data/app_role.dart';

import '../support/fakes.dart';

/// LND-020 my homes, LND-021 a home a broker listed.
void main() {
  const own = PartnerListing(id: 'p1', status: 'approved', title: 'Mikocheni Family House', price: 900000, editable: false);
  const brokered = PartnerListing(
    id: 'p2',
    status: 'draft',
    title: 'Masaki Heights Residence',
    price: 1200000,
    listedByYou: false,
    listedByName: 'Juma Broker',
    brokerName: 'Juma Broker',
    brokerPhone: '+255713700001',
    landlord: ListingLandlord(userId: 'me', name: 'Amina Mwinyi', confirmationStatus: 'pending'),
    editable: false,
  );

  Future<TestHarness> open(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = TestHarness.phone * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final harness = TestHarness(roles: FakeRoleRepository.withPartner(AppRole.landlord))..listings.viewer = 'landlord';
    harness.listings.seed(own);
    harness.listings.seed(brokered);
    await tester.pumpWidget(harness.wrap(screen, extraRoutes: [
      GoRoute(path: '/landlord/homes/:id', builder: (_, s) => Scaffold(body: Text('HOME ${s.pathParameters['id']}'))),
      GoRoute(path: '/landlord/confirm/:id', builder: (_, s) => Scaffold(body: Text('CONFIRM ${s.pathParameters['id']}'))),
    ]));
    await tester.pumpAndSettle();
    return harness;
  }

  testWidgets('my homes says who listed each one', (tester) async {
    await open(tester, const PartnerListingsScreen(role: AppRole.landlord));
    expect(find.text('Listed by you'), findsOneWidget);
    expect(find.text('Listed by Juma Broker (broker)'), findsOneWidget);
  });

  testWidgets('a broker-listed home: who the broker is, how to reach them, and the confirmation it waits for', (tester) async {
    final harness = await open(tester, const PartnerListingScreen(role: AppRole.landlord, listingId: 'p2'));
    expect(find.text('Your broker'), findsOneWidget);
    expect(find.textContaining('Juma Broker answers enquiries and changes the terms'), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('Call'));
    await tester.tap(find.byTooltip('Call'));
    await tester.tap(find.byTooltip('WhatsApp'));
    expect(harness.contact.calls, ['+255713700001']);
    expect(harness.contact.chats, ['+255713700001']);

    await tester.ensureVisible(find.text('Confirm this listing'));
    await tester.tap(find.text('Confirm this listing'));
    await tester.pumpAndSettle();
    expect(find.text('CONFIRM p2'), findsOneWidget);
  });

  testWidgets('a home the landlord listed shows no broker', (tester) async {
    await open(tester, const PartnerListingScreen(role: AppRole.landlord, listingId: 'p1'));
    expect(find.text('Your broker'), findsNothing);
    expect(find.text('Confirm this listing'), findsNothing);
  });

  testWidgets('the broker sees their own listings without a "listed by" line', (tester) async {
    tester.view.physicalSize = TestHarness.phone * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final harness = TestHarness(roles: FakeRoleRepository.withPartner(AppRole.broker));
    harness.listings.seed(own);
    await tester.pumpWidget(harness.wrap(const PartnerListingsScreen(role: AppRole.broker)));
    await tester.pumpAndSettle();
    expect(find.text('Listed by you'), findsNothing);
  });
}
