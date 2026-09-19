import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:homemate_mobile/core/network/api_exception.dart';
import 'package:homemate_mobile/features/booking/presentation/booking_detail_screen.dart';
import 'package:homemate_mobile/features/discovery/data/search_providers.dart';
import 'package:homemate_mobile/features/discovery/presentation/search_overlay.dart';
import 'package:homemate_mobile/features/discovery/presentation/search_screen.dart';
import 'package:homemate_mobile/features/inquiry/presentation/inquiry_form_screen.dart';
import 'package:homemate_mobile/features/payment/presentation/payment_screen.dart';
import 'package:homemate_mobile/features/property/presentation/property_screen.dart';
import 'package:homemate_mobile/features/saved/presentation/saved_screen.dart';
import 'package:homemate_mobile/features/shared/journey_models.dart';
import 'package:homemate_mobile/features/viewing/presentation/schedule_viewing_screen.dart';

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

    testWidgets('the favourites screen carries all four of its sections', (tester) async {
      // CUS-013a is not a list of saved listings: a tenancy with rent falling
      // due outranks anything a heart was once tapped on, and the enquiries
      // and viewings belong on the same screen. A regression that quietly
      // drops a section back to "saved only" fails here.
      final harness = TestHarness();
      harness.journey.overview = SavedOverview(
        activeRentals: [fakeRental()],
        activeRentalCount: 1,
        favorites: [fakeProperty(isSaved: true)],
        favoriteCount: 1,
        recentInquiries: [fakeInquirySummary()],
        inquiryCount: 1,
        upcomingBookings: [fakeViewingSummary()],
        upcomingBookingCount: 1,
      );

      await tester.pumpWidget(harness.wrap(const SavedScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Active Rents'), findsOneWidget);
      expect(find.text('Saved Favorites'), findsOneWidget);
      await reveal(tester, find.text('Recent Inquiries'));
      await reveal(tester, find.text('Upcoming Bookings'));
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

    testWidgets('offers paying outright as well as enquiring and viewing', (tester) async {
      // An enquiry is a courtesy, not a turnstile: somebody who knows this
      // listing may reserve it without asking anybody first.
      final harness = TestHarness();

      await tester.pumpWidget(harness.wrap(const PropertyScreen(propertyId: 'prop-1')));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Reserve & pay'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Enquire'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Book a viewing'), findsOneWidget);
    });

    testWidgets('falls back to viewing as the primary action when paying is not allowed',
        (tester) async {
      final harness = TestHarness();
      harness.journey.eligibility = const CheckoutEligibility(
        propertyId: 'prop-1',
        available: false,
        canPay: false,
        route: 'blocked',
      );

      await tester.pumpWidget(harness.wrap(const PropertyScreen(propertyId: 'prop-1')));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Reserve & pay'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Enquire'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Book a viewing'), findsOneWidget);
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

  group('booking a viewing', () {
    testWidgets('needs a day and a time before it will send', (tester) async {
      final harness = TestHarness();

      await tester.pumpWidget(harness.wrap(const ScheduleViewingScreen(propertyId: 'prop-1')));
      await tester.pumpAndSettle();

      await tapAfterScroll(tester, find.widgetWithText(ElevatedButton, 'Request viewing'));

      expect(find.text('Choose a day and a time'), findsOneWidget);
      expect(harness.activity.viewingList, isEmpty);
    });

    testWidgets('books a slot and records the time', (tester) async {
      final harness = TestHarness();

      await tester.pumpWidget(harness.wrap(
        const ScheduleViewingScreen(propertyId: 'prop-1'),
        extraRoutes: [
          GoRoute(
            path: '/viewing/:id',
            builder: (_, __) => const Scaffold(body: Text('Viewing requested')),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      // Tomorrow, so the slot cannot already have passed.
      await tester.tap(find.text('${DateTime.now().add(const Duration(days: 1)).day}'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ChoiceChip).first);
      await tester.pumpAndSettle();

      await tapAfterScroll(tester, find.widgetWithText(ElevatedButton, 'Request viewing'));

      expect(harness.activity.viewingList, hasLength(1));
      expect(harness.activity.viewingList.single.status, 'requested');
    });
  });

  group('paying for a booking', () {
    testWidgets('before an operator publishes details, the app says to wait', (tester) async {
      final harness = TestHarness();
      final booking = await harness.activity.createBooking(propertyId: 'prop-1');
      final payment = booking.payments.single;

      await tester.pumpWidget(harness.wrap(PaymentScreen(paymentId: payment.id)));
      await tester.pumpAndSettle();

      expect(find.text('Payment details are being prepared'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'I have paid'), findsNothing);
    });

    testWidgets('shows the account details exactly as configured', (tester) async {
      final harness = TestHarness();
      final booking = await harness.activity.createBooking(propertyId: 'prop-1');
      final payment = booking.payments.single;
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
      final booking = await harness.activity.createBooking(propertyId: 'prop-1');
      final payment = booking.payments.single;
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

    testWidgets('the booking shows the money as being checked, not as paid', (tester) async {
      final harness = TestHarness();
      final booking = await harness.activity.createBooking(propertyId: 'prop-1');

      await tester.pumpWidget(harness.wrap(BookingDetailScreen(bookingId: booking.id)));
      await tester.pumpAndSettle();

      expect(find.text('Left to pay'), findsOneWidget);
      expect(find.text('TZS 2,400,000'), findsWidgets);
    });
  });
}
