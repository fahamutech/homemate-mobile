import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:homemate_mobile/core/network/api_exception.dart';
import 'package:homemate_mobile/features/booking/presentation/booking_detail_screen.dart';
import 'package:homemate_mobile/features/discovery/presentation/search_screen.dart';
import 'package:homemate_mobile/features/inquiry/presentation/inquiry_form_screen.dart';
import 'package:homemate_mobile/features/payment/presentation/payment_screen.dart';
import 'package:homemate_mobile/features/property/presentation/property_screen.dart';
import 'package:homemate_mobile/features/saved/presentation/saved_screen.dart';
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

      await tester.enterText(find.byKey(const Key('search-field')), 'Masaki');
      // The field is debounced, so nothing happens until the pause elapses.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('1 home'), findsOneWidget);
      expect(find.text('Mikocheni Family House'), findsNothing);
    });

    testWidgets('a search matching nothing offers a way out', (tester) async {
      final harness = TestHarness();

      await tester.pumpWidget(harness.wrap(const SearchScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('search-field')), 'Zanzibar Villa');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('Nothing matches that'), findsOneWidget);
    });

    testWidgets('a failure explains itself and can be retried', (tester) async {
      final harness = TestHarness();
      harness.catalogue.nextFailure = ApiException.network();

      await tester.pumpWidget(harness.wrap(const SearchScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('You appear to be offline'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Try again'), findsOneWidget);
    });

    testWidgets('saving a property shows on the saved screen', (tester) async {
      final harness = TestHarness();

      await tester.pumpWidget(harness.wrap(const SearchScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Save this property'));
      await tester.pumpAndSettle();
      expect(harness.catalogue.savedIds, {'prop-1'});

      await tester.pumpWidget(harness.wrap(const SavedScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Masaki 2BR Apartment'), findsOneWidget);
    });

    testWidgets('an empty saved list says what to do about it', (tester) async {
      final harness = TestHarness();

      await tester.pumpWidget(harness.wrap(const SavedScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Nothing saved yet'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Browse homes'), findsOneWidget);
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

    testWidgets('offers both actions, with booking a viewing as the primary one', (tester) async {
      final harness = TestHarness();

      await tester.pumpWidget(harness.wrap(const PropertyScreen(propertyId: 'prop-1')));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(OutlinedButton, 'Enquire'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Book a viewing'), findsOneWidget);
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
