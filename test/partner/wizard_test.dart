import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:homemate_mobile/features/partner_shared/data/partner_listing.dart';
import 'package:homemate_mobile/features/partner_shared/presentation/listings/wizard/listing_wizard_screen.dart';
import 'package:homemate_mobile/features/partner_shared/presentation/listings/wizard/wizard_step.dart';
import 'package:homemate_mobile/features/roles/data/app_role.dart';
import 'package:homemate_mobile/routing/routes.dart';

import '../support/fakes.dart';

/// BRK-030a–g and BRK-031: adding a home, one saved step at a time.
void main() {
  GoRoute stub(String path, String label) => GoRoute(path: path, builder: (_, __) => Scaffold(body: Text(label)));

  Future<TestHarness> open(
    WidgetTester tester, {
    String? listingId,
    WizardStep step = WizardStep.basics,
    AppRole role = AppRole.broker,
    void Function(TestHarness)? arrange,
  }) async {
    tester.view.physicalSize = TestHarness.phone * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final harness = TestHarness(roles: FakeRoleRepository.withPartner(role, status: 'applied'));
    harness.listings.viewer = role.name;
    arrange?.call(harness);
    await tester.pumpWidget(harness.wrap(
      ListingWizardScreen(role: role, listingId: listingId, initialStep: step),
      extraRoutes: [
        stub(Routes.partnerListings(role), 'LISTINGS'),
        stub('${Routes.partnerListings(role)}/:id/sent', 'SENT'),
      ],
    ));
    await tester.pumpAndSettle();
    return harness;
  }

  PartnerListing draft({String id = 'listing-9', bool pin = true, int photos = 1, bool landlord = true}) => PartnerListing(
        id: id,
        status: 'draft',
        title: 'Mikocheni Cosy Studio',
        propertyTypeId: 'type-apartment',
        bedrooms: 1,
        bathrooms: 1,
        regionId: 'region-dar',
        latitude: pin ? -6.77 : null,
        longitude: pin ? 39.24 : null,
        price: 850000,
        depositMonths: 2,
        photos: [for (var i = 0; i < photos; i++) ListingPhoto(id: 'm$i', isCover: i == 0, position: i)],
        landlord: landlord ? const ListingLandlord(userId: 'landlord-1', name: 'Hassan Juma') : null,
      );

  Future<void> tapText(WidgetTester tester, String label) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    final finder = find.text(label).last;
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  group('basics (BRK-030a)', () {
    testWidgets('a title is needed; Continue then starts the draft and moves on', (tester) async {
      final harness = await open(tester);
      expect(find.text('STEP 1 OF 6 · BASICS'), findsOneWidget);

      await tapText(tester, 'Continue');
      expect(find.text('Give the home a title.'), findsOneWidget);
      expect(harness.listings.listings, isEmpty);

      await tester.enterText(find.byKey(const ValueKey('wizard-title')), 'Mikocheni Cosy Studio');
      await tapText(tester, 'Apartment');
      await tester.tap(find.byTooltip('Increase Bedrooms'));
      await tapText(tester, 'Continue');

      final created = harness.listings.saves.first['create'] as Map<String, dynamic>;
      expect(created['title'], 'Mikocheni Cosy Studio');
      expect(created['propertyTypeId'], 'type-apartment');
      expect(created['bedrooms'], 1);
      expect(find.text('STEP 2 OF 6 · LOCATION'), findsOneWidget);
    });

    testWidgets('Save draft saves this step and closes', (tester) async {
      final harness = await open(tester);
      await tester.enterText(find.byKey(const ValueKey('wizard-title')), 'Sinza Family House');
      await tapText(tester, 'Save draft');
      expect(harness.listings.listings.values.single.title, 'Sinza Family House');
      expect(find.text('LISTINGS'), findsOneWidget);
    });
  });

  testWidgets('location (BRK-030b): the current location drops the pin', (tester) async {
    final harness = await open(tester, listingId: 'listing-9', step: WizardStep.location, arrange: (h) => h.listings.seed(draft(pin: false)));
    expect(find.text("A home can't go live without its pin on the map."), findsOneWidget);
    await tapText(tester, 'Use my current location');
    expect(find.text('Pin set'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('wizard-street')), 'Plot 214, Mikocheni B');
    await tapText(tester, 'Continue');
    final saved = harness.listings.saves.last['listing-9'] as Map<String, dynamic>;
    expect(saved['latitude'], closeTo(-6.7576, 0.001));
    expect(saved['addressLine'], 'Plot 214, Mikocheni B');
    expect(saved['regionId'], 'region-dar');
  });

  testWidgets('rent & terms (BRK-030c): saved, and the money comes back from the server', (tester) async {
    final harness = await open(tester, listingId: 'listing-9', step: WizardStep.terms, arrange: (h) => h.listings.seed(draft()));
    await tester.enterText(find.byKey(const ValueKey('wizard-rent')), '1000000');
    await tapText(tester, '3 months');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // The preview is the server's (the fake mirrors fees.mjs): 2 months deposit + first month + 50% fee.
    expect(find.text('What the tenant pays to move in'), findsOneWidget);
    expect(find.text('TZS 3,500,000'), findsOneWidget);
    expect(find.text('You earn TZS 450,000 when this home is let'), findsOneWidget);

    await tapText(tester, 'Continue');
    final saved = harness.listings.saves.last['listing-9'] as Map<String, dynamic>;
    expect(saved['price'], 1000000);
    expect(saved['paymentFrequency'], 'quarterly');
    expect(saved['depositMonths'], 2);
  });

  testWidgets('amenities & charges (BRK-030d)', (tester) async {
    final harness = await open(tester, listingId: 'listing-9', step: WizardStep.amenities, arrange: (h) => h.listings.seed(draft()));
    await tapText(tester, 'Parking');
    await tapText(tester, 'Add a charge');
    await tester.enterText(find.byKey(const ValueKey('charge-name')), 'Service charge');
    await tester.enterText(find.byKey(const ValueKey('charge-amount')), '50000');
    await tapText(tester, 'Save');
    expect(find.text('Service charge'), findsOneWidget);
    await tapText(tester, 'Continue');
    final saved = harness.listings.saves.last['listing-9'] as Map<String, dynamic>;
    expect(saved['amenityIds'], ['amenity-parking']);
    expect((saved['charges'] as List).single['name'], 'Service charge');
    expect(find.text('STEP 5 OF 6 · LANDLORD'), findsOneWidget);
  });

  group('landlord (BRK-030e)', () {
    testWidgets('a landlord on HomeMate is found and attached', (tester) async {
      final harness = await open(tester, listingId: 'listing-9', step: WizardStep.landlord, arrange: (h) => h.listings.seed(draft(landlord: false)));
      await tester.enterText(find.byKey(const ValueKey('landlord-phone')), '+255754221908');
      await tapText(tester, 'Find');
      expect(find.text('Hassan J.'), findsOneWidget);
      expect(find.text('Landlord on HomeMate · 3 homes'), findsOneWidget);
      expect(find.text("This can't change once a customer has paid for the home."), findsOneWidget);
      await tapText(tester, 'Continue');
      expect((harness.listings.saves.last['listing-9'] as Map)['landlordUserId'], 'landlord-1');
    });

    testWidgets('one who is not is invited by name', (tester) async {
      final harness = await open(tester, listingId: 'listing-9', step: WizardStep.landlord, arrange: (h) => h.listings.seed(draft(landlord: false)));
      await tester.enterText(find.byKey(const ValueKey('landlord-phone')), '+255713000002');
      await tapText(tester, 'Find');
      expect(find.text("Not on HomeMate yet? Add their name and we'll send them an SMS to confirm."), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('landlord-name')), 'Amina Mwinyi');
      await tapText(tester, 'Invite and add');
      expect(harness.listings.invited, ['+255713000002']);
      expect(find.text('Invited — we sent them an SMS to confirm'), findsOneWidget);
      await tapText(tester, 'Continue');
      expect((harness.listings.saves.last['listing-9'] as Map)['landlordUserId'], 'invited-1');
    });

    testWidgets('no landlord, no moving on', (tester) async {
      final harness = await open(tester, listingId: 'listing-9', step: WizardStep.landlord, arrange: (h) => h.listings.seed(draft(landlord: false)));
      await tapText(tester, 'Continue');
      expect(find.text('Add the landlord of this home.'), findsWidgets);
      expect(harness.listings.saves, isEmpty);
    });
  });

  testWidgets('photos (BRK-030f): picked, made WebP, uploaded; the cover can change', (tester) async {
    final harness = await open(tester, listingId: 'listing-9', step: WizardStep.photos, arrange: (h) => h.listings.seed(draft(photos: 0)));
    await tapText(tester, 'Add photo');
    expect(harness.webp.encoded, 2);
    expect(harness.listings.listings['listing-9']!.photos, hasLength(2));
    expect(find.text('Cover'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('photo-media-2')));
    await tester.pumpAndSettle();
    await tapText(tester, 'Make it the cover');
    expect((harness.listings.saves.last['listing-9'] as Map)['photoOrder'], ['media-2', 'media-1']);
  });

  group('review (BRK-030g) and sent (BRK-031)', () {
    testWidgets('before verification it says why it cannot be sent', (tester) async {
      await open(tester, listingId: 'listing-9', step: WizardStep.review, arrange: (h) => h.listings.seed(draft()));
      expect(find.text('Review and submit'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Before this can be sent:'), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text('Before this can be sent:'), findsOneWidget);
      expect(find.text('Your partner account is still being verified — you can submit once it is approved.'), findsOneWidget);
      final send = tester.widget<InkWell>(find.byKey(const ValueKey('hm-button-Send for review')));
      expect(send.onTap, isNull);
    });

    testWidgets('once verified and complete it is sent', (tester) async {
      final harness = await open(tester, listingId: 'listing-9', step: WizardStep.review, arrange: (h) {
        h.listings.roleActive = true;
        h.listings.seed(draft());
      });
      expect(find.text('Basics'), findsOneWidget);
      expect(find.text('You earn TZS 0'), findsNothing);
      await tapText(tester, 'Send for review');
      expect(harness.listings.listings['listing-9']!.status, 'pending_review');
      expect(find.text('SENT'), findsOneWidget);
    });

    testWidgets('Edit jumps back to that step', (tester) async {
      await open(tester, listingId: 'listing-9', step: WizardStep.review, arrange: (h) => h.listings.seed(draft()));
      await tester.ensureVisible(find.byKey(const ValueKey('edit-photos')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('edit-photos')));
      await tester.pumpAndSettle();
      expect(find.text('STEP 6 OF 6 · PHOTOS'), findsOneWidget);
    });
  });

  testWidgets('a landlord listing their own home has no landlord step', (tester) async {
    await open(tester, role: AppRole.landlord);
    expect(find.text('STEP 1 OF 5 · BASICS'), findsOneWidget);
  });
}
