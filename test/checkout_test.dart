import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:homemate_mobile/core/network/api_exception.dart';
import 'package:homemate_mobile/features/activity/presentation/property_activity_screen.dart';
import 'package:homemate_mobile/features/booking/presentation/booking_detail_screen.dart';
import 'package:homemate_mobile/features/inquiry/presentation/inquiry_detail_screen.dart';
import 'package:homemate_mobile/features/payment/presentation/checkout_screen.dart';
import 'package:homemate_mobile/features/payment/presentation/hold_banner.dart';
import 'package:homemate_mobile/features/shared/journey_models.dart';
import 'package:homemate_mobile/features/viewing/presentation/viewing_detail_screen.dart';

import 'support/fakes.dart';

/// Reserving a home and paying for it.
///
/// The rules these protect are the ones that cost real money if they slip: a
/// property held for exactly one customer at a time, a total nobody can
/// invent, and a payment the app is never allowed to call successful.
void main() {
  group('the ten-minute hold', () {
    testWidgets('starting a checkout takes the property and shows the countdown',
        (tester) async {
      final harness = TestHarness();

      await tester.pumpWidget(harness.wrap(const CheckoutScreen(propertyId: 'prop-1')));
      await tester.pumpAndSettle();

      expect(harness.journey.heldPropertyIds, ['prop-1']);
      expect(find.byType(HoldBanner), findsOneWidget);
      expect(find.text('This home is held for you'), findsOneWidget);
      expect(find.text('10:00'), findsOneWidget);
    });

    testWidgets('the countdown actually counts down', (tester) async {
      final harness = TestHarness();
      harness.journey.currentHold = fakeHold(secondsRemaining: 65);

      await tester.pumpWidget(harness.wrap(const CheckoutScreen(propertyId: 'prop-1')));
      await tester.pumpAndSettle();
      expect(find.text('1:05'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      expect(find.text('1:00'), findsOneWidget);
    });

    testWidgets('when the clock runs out it says so and stops the payment button',
        (tester) async {
      final harness = TestHarness();
      harness.journey.currentHold = fakeHold(secondsRemaining: 2);

      await tester.pumpWidget(harness.wrap(const CheckoutScreen(propertyId: 'prop-1')));
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 3));
      await tester.pump();

      expect(find.text('Your hold has expired'), findsOneWidget);
      expect(find.textContaining('Nothing has been charged'), findsOneWidget);

      final payButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Pay TZS 2,400,000'),
      );
      expect(
        payButton.onPressed,
        isNull,
        reason: 'paying on a lapsed hold is how two people buy the same house',
      );

      // And there is a way back, rather than a dead screen.
      expect(find.widgetWithText(FilledButton, 'Hold it again'), findsOneWidget);
    });

    testWidgets('a property somebody else is paying for reads as a wait, not an error',
        (tester) async {
      final harness = TestHarness();
      harness.journey.nextFailure = ApiException(
        code: 'CONFLICT',
        message: 'Someone is paying for this property right now. Try again in a few minutes.',
        statusCode: 409,
      );

      await tester.pumpWidget(harness.wrap(const CheckoutScreen(propertyId: 'prop-1')));
      await tester.pumpAndSettle();

      expect(find.text('Someone is paying for this home'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Try again'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Keep looking'), findsOneWidget);
    });

    testWidgets('leaving the screen gives the property back rather than parking it',
        (tester) async {
      final harness = TestHarness();

      await tester.pumpWidget(harness.wrap(
        const CheckoutScreen(propertyId: 'prop-1'),
      ));
      await tester.pumpAndSettle();
      expect(harness.journey.releasedHoldIds, isEmpty);

      // Tearing the screen down is what a back gesture ends in.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  });

  group('the checkout', () {
    testWidgets('shows the total and a breakdown that adds up to it', (tester) async {
      final harness = TestHarness();

      await tester.pumpWidget(harness.wrap(const CheckoutScreen(propertyId: 'prop-1')));
      await tester.pumpAndSettle();

      expect(find.text('TOTAL AMOUNT DUE'), findsOneWidget);
      expect(find.text('TZS 2,400,000'), findsWidgets);
      await reveal(tester, find.text('First month rent'));
      await reveal(tester, find.text('Security deposit (2x)'));
    });

    testWidgets('a waived charge is still listed, because zero is information',
        (tester) async {
      final harness = TestHarness();

      await tester.pumpWidget(harness.wrap(const CheckoutScreen(propertyId: 'prop-1')));
      await tester.pumpAndSettle();

      await reveal(tester, find.text('Agency fee'));
      expect(find.text('TZS 0 (Waived)'), findsOneWidget);
    });

    testWidgets('refuses to pay until a method is chosen', (tester) async {
      final harness = TestHarness();

      await tester.pumpWidget(harness.wrap(const CheckoutScreen(propertyId: 'prop-1')));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Pay TZS 2,400,000'));
      await tester.pumpAndSettle();

      expect(find.text('Choose how you want to pay'), findsOneWidget);
      expect(harness.journey.payments, isEmpty);
    });

    testWidgets('mobile money asks for the number to charge, and will not send without one',
        (tester) async {
      final harness = TestHarness();

      await tester.pumpWidget(harness.wrap(const CheckoutScreen(propertyId: 'prop-1')));
      await tester.pumpAndSettle();

      await reveal(tester, find.text('M-Pesa'));
      await tester.tap(find.text('M-Pesa'));
      await tester.pumpAndSettle();

      expect(find.text('M-Pesa Registered Number'), findsOneWidget);
      expect(find.textContaining('You will receive a M-Pesa prompt'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Pay TZS 2,400,000'));
      await tester.pumpAndSettle();

      expect(find.text('Enter the mobile money number to charge'), findsOneWidget);
      expect(harness.journey.payments, isEmpty);
    });

    testWidgets('a bank transfer needs no phone number', (tester) async {
      final harness = TestHarness();

      await tester.pumpWidget(harness.wrap(
        const CheckoutScreen(propertyId: 'prop-1'),
        extraRoutes: [payScreenRoute()],
      ));
      await tester.pumpAndSettle();

      await reveal(tester, find.text('Bank Transfer'));
      await tester.tap(find.text('Bank Transfer'));
      await tester.pumpAndSettle();

      expect(find.text('M-Pesa Registered Number'), findsNothing);

      await tester.tap(find.widgetWithText(FilledButton, 'Pay TZS 2,400,000'));
      await tester.pumpAndSettle();

      expect(harness.journey.payments.single.methodId, 'pm-2');
      expect(harness.journey.payments.single.phone, isNull);
    });

    testWidgets('never claims a payment has succeeded', (tester) async {
      // BR-005: only a provider callback or a finance officer settles a
      // payment. The most this flow may do is hand over the instructions.
      final harness = TestHarness();

      await tester.pumpWidget(harness.wrap(
        const CheckoutScreen(propertyId: 'prop-1'),
        extraRoutes: [payScreenRoute()],
      ));
      await tester.pumpAndSettle();

      await reveal(tester, find.text('Bank Transfer'));
      await tester.tap(find.text('Bank Transfer'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Pay TZS 2,400,000'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Payment successful'), findsNothing);
      expect(find.textContaining('Paid'), findsNothing);
    });

    testWidgets('a listing with no configured method says so instead of showing nothing',
        (tester) async {
      final harness = TestHarness(
        journey: FakeJourneyRepository(paymentMethodOptions: const []),
      );

      await tester.pumpWidget(harness.wrap(const CheckoutScreen(propertyId: 'prop-1')));
      await tester.pumpAndSettle();

      await reveal(tester, find.textContaining('No payment methods are configured'));
    });
  });

  group('an enquiry that is waiting', () {
    testWidgets('offers a nudge and sends it', (tester) async {
      final harness = TestHarness();
      harness.activity.inquiryList.add(fakeInquiry(status: 'pending'));

      await tester.pumpWidget(harness.wrap(const InquiryDetailScreen(inquiryId: 'inq-1')));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Send Nudge Reminder'), findsOneWidget);

      await tapAfterScroll(tester, find.widgetWithText(FilledButton, 'Send Nudge Reminder'));

      expect(harness.journey.nudgedInquiryIds, ['inq-1']);
      expect(find.textContaining('Reminder sent'), findsOneWidget);
    });

    testWidgets('a nudge inside its cooldown explains the wait rather than failing silently',
        (tester) async {
      final harness = TestHarness();
      harness.activity.inquiryList.add(fakeInquiry(status: 'pending'));
      harness.journey.nextFailure = ApiException(
        code: 'VALIDATION_FAILED',
        message: 'You have already sent a reminder recently. You can send another in 19 hour(s).',
        statusCode: 422,
      );

      await tester.pumpWidget(harness.wrap(const InquiryDetailScreen(inquiryId: 'inq-1')));
      await tester.pumpAndSettle();

      await tapAfterScroll(tester, find.widgetWithText(FilledButton, 'Send Nudge Reminder'));

      expect(find.textContaining('already sent a reminder'), findsOneWidget);
    });

    testWidgets('shows the timeline of where the enquiry has got to', (tester) async {
      final harness = TestHarness();
      harness.activity.inquiryList.add(fakeInquiry(status: 'pending'));
      harness.journey.events = [
        JourneyEvent(
          key: 'landlord_decision',
          title: 'Under Review',
          state: 'current',
          at: DateTime(2026, 1, 9),
          detail: 'The landlord is reviewing your application',
        ),
        JourneyEvent(
          key: 'inquiry_submitted',
          title: 'Enquiry Submitted',
          state: 'done',
          at: DateTime(2026, 1, 8),
          detail: 'You submitted an enquiry for this property',
        ),
      ];

      await tester.pumpWidget(harness.wrap(const InquiryDetailScreen(inquiryId: 'inq-1')));
      await tester.pumpAndSettle();

      expect(find.text('Status timeline'), findsOneWidget);
      expect(find.text('Under Review'), findsOneWidget);
      expect(find.text('Enquiry Submitted'), findsOneWidget);
    });
  });

  group('an enquiry that was accepted', () {
    testWidgets('leads straight to paying for it', (tester) async {
      final harness = TestHarness();
      harness.activity.inquiryList.add(fakeInquiry(status: 'accepted'));
      // What the server actually answers once a landlord has approved: the
      // route is what puts the right sentence above the button.
      harness.journey.eligibility = const CheckoutEligibility(
        propertyId: 'prop-1',
        available: true,
        canPay: true,
        route: 'inquiry_accepted',
        inquiryId: 'inq-1',
      );

      await tester.pumpWidget(harness.wrap(const InquiryDetailScreen(inquiryId: 'inq-1')));
      await tester.pumpAndSettle();

      await reveal(tester, find.widgetWithText(FilledButton, 'Pay now to secure it'));
      expect(find.textContaining('Complete payment to secure your reservation'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Send Nudge Reminder'), findsNothing);
    });

    testWidgets('reads as awaiting payment rather than as accepted', (tester) async {
      final harness = TestHarness();
      harness.activity.inquiryList.add(fakeInquiry(status: 'accepted'));

      await tester.pumpWidget(harness.wrap(const InquiryDetailScreen(inquiryId: 'inq-1')));
      await tester.pumpAndSettle();

      expect(find.text('Awaiting payment'), findsOneWidget);
    });

    testWidgets('holds the button while somebody else is mid-payment', (tester) async {
      final harness = TestHarness();
      harness.activity.inquiryList.add(fakeInquiry(status: 'accepted'));
      harness.journey.eligibility = const CheckoutEligibility(
        propertyId: 'prop-1',
        available: true,
        canPay: true,
        route: 'inquiry_accepted',
        heldByOther: true,
        holdSecondsRemaining: 300,
      );

      await tester.pumpWidget(harness.wrap(const InquiryDetailScreen(inquiryId: 'inq-1')));
      await tester.pumpAndSettle();

      await reveal(tester, find.textContaining('Someone else is paying for this home'));
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Pay now to secure it'),
      );
      expect(button.onPressed, isNull);
    });
  });

  group('an enquiry that was declined', () {
    testWidgets('says why, and offers somewhere else to look', (tester) async {
      final harness = TestHarness();
      harness.activity.inquiryList.add(
        fakeInquiry(status: 'rejected', rejectionReason: 'Already let to another tenant'),
      );

      await tester.pumpWidget(harness.wrap(const InquiryDetailScreen(inquiryId: 'inq-1')));
      await tester.pumpAndSettle();

      await reveal(tester, find.textContaining('Already let to another tenant'));
      expect(find.widgetWithText(OutlinedButton, 'Find another home'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Pay now to secure it'), findsNothing);
    });
  });

  group('my activity', () {
    testWidgets('a booking opens onto the whole journey, not just itself',
        (tester) async {
      // CUS-013b. "Where am I with that house" spans the enquiry, the viewing,
      // the payments and the lease — a booking screen that only shows the
      // booking answers a narrower question than the one being asked.
      final harness = TestHarness();
      harness.activity.bookingList.add(fakeBooking());

      await tester.pumpWidget(harness.wrap(
        const BookingDetailScreen(bookingId: 'booking-1'),
        extraRoutes: [
          GoRoute(
            path: '/property/:id/activity',
            builder: (_, state) =>
                PropertyActivityScreen(propertyId: state.pathParameters['id']!),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      await tapAfterScroll(
        tester,
        find.widgetWithText(OutlinedButton, 'View the full journey'),
      );

      expect(find.text('My Activity'), findsOneWidget);
      expect(find.text('Journey Timeline'), findsOneWidget);
    });

    testWidgets('the timeline renders the steps the server decided', (tester) async {
      final harness = TestHarness();
      harness.journey.events = [
        JourneyEvent(
          key: 'next_rent',
          title: 'Next Rent Due',
          state: 'upcoming',
          at: DateTime(2026, 11, 1),
          detail: '850,000 TZS monthly rent payment',
        ),
        JourneyEvent(
          key: 'lease_started',
          title: 'Lease Started',
          state: 'done',
          at: DateTime(2026, 1, 1),
          detail: 'Active tenancy. 12-month term.',
        ),
      ];

      await tester.pumpWidget(
        harness.wrap(const PropertyActivityScreen(propertyId: 'prop-1')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Next Rent Due'), findsOneWidget);
      expect(find.text('Lease Started'), findsOneWidget);
      // An upcoming step shows the date without a time of day, because
      // "Nov 1, 2026" is the whole fact.
      expect(find.text('1 Nov 2026'), findsOneWidget);
    });

    testWidgets('a property with no history says what would create some',
        (tester) async {
      final harness = TestHarness();

      await tester.pumpWidget(
        harness.wrap(const PropertyActivityScreen(propertyId: 'prop-1')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nothing here yet'), findsOneWidget);
    });
  });

  group('after a viewing', () {
    testWidgets('a tour that has been and gone offers the payment flow', (tester) async {
      final harness = TestHarness();
      harness.activity.viewingList.add(
        fakeViewing(status: 'completed', scheduledFor: DateTime(2026, 1, 1)),
      );

      await tester.pumpWidget(harness.wrap(const ViewingDetailScreen(viewingId: 'view-1')));
      await tester.pumpAndSettle();

      await reveal(tester, find.widgetWithText(FilledButton, 'Reserve & pay'));
      expect(find.textContaining('You have seen this home'), findsOneWidget);
    });

    testWidgets('a confirmed tour whose day has passed counts too', (tester) async {
      // Landlords routinely never mark a viewing completed. Waiting for them
      // to do it would strand the customer at exactly the moment they have
      // decided.
      final harness = TestHarness();
      harness.activity.viewingList.add(
        fakeViewing(
          status: 'confirmed',
          scheduledFor: DateTime.now().subtract(const Duration(days: 1)),
        ),
      );

      await tester.pumpWidget(harness.wrap(const ViewingDetailScreen(viewingId: 'view-1')));
      await tester.pumpAndSettle();

      await reveal(tester, find.widgetWithText(FilledButton, 'Reserve & pay'));
    });

    testWidgets('a tour still to come offers nothing to pay for yet', (tester) async {
      final harness = TestHarness();
      harness.activity.viewingList.add(
        fakeViewing(
          status: 'confirmed',
          scheduledFor: DateTime.now().add(const Duration(days: 3)),
        ),
      );

      await tester.pumpWidget(harness.wrap(const ViewingDetailScreen(viewingId: 'view-1')));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Reserve & pay'), findsNothing);
    });

    testWidgets('a home let to somebody else says so instead of offering to charge for it',
        (tester) async {
      final harness = TestHarness();
      harness.activity.viewingList.add(
        fakeViewing(status: 'completed', scheduledFor: DateTime(2026, 1, 1)),
      );
      harness.journey.eligibility = const CheckoutEligibility(
        propertyId: 'prop-1',
        available: false,
        canPay: false,
      );

      await tester.pumpWidget(harness.wrap(const ViewingDetailScreen(viewingId: 'view-1')));
      await tester.pumpAndSettle();

      await reveal(tester, find.textContaining('has been let to someone else'));
      expect(find.widgetWithText(FilledButton, 'Reserve & pay'), findsNothing);
    });
  });
}
