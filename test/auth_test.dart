import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homemate_mobile/core/network/api_exception.dart';
import 'package:homemate_mobile/core/providers.dart';
import 'package:homemate_mobile/features/auth/data/auth_controller.dart';
import 'package:homemate_mobile/features/auth/data/customer.dart';
import 'package:homemate_mobile/features/roles/data/app_role.dart';
import 'package:homemate_mobile/features/auth/data/session_store.dart';
import 'package:homemate_mobile/features/auth/presentation/otp_screen.dart';
import 'package:homemate_mobile/features/auth/presentation/phone_field.dart';
import 'package:homemate_mobile/features/auth/presentation/pin_setup_screen.dart';
import 'package:homemate_mobile/features/auth/presentation/profile_setup_screen.dart';
import 'package:homemate_mobile/features/auth/presentation/sign_in_screen.dart';
import 'package:homemate_mobile/routing/app_router.dart';
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
    testWidgets('an enrolled device signs in on the keypad and no SMS is sent', (tester) async {
      final harness = TestHarness();
      harness.auth.pins['+255712345678'] = '4820';
      await harness.store.rememberPinEnrolment('+255712345678');

      await tester.pumpWidget(harness.wrap(const SignInScreen()));
      await tester.pumpAndSettle();

      // An enrolled device opens straight on the keypad.
      expect(find.text('Welcome back'), findsOneWidget);
      await tapPin(tester, '4820');

      expect(harness.auth.sentTo, isEmpty, reason: 'signing in must not cost an SMS');
    });

    testWidgets('a number remembered from an abandoned code still asks for a code',
        (tester) async {
      // The number is written the moment a code is requested. Treating that as
      // "this device has a PIN" left anyone who never finished the SMS staring
      // at a keypad for a PIN that was never created.
      final harness = TestHarness();
      await harness.store.rememberPhoneNumber('+255712345678');

      await tester.pumpWidget(harness.wrap(const SignInScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Welcome back'), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'Send code'), findsOneWidget);
    });

    testWidgets('a wrong PIN shows the message and stays put', (tester) async {
      final harness = TestHarness();
      harness.auth.pins['+255712345678'] = '4820';
      await harness.store.rememberPinEnrolment('+255712345678');

      await tester.pumpWidget(harness.wrap(const SignInScreen()));
      await tester.pumpAndSettle();

      await tapPin(tester, '9999');

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

    testWidgets('a finished profile can still open the edit screen', (tester) async {
      // "Edit your details" used to point at /complete-profile — the path the
      // redirect uses to *hold* anyone whose profile is outstanding, and which
      // it sends everyone else away from. Tapping it landed on the home
      // screen. The edit screen is its own route for exactly that reason.
      final harness = TestHarness();
      final container = ProviderContainer(overrides: harness.overrides);
      addTearDown(container.dispose);

      await container.read(authControllerProvider.notifier).adopt(
            AuthSessionStub(token: 'session-token', customer: harness.auth.customer),
          );
      expect(container.read(authControllerProvider).stage, AuthStage.ready);

      final router = container.read(routerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: testApp(router),
        ),
      );
      await tester.pumpAndSettle();

      router.go(Routes.profileEdit);
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, Routes.profileEdit);
      expect(find.text('Edit your details'), findsOneWidget);
    });

    testWidgets('an enrolled device signing out lands on the keypad, not onboarding',
        (tester) async {
      final harness = TestHarness();
      final container = ProviderContainer(overrides: harness.overrides);
      addTearDown(container.dispose);

      await container.read(authControllerProvider.notifier).adopt(
            AuthSessionStub(token: 'session-token', customer: harness.auth.customer),
          );

      final router = container.read(routerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: testApp(router),
        ),
      );
      await tester.pumpAndSettle();

      await container.read(authControllerProvider.notifier).signOut();
      await tester.pumpAndSettle();

      // Signing out is not forgetting the device: the PIN still works, so the
      // intro slides have nothing left to tell them.
      expect(router.state.matchedLocation, Routes.signIn);
      expect(find.text('Welcome back'), findsOneWidget);
    });

    testWidgets('a device with no PIN still gets the intro first', (tester) async {
      final harness = TestHarness();
      final container = ProviderContainer(overrides: harness.overrides);
      addTearDown(container.dispose);

      await container.read(authControllerProvider.notifier).restore();

      final router = container.read(routerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: testApp(router),
        ),
      );
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, Routes.onboarding);
    });

    testWidgets('a signed-in customer does not get stranded on the splash', (tester) async {
      // The splash is correct only while the stored session is being read. It
      // is not a public route, so the "you are signed in, move along" branch
      // has to name it — otherwise restoring finishes and nothing moves.
      final harness = TestHarness();
      final container = ProviderContainer(overrides: harness.overrides);
      addTearDown(container.dispose);

      await container.read(sessionStoreProvider).write(
            StoredSession(token: 'session-token', userJson: harness.auth.customer.toJson()),
          );

      final router = container.read(routerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: testApp(router),
        ),
      );
      // Launch reads the stored session, exactly as HomeMateApp does.
      await container.read(authControllerProvider.notifier).restore();
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, Routes.home);
    });

    testWidgets('an unfinished profile is still held at the wizard', (tester) async {
      final harness = TestHarness();
      harness.auth.customer = const Customer(
        id: 'cust-1',
        phoneNumber: '+255712345678',
        hasPin: true,
      );
      // They already said "Find a home" on AUTH-001 (partner roles T07).
      await harness.rolePreferences.setStartedAs('cust-1', AppRole.customer);
      final container = ProviderContainer(overrides: harness.overrides);
      addTearDown(container.dispose);

      await container.read(authControllerProvider.notifier).adopt(
            AuthSessionStub(token: 'session-token', customer: harness.auth.customer),
          );

      final router = container.read(routerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: testApp(router),
        ),
      );
      await tester.pumpAndSettle();

      router.go(Routes.home);
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, Routes.profileSetup);
      expect(find.text('Complete Your Profile'), findsOneWidget);
    });
  });
}

/// A session literal, so tests do not have to walk the whole OTP flow just to
/// get one.
/// Taps a PIN into the on-device keypad, one digit at a time — which is what a
/// customer does, and the only way to exercise the auto-submit on the fourth.
Future<void> tapPin(WidgetTester tester, String pin) async {
  for (final digit in pin.split('')) {
    await tester.tap(find.widgetWithText(TextButton, digit));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}
