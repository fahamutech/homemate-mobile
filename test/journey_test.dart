import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:homemate_mobile/core/network/api_exception.dart';
import 'package:homemate_mobile/features/discovery/data/search_providers.dart';
import 'package:homemate_mobile/features/discovery/presentation/search_overlay.dart';
import 'package:homemate_mobile/features/discovery/presentation/search_screen.dart';
import 'package:homemate_mobile/features/inquiry/presentation/inquiry_form_screen.dart';
import 'package:homemate_mobile/features/payment/presentation/payment_screen.dart';
import 'package:homemate_mobile/features/property/presentation/property_screen.dart';
import 'package:homemate_mobile/features/saved/presentation/saved_screen.dart';
import 'package:homemate_mobile/features/shared/journey_models.dart';

import 'support/fakes.dart';

/// The journeys the app exists for, driven through the widgets.
///
/// These press the same buttons a customer does, against fakes that refuse the
/// same things the server refuses — so a screen that ignores a conflict, or
/// pretends a payment is confirmed, fails here rather than in someone's hands.
void main() {
  group('finding a home', () {
    testWidgets('searching narrows the results', (tester) async {
      final harness = TestHarness(
        catalogue: FakeCatalogueRepository(properties: [
          fakeProperty(id: 'p1', title: 'Masaki 2BR Apartment'),
          fakeProperty(id: 'p2', title: 'Mikocheni Family House'),
        ]),
      );

      await tester.pumpWidget(harness.wrap(const SearchScreen()));
      await tester.pumpAndSettle();
      expect(find.text('2 homes'), findsOneWidget);

      // The results screen reflects the shared filters; the overlay is what
      // edits them (see "the search overlay" below).
      harness.container!.read(searchFiltersProvider.notifier).setQuery('Masaki');
      await tester.pumpAndSettle();

      expect(find.text('1 home'), findsOneWidget);
      expect(find.text('Mikocheni Family House'), findsNothing);
    });

    testWidgets('a search matching nothing offers a way out', (tester) async {
      final harness = TestHarness();

      await tester.pumpWidget(harness.wrap(const SearchScreen()));
      await tester.pumpAndSettle();

      harness.container!.read(searchFiltersProvider.notifier).setQuery('Zanzibar Villa');
      await tester.pumpAndSettle();

      expect(find.text('Nothing matches that'), findsOneWidget);
    });

    testWidgets('the search overlay publishes what was typed', (tester) async {
      final harness = TestHarness();

      await tester.pumpWidget(harness.wrap(const SearchOverlay()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('search-field')), 'Masaki');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(harness.container!.read(searchFiltersProvider).query, 'Masaki');
    });

    testWidgets('the search overlay suggests matching homes as you type', (tester) async {
      final harness = TestHarness(
        catalogue: FakeCatalogueRepository(properties: [
          fakeProperty(id: 'p1', title: 'Masaki 2BR Apartment'),
          fakeProperty(id: 'p2', title: 'Mikocheni Family House'),
        ]),
      );

      await tester.pumpWidget(harness.wrap(const SearchOverlay()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('search-field')), 'Masaki');
      // Typing is debounced, so nothing happens until the pause elapses.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('Masaki 2BR Apartment'), findsOneWidget);
      expect(find.text('Mikocheni Family House'), findsNothing);
    });

    testWidgets('a failure explains itself and can be retried', (tester) async {
      final harness = TestHarness();
      harness.catalogue.nextFailure = ApiException.network();

      await tester.pumpWidget(harness.wrap(const SearchScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('You appear to be offline'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Try again'), findsOneWidget);
    });

    testWidgets('saving a property shows on the favourites screen', (tester) async {
      final harness = TestHarness();

      await tester.pumpWidget(harness.wrap(const SearchScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Save this property'));
      await tester.pumpAndSettle();
      expect(harness.catalogue.savedIds, {'prop-1'});

      // The Favourites screen reads one assembled payload rather than the
      // saved list alone, so the fake has to answer with what the server
      // would now be returning.
      harness.journey.overview = SavedOverview(
        favorites: [fakeProperty(isSaved: true)],
        favoriteCount: 1,
      );

      await tester.pumpWidget(harness.wrap(const SavedScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Masaki 2BR Apartment'), findsOneWidget);
      expect(find.text('Saved Favorites'), findsOneWidget);
    });

    testWidgets('the saved list refreshes when a heart is tapped elsewhere', (tester) async {
      // The Saved tab is a branch of an IndexedStack, so its provider stays
      // alive holding whatever it last fetched. Without an invalidation on
      // save, a heart tapped on another tab left Saved still saying "Nothing
      // saved" — which is what this test would have caught.
      final harness = TestHarness();

      await tester.pumpWidget(harness.wrap(const SearchScreen()));
      await tester.pumpAndSettle();

      // Resolve the saved list first, exactly as opening the tab would.
      final container = harness.container!;
      await container.read(savedPropertiesProvider.future);
      expect(container.read(savedPropertiesProvider).value!.items, isEmpty);

      await tester.tap(find.byTooltip('Save this property'));
      await tester.pumpAndSettle();

      final refreshed = await container.read(savedPropertiesProvider.future);
      expect(refreshed.items.map((property) => property.id), ['prop-1']);
    });

    testWidgets('an empty favourites screen says what to do about it', (tester) async {
      final harness = TestHarness();

      await tester.pumpWidget(harness.wrap(const SavedScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Nothing here yet'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Browse homes'), findsOneWidget);
    });

    testWidgets('the favourites screen carries all three of its sections', (tester) async {
      // CUS-013a is not a list of saved listings: a tenancy with rent falling
      // due outranks anything a heart was once tapped on, and the enquiries
      // belong on the same screen. A regression that quietly drops a section
      // back to "saved only" fails here.
      final harness = TestHarness();
      harness.journey.overview = SavedOverview(
        activeRentals: [fakeRental()],
        activeRentalCount: 1,
        favorites: [fakeProperty(isSaved: true)],
        favoriteCount: 1,
        recentInquiries: [fakeInquirySummary()],
        inquiryCount: 1,
      );

      await tester.pumpWidget(harness.wrap(const SavedScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Active Rents'), findsOneWidget);
      expect(find.text('Saved Favorites'), findsOneWidget);
      await reveal(tester, find.text('Recent Inquiries'));
      expect(find.text('Upcoming Bookings'), findsNothing, reason: 'viewings are gone');
    });

    testWidgets('an enquiry being paid for says the payment is being verified', (tester) async {
      final harness = TestHarness();
      harness.journey.overview = SavedOverview(
        recentInquiries: [
          fakeInquirySummary(status: 'accepted', displayStatus: 'awaiting_verification'),
        ],
        inquiryCount: 1,
      );

      await tester.pumpWidget(harness.wrap(const SavedScreen()));
      await tester.pumpAndSettle();

      await reveal(tester, find.text('Awaiting verification'));
    });

    testWidgets('an accepted enquiry reads as awaiting payment, not as accepted',
        (tester) async {
      // The customer's question is "what do I do now", and the answer for an
      // approved enquiry is "pay". Showing the raw status would leave the chip
      // and the enquiry screen giving two different answers.
      final harness = TestHarness();
      harness.journey.overview = SavedOverview(
        recentInquiries: [
          fakeInquirySummary(status: 'accepted', displayStatus: 'awaiting_payment'),
        ],
        inquiryCount: 1,
      );

      await tester.pumpWidget(harness.wrap(const SavedScreen()));
      await tester.pumpAndSettle();

      await reveal(tester, find.text('Awaiting payment'));
      expect(find.text('Accepted'), findsNothing);
    });

    testWidgets('an active rental is the way into managing the tenancy', (tester) async {
      final harness = TestHarness();
      harness.journey.overview = SavedOverview(
        activeRentals: [fakeRental()],
        activeRentalCount: 1,
      );

      await tester.pumpWidget(harness.wrap(const SavedScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Masaki 2BR Apartment'), findsOneWidget);
      expect(find.text('TZS 800,000/mo'), findsOneWidget);
      expect(find.textContaining('Next payment'), findsOneWidget);
      expect(find.text('9 months'), findsOneWidget);
    });
  });

  group('the property screen', () {
    testWidgets('shows the terms in money, not just in months', (tester) async {
      final harness = TestHarness();

      await tester.pumpWidget(harness.wrap(const PropertyScreen(propertyId: 'prop-1')));
      await tester.pumpAndSettle();

      expect(find.text('Masaki 2BR Apartment'), findsOneWidget);
      expect(find.text('TZS 800,000/month'), findsOneWidget);

      // 2 months of 800,000 — the customer should not have to work that out.
      await reveal(tester, find.textContaining('TZS 1,600,000'));
      expect(find.textContaining('TZS 1,600,000'), findsOneWidget);
    });

    testWidgets('before anything is asked, the only thing on offer is to enquire', (tester) async {
      // One road to a home: enquire, be accepted, pay. Nothing to pay for yet.
      final harness = TestHarness();
      harness.journey.eligibility = const CheckoutEligibility(
        propertyId: 'prop-1',
        available: true,
        route: 'no_inquiry',
      );

      await tester.pumpWidget(harness.wrap(const PropertyScreen(propertyId: 'prop-1')));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Enquire'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Pay to secure it'), findsNothing);
      expect(find.textContaining('Book a viewing'), findsNothing);
      expect(find.textContaining('Reserve & pay'), findsNothing);
    });

    testWidgets('while the landlord decides, it points back at the enquiry', (tester) async {
      final harness = TestHarness();
      harness.catalogue.myInquiry = (id: 'inq-1', status: 'pending');
      harness.journey.eligibility = const CheckoutEligibility(
        propertyId: 'prop-1',
        available: true,
        route: 'inquiry_pending',
      );

      await tester.pumpWidget(harness.wrap(const PropertyScreen(propertyId: 'prop-1')));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(OutlinedButton, 'View enquiry'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Pay to secure it'), findsNothing);
    });

    testWidgets('once the landlord accepts, paying is the next step', (tester) async {
      final harness = TestHarness();
      harness.catalogue.myInquiry = (id: 'inq-1', status: 'accepted');

      await tester.pumpWidget(harness.wrap(const PropertyScreen(propertyId: 'prop-1')));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Pay to secure it'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'View enquiry'), findsOneWidget);
    });

    testWidgets('shows the HomeMate fee before anyone enquires, with what it saves',
        (tester) async {
      final harness = TestHarness();

      await tester.pumpWidget(harness.wrap(const PropertyScreen(propertyId: 'prop-1')));
      await tester.pumpAndSettle();

      // It is counted in what has to be found before moving in:
      // 1,600,000 deposit + 800,000 first month + 400,000 fee.
      await reveal(tester, find.text('TZS 2,800,000'));
      expect(find.text('HomeMate fee · 50% of a month'), findsOneWidget);

      await reveal(tester, find.byKey(const Key('service-fee-card')));
      expect(find.text('HomeMate fee: TZS 400,000'), findsOneWidget);
      expect(find.text("Usual agent fee (one month's rent)"), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('service-fee-saving'))).data,
        'TZS 400,000',
      );
    });

    testWidgets('says so rather than failing when someone else is mid-payment',
        (tester) async {
      final harness = TestHarness();
      harness.journey.eligibility = const CheckoutEligibility(
        propertyId: 'prop-1',
        available: true,
        canPay: true,
        heldByOther: true,
        holdSecondsRemaining: 240,
      );

      await tester.pumpWidget(harness.wrap(const PropertyScreen(propertyId: 'prop-1')));
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Someone is paying for this'),
      );
      expect(button.onPressed, isNull, reason: 'a button that would 409 must not be tappable');
    });

    testWidgets('a listing that is gone says so rather than showing a blank page', (tester) async {
      final harness = TestHarness();

      await tester.pumpWidget(harness.wrap(const PropertyScreen(propertyId: 'does-not-exist')));
      await tester.pumpAndSettle();

      expect(find.text('Property not found'), findsOneWidget);
    });
  });

  group('enquiring', () {
    testWidgets('sends an enquiry with what the landlord needs to answer', (tester) async {
      final harness = TestHarness();

      await tester.pumpWidget(harness.wrap(
        const InquiryFormScreen(propertyId: 'prop-1'),
        extraRoutes: [
          GoRoute(
            path: '/enquiry/:id',
            builder: (_, __) => const Scaffold(body: Text('Enquiry sent')),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('inquiry-message')),
        'Is it available from November?',
      );
      await tapAfterScroll(tester, find.widgetWithText(ElevatedButton, 'Send enquiry'));

      expect(harness.activity.inquiryList, hasLength(1));
      expect(harness.activity.inquiryList.single.message, 'Is it available from November?');
      // Occupants defaults to 1 rather than being left null.
      expect(harness.activity.inquiryList.single.occupants, 1);
    });

    testWidgets('an empty message is refused before it is sent', (tester) async {
      final harness = TestHarness();

      await tester.pumpWidget(harness.wrap(const InquiryFormScreen(propertyId: 'prop-1')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('inquiry-message')), '   ');
      await tapAfterScroll(tester, find.widgetWithText(ElevatedButton, 'Send enquiry'));

      expect(find.text('Write a short message'), findsOneWidget);
      expect(harness.activity.inquiryList, isEmpty);
    });

    testWidgets('a second enquiry for the same place is refused with the reason', (tester) async {
      final harness = TestHarness();
      await harness.activity.createInquiry(propertyId: 'prop-1', message: 'First ask');

      await tester.pumpWidget(harness.wrap(const InquiryFormScreen(propertyId: 'prop-1')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('inquiry-message')), 'Asking again');
      await tapAfterScroll(tester, find.widgetWithText(ElevatedButton, 'Send enquiry'));

      expect(find.text('You already have an open enquiry for this property'), findsOneWidget);
      expect(harness.activity.inquiryList, hasLength(1));
    });
  });

  group('paying once accepted', () {
    testWidgets('before an operator publishes details, the app says to wait', (tester) async {
      final harness = TestHarness();
      final payment = harness.activity.seedCheckoutPayment();

      await tester.pumpWidget(harness.wrap(PaymentScreen(paymentId: payment.id)));
      await tester.pumpAndSettle();

      expect(find.text('Payment details are being prepared'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'I have paid'), findsNothing);
    });

    testWidgets('shows the account details exactly as configured', (tester) async {
      final harness = TestHarness();
      final payment = harness.activity.seedCheckoutPayment();
      harness.activity.publishInstructions(payment.id);

      await tester.pumpWidget(harness.wrap(PaymentScreen(paymentId: payment.id)));
      await tester.pumpAndSettle();

      expect(findValue('5566778'), findsOneWidget);
      expect(findValue('HM-BK-000001'), findsOneWidget);
      expect(findValue('HomeMate Africa Ltd'), findsOneWidget);
      // An M-Pesa number is a Lipa Namba, not an "account number".
      expect(find.text('Lipa Namba'), findsOneWidget);

      await reveal(tester, find.widgetWithText(ElevatedButton, 'I have paid'));
      expect(find.widgetWithText(ElevatedButton, 'I have paid'), findsOneWidget);
    });

    testWidgets('"I have paid" records a claim and does not pretend it is confirmed',
        (tester) async {
      final harness = TestHarness();
      final payment = harness.activity.seedCheckoutPayment();
      harness.activity.publishInstructions(payment.id);

      await tester.pumpWidget(harness.wrap(PaymentScreen(paymentId: payment.id)));
      await tester.pumpAndSettle();

      await tapAfterScroll(tester, find.widgetWithText(ElevatedButton, 'I have paid'));
      await tester.enterText(find.byType(TextField).last, 'QJ12KL9MN');
      await tester.tap(find.widgetWithText(FilledButton, 'I have paid'));
      await tester.pumpAndSettle();

      final updated = await harness.activity.payment(payment.id);
      expect(updated.customerState, 'awaiting_verification');
      expect(updated.status, 'pending', reason: 'a claim must never settle a payment');
      expect(updated.declaredReference, 'QJ12KL9MN');

      await reveal(tester, find.text('We are checking your payment'));
      expect(find.text('We are checking your payment'), findsOneWidget);
      expect(find.text('Payment received'), findsNothing);
    });

  });
}
