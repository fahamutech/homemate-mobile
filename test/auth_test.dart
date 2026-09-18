import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homemate_mobile/core/network/api_exception.dart';
import 'package:homemate_mobile/core/providers.dart';
import 'package:homemate_mobile/features/auth/data/auth_controller.dart';
import 'package:homemate_mobile/features/auth/data/auth_repository.dart';
import 'package:homemate_mobile/features/auth/data/customer.dart';
import 'package:homemate_mobile/features/auth/presentation/otp_screen.dart';
import 'package:homemate_mobile/features/auth/presentation/phone_field.dart';
import 'package:homemate_mobile/features/auth/presentation/pin_setup_screen.dart';
import 'package:homemate_mobile/features/auth/presentation/profile_setup_screen.dart';
import 'package:homemate_mobile/features/auth/presentation/sign_in_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'support/fakes.dart';

void main() {
  group('phone numbers', () {
    test('accepts every way a Tanzanian writes their number', () {
      // Somebody typing their own number should never be told it is wrong.
      expect(PhoneField.normalise('0712345678'), '+255712345678');
      expect(PhoneField.normalise('712345678'), '+255712345678');
      expect(PhoneField.normalise('255712345678'), '+255712345678');
      expect(PhoneField.normalise('+255712345678'), '+255712345678');
      expect(PhoneField.normalise('0712 345 678'), '+255712345678');
      expect(PhoneField.normalise('+255 712 345 678'), '+255712345678');
    });

    test('rejects what is genuinely not one', () {
      expect(PhoneField.normalise('12345'), isNull);
      expect(PhoneField.normalise('+254712345678'), isNull, reason: 'Kenyan, not Tanzanian');
      expect(PhoneField.normalise(''), isNull);
      expect(PhoneField.normalise('not a number'), isNull);
    });
  });

  group('signing in', () {
    testWidgets('a returning customer signs in with a PIN and no SMS is sent', (tester) async {
      final harness = TestHarness();
      harness.auth.pins['+255712345678'] = '4820';
      await harness.store.rememberPhoneNumber('+255712345678');

      await tester.pumpWidget(harness.wrap(const SignInScreen()));
      await tester.pumpAndSettle();

      // The remembered number puts them straight on the PIN path.
      expect(find.text('Welcome back'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('pin-field')), '4820');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
      await tester.pumpAndSettle();

      expect(harness.auth.sentTo, isEmpty, reason: 'signing in must not cost an SMS');
    });

    testWidgets('a wrong PIN shows the message and stays put', (tester) async {
      final harness = TestHarness();
      harness.auth.pins['+255712345678'] = '4820';
      await harness.store.rememberPhoneNumber('+255712345678');

      await tester.pumpWidget(harness.wrap(const SignInScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('pin-field')), '9999');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('That phone number and PIN do not match'), findsOneWidget);
    });

    testWidgets('a new number is sent a code instead', (tester) async {
      final harness = TestHarness();

      await tester.pumpWidget(harness.wrap(const SignInScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Sign in'), findsWidgets);
      await tester.enterText(find.byType(TextFormField).first, '0712345678');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Send code'));
      await tester.pumpAndSettle();

      expect(harness.auth.sentTo, ['+255712345678'], reason: 'the number must be normalised');
    });

    testWidgets('a throttled request shows the wait rather than failing silently', (tester) async {
      final harness = TestHarness();
      harness.auth.nextFailure = ApiException(
        code: 'RATE_LIMITED',
        message: 'Please wait before asking for another code',
        statusCode: 429,
        retryAfterSeconds: 42,
      );

      await tester.pumpWidget(harness.wrap(const SignInScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, '0712345678');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Send code'));
      await tester.pumpAndSettle();

      expect(find.text('Please wait before asking for another code'), findsOneWidget);
    });
  });

  group('verifying a code', () {
    testWidgets('a wrong code says how many tries are left', (tester) async {
      final harness = TestHarness();

      await tester.pumpWidget(harness.wrap(
        const OtpScreen(phoneNumber: '+255712345678', challengeId: 'challenge-1'),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('otp-field')), '000000');
      await tester.pumpAndSettle();

      expect(find.text('That code is not right — 4 tries left'), findsOneWidget);
    });

    testWidgets('resend is held behind a countdown, so credit cannot be burned', (tester) async {
      final harness = TestHarness();

      await tester.pumpWidget(harness.wrap(
        const OtpScreen(phoneNumber: '+255712345678', challengeId: 'challenge-1'),
      ));
      await tester.pumpAndSettle();

      // Counting down, not a tappable button.
      expect(find.textContaining('Resend in'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Send another code'), findsNothing);

      await tester.pump(const Duration(seconds: 61));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextButton, 'Send another code'), findsOneWidget);
    });
  });

  group('choosing a PIN', () {
    Future<void> enterPins(WidgetTester tester, String pin, String confirm) async {
      await tester.enterText(find.byKey(const Key('new-pin')), pin);
      await tester.enterText(find.byKey(const Key('confirm-pin')), confirm);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create PIN'));
      await tester.pumpAndSettle();
    }

    testWidgets('refuses the PINs everybody tries first', (tester) async {
      final harness = TestHarness();
      await tester.pumpWidget(harness.wrap(
        const PinSetupScreen(verificationToken: 'verify-token'),
      ));
      await tester.pumpAndSettle();

      for (final weak in ['1234', '0000', '1111']) {
        await enterPins(tester, weak, weak);
        expect(
          find.text('Please choose a less predictable PIN'),
          findsOneWidget,
          reason: '$weak should be refused',
        );
      }
      expect(harness.auth.pins, isEmpty);
    });

    testWidgets('refuses a mismatched confirmation', (tester) async {
      final harness = TestHarness();
      await tester.pumpWidget(harness.wrap(
        const PinSetupScreen(verificationToken: 'verify-token'),
      ));
      await tester.pumpAndSettle();

      await enterPins(tester, '4820', '4821');

      expect(find.text('The two PINs do not match'), findsOneWidget);
      expect(harness.auth.pins, isEmpty);
    });

    testWidgets('accepts a good PIN and records it', (tester) async {
      final harness = TestHarness();
      await tester.pumpWidget(harness.wrap(
        const PinSetupScreen(verificationToken: 'verify-token'),
      ));
      await tester.pumpAndSettle();

      await enterPins(tester, '4820', '4820');

      expect(harness.auth.pins['+255712345678'], '4820');
    });

    testWidgets('a reset says so, and saves rather than creates', (tester) async {
      final harness = TestHarness();
      await tester.pumpWidget(harness.wrap(
        const PinSetupScreen(verificationToken: 'verify-token', isReset: true),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Choose a new PIN'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Save new PIN'), findsOneWidget);
    });
  });

  group('completing the profile', () {
    testWidgets('needs a name, because the landlord sees it', (tester) async {
      final harness = TestHarness();
      harness.auth.customer = const Customer(
        id: 'cust-1',
        phoneNumber: '+255712345678',
        hasPin: true,
      );

      await tester.pumpWidget(harness.wrap(const ProfileSetupScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('full-name')), '   ');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your name'), findsOneWidget);
    });

    testWidgets('rejects a malformed email but allows none at all', (tester) async {
      final harness = TestHarness();
      await tester.pumpWidget(harness.wrap(const ProfileSetupScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('full-name')), 'Neema Kileo');
      await tester.enterText(find.byKey(const Key('email')), 'not-an-email');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();
      expect(find.text('That does not look like an email address'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('email')), '');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();
      expect(find.text('That does not look like an email address'), findsNothing);
    });
  });

  group('the session', () {
    test('restores from storage and confirms it against the server', () async {
      final harness = TestHarness();
      final container = ProviderContainer(overrides: harness.overrides);
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      await controller.adopt(
        AuthSessionStub(token: 'session-token', customer: harness.auth.customer),
      );

      final fresh = ProviderContainer(overrides: harness.overrides);
      addTearDown(fresh.dispose);
      await fresh.read(authControllerProvider.notifier).restore();

      expect(fresh.read(authControllerProvider).stage, AuthStage.ready);
    });

    test('a rejected token lands on sign-in rather than a broken app', () async {
      final harness = TestHarness();
      final container = ProviderContainer(overrides: harness.overrides);
      addTearDown(container.dispose);

      await container.read(authControllerProvider.notifier).adopt(
            AuthSessionStub(token: 'session-token', customer: harness.auth.customer),
          );

      // The server now refuses the stored token.
      harness.auth.nextFailure = ApiException(
        code: 'UNAUTHORIZED',
        message: 'Invalid or expired session token',
        statusCode: 401,
      );

      final fresh = ProviderContainer(overrides: harness.overrides);
      addTearDown(fresh.dispose);
      await fresh.read(authControllerProvider.notifier).restore();

      final state = fresh.read(authControllerProvider);
      expect(state.stage, AuthStage.signedOut);
      // The number survives, so they are not asked to type it again.
      expect(state.lastPhoneNumber, '+255712345678');
    });

    test('an unfinished profile holds the customer at the profile step', () async {
      final harness = TestHarness();
      harness.auth.customer = const Customer(
        id: 'cust-1',
        phoneNumber: '+255712345678',
        hasPin: true,
      );
      final container = ProviderContainer(overrides: harness.overrides);
      addTearDown(container.dispose);

      await container.read(authControllerProvider.notifier).restore();
      // No stored session, so they are signed out — then sign in.
      await container.read(authControllerProvider.notifier).adopt(
            AuthSessionStub(token: 'session-token', customer: harness.auth.customer),
          );

      expect(container.read(authControllerProvider).stage, AuthStage.needsProfile);
    });
  });
}

/// A session literal, so tests do not have to walk the whole OTP flow just to
/// get one.
class AuthSessionStub extends AuthSession {
  AuthSessionStub({required super.token, required super.customer});
}
