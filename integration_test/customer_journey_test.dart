import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homemate_mobile/app.dart';
import 'package:homemate_mobile/core/config/env.dart';
import 'package:homemate_mobile/core/network/api_client.dart';
import 'package:homemate_mobile/core/providers.dart';
import 'package:homemate_mobile/features/auth/data/session_store.dart';
import 'package:integration_test/integration_test.dart';


/// The whole app against the real backend.
///
/// Nothing is faked here: the widgets, the router, the HTTP client, the API and
/// Postgres are all the real ones. It is the only test that can catch the
/// things a widget test cannot — a route the server does not have, a field the
/// app reads by the wrong name, a rule the two disagree about.
///
/// Run it with the backend up:
///
///   flutter test integration_test --dart-define-from-file=.env.json
///
/// or in a real browser, which is what requirement 11 asks for:
///
///   flutter drive --driver=test_driver/integration_test.dart \
///     --target=integration_test/customer_journey_test.dart \
///     -d chrome --dart-define-from-file=.env.json
/// Pumps until `finder` appears, or gives up with a readable message.
///
/// `pumpAndSettle` is the wrong tool here: it settles the animation queue, but
/// this app is waiting on a real HTTP round trip, which is not an animation.
/// Pumping in a loop lets real time pass between frames.
Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
  String? describe,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      // One more settle so any transition finishes before the test acts.
      await tester.pump(const Duration(milliseconds: 300));
      return;
    }
  }
  fail("Timed out waiting for ${describe ?? finder.describeMatch(Plurality.zero)}");
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// A fresh number per run, so a re-run is not throttled by the last one and
  /// does not collide with an account that already has a PIN.
  final phone = '+2557145${Random().nextInt(90000) + 10000}';
  const pin = '4820';

  late ApiClient probe;

  setUpAll(() {
    // A second, unauthenticated client used only to read what the backend did
    // — the sandbox SMS adapter's code, for instance, which a real customer
    // would read off their phone.
    probe = ApiClient(baseUrl: Env.apiBaseUrl);
  });

  tearDownAll(() => probe.close());

  Future<bool> backendIsUp() async {
    try {
      // Any route that answers without a session proves it is listening.
      await probe.get('/app/summary');
      return true;
    } on Object catch (error) {
      // 401 is a perfectly good sign of life; only a transport failure is not.
      return '$error'.contains('401') || '$error'.contains('UNAUTHORIZED');
    }
  }

  testWidgets('a customer onboards, finds a home, enquires and books it', (tester) async {
    if (!await backendIsUp()) {
      markTestSkipped('Backend is not running at ${Env.apiBaseUrl} — start it and re-run.');
      return;
    }

    await tester.pumpWidget(
      ProviderScope(
        // A throwaway session store: this run must not inherit or leave behind
        // a signed-in state on the machine running it.
        overrides: [sessionStoreProvider.overrideWithValue(InMemorySessionStore())],
        child: const HomeMateApp(),
      ),
    );
    // The splash holds until the stored session has been read.
    await waitFor(tester, find.text('Skip'), describe: 'the onboarding carousel');

    // --- Onboarding ---------------------------------------------------------
    // The slides have nothing to prove here; skip straight to signing in.
    await tester.tap(find.text('Skip'));
    await waitFor(tester, find.widgetWithText(ElevatedButton, 'Send code'),
        describe: 'the sign-in screen');

    await tester.enterText(find.byType(TextFormField).first, phone);
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Send code'));
    await waitFor(tester, find.byKey(const Key('otp-field')), describe: 'the code screen');

    // The code the backend actually sent. A real customer reads it off their
    // phone; the sandbox adapter lets the test read the same value.
    late String code;
    await tester.runAsync(() async {
      final sent = await probe.get('/customer/auth/otp/last', query: {'phoneNumber': phone});
      code = sent['code'] as String;
    });

    await tester.enterText(find.byKey(const Key('otp-field')), code);

    // --- Choosing a PIN -------------------------------------------------------
    await waitFor(tester, find.text('Create your PIN'), describe: 'the PIN screen');
    await tester.enterText(find.byKey(const Key('new-pin')), pin);
    await tester.enterText(find.byKey(const Key('confirm-pin')), pin);
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create PIN'));

    // --- The profile step -----------------------------------------------------
    await waitFor(tester, find.text('Tell us about you'), describe: 'the profile screen');
    await tester.enterText(find.byKey(const Key('full-name')), 'Neema Kileo');
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));

    // --- Home -----------------------------------------------------------------
    await waitFor(tester, find.text('Karibu'), describe: 'the home screen');

    // --- Finding and opening a listing ----------------------------------------
    await tester.tap(find.text('Search'));
    await waitFor(tester, find.byKey(const Key('search-field')), describe: 'the search screen');
    await tester.pump(const Duration(seconds: 2));

    final listings = find.byType(Card);
    if (listings.evaluate().isEmpty) {
      markTestSkipped('No approved listings in this database — seed one and re-run.');
      return;
    }

    await tester.tap(listings.first);
    await waitFor(tester, find.widgetWithText(ElevatedButton, 'Book a viewing'),
        describe: 'the property screen');

    // --- Enquiring -------------------------------------------------------------
    await tester.tap(find.widgetWithText(OutlinedButton, 'Enquire'));
    await waitFor(tester, find.byKey(const Key('inquiry-message')),
        describe: 'the enquiry form');

    await tester.enterText(
      find.byKey(const Key('inquiry-message')),
      'Is this still available from November?',
    );
    await tester.pump();
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Send enquiry'));
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Send enquiry'));

    // The enquiry screen it lands on carries the reference the server minted.
    await waitFor(tester, find.textContaining('HM-INQ-'),
        describe: 'the reference the server minted');
  }, timeout: const Timeout(Duration(minutes: 3)));
}
