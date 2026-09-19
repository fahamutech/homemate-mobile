import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homemate_mobile/core/location/location_providers.dart';
import 'package:homemate_mobile/core/location/location_service.dart';
import 'package:homemate_mobile/features/discovery/presentation/home_screen.dart';
import 'package:homemate_mobile/features/discovery/presentation/near_me_prompt.dart';

import 'support/fakes.dart';

/// "Near me", and the four ways it can be refused.
///
/// These exist because a location feature is mostly its failure states: the
/// happy path is one line of code, and the rest is what happens to someone who
/// said no in 2024, or who has location switched off entirely. Each of those
/// has to lead somewhere, and a card that does nothing when tapped is the bug
/// this file is here to catch.
///
/// The prompt is driven directly rather than through the home screen for most
/// of these: it lives well below the fold on a 390pt phone, and a test that
/// has to scroll before it can assert is a test that fails for the wrong
/// reason. The one thing that genuinely needs the whole screen — that the
/// position actually reaches the search — is exercised through it.
void main() {
  /// The prompt and the source line together, which is how the home screen
  /// arranges them: exactly one of the two is ever visible.
  Widget nearMeSection() => Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NearMePrompt(onChooseArea: () {}),
                NearMeSource(onChooseArea: () {}),
              ],
            ),
          ),
        ),
      );

  group('the soft ask', () {
    testWidgets('never prompts the operating system on its own', (tester) async {
      // On iOS the system prompt can be spent exactly once. Firing it because
      // a screen appeared is how an app ends up permanently unable to ask.
      final harness = TestHarness();

      await tester.pumpWidget(harness.wrap(nearMeSection()));
      await tester.pumpAndSettle();

      expect(
        harness.location.requestCount,
        0,
        reason: 'the OS prompt may only ever follow an explicit tap',
      );
      expect(find.text('See homes near you'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Use my location'), findsOneWidget);
    });

    testWidgets('asks when the button is pressed, and then steps aside', (tester) async {
      final harness = TestHarness();

      await tester.pumpWidget(harness.wrap(nearMeSection()));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Use my location'));
      await tester.pumpAndSettle();

      expect(harness.location.requestCount, 1);
      expect(find.text('Sorted by distance from you'), findsOneWidget);
      expect(find.text('See homes near you'), findsNothing);
    });

    testWidgets('a refusal keeps the other way in', (tester) async {
      final harness = TestHarness(
        location: FakeLocationService(grantOnRequest: false),
      );

      await tester.pumpWidget(harness.wrap(nearMeSection()));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Use my location'));
      await tester.pumpAndSettle();

      expect(harness.location.requestCount, 1);
      expect(find.widgetWithText(OutlinedButton, 'Choose an area'), findsOneWidget);
    });
  });

  group('a refusal that cannot be undone from here', () {
    testWidgets('sends the customer to Settings rather than asking again', (tester) async {
      final harness = TestHarness(
        location: FakeLocationService(state: LocationAvailability.deniedForever),
      );

      await tester.pumpWidget(harness.wrap(nearMeSection()));
      await tester.pumpAndSettle();

      expect(find.text('Location is blocked for HomeMate'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Open settings'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Open settings'));
      await tester.pumpAndSettle();

      expect(harness.location.settingsOpenedCount, 1);
      expect(
        harness.location.requestCount,
        0,
        reason: 'asking again when the OS will not ask is a button that does nothing',
      );
    });

    testWidgets('offers a way to re-check after coming back from Settings', (tester) async {
      // Returning from Settings rebuilds nothing by itself. Without this, a
      // customer grants permission and the app carries on insisting it is
      // blocked.
      final harness = TestHarness(
        location: FakeLocationService(state: LocationAvailability.deniedForever),
      );

      await tester.pumpWidget(harness.wrap(nearMeSection()));
      await tester.pumpAndSettle();

      final recheck = find.widgetWithText(TextButton, 'I have allowed it — check again');
      expect(recheck, findsOneWidget);

      harness.location.state = LocationAvailability.granted;
      await tester.tap(recheck);
      await tester.pumpAndSettle();

      expect(find.text('Sorted by distance from you'), findsOneWidget);
    });
  });

  group('location switched off device-wide', () {
    testWidgets('says so, and points at the right settings page', (tester) async {
      // A permission grant produces no position at all when the service is
      // off, so "Allow location" here would be a lie.
      final harness = TestHarness(
        location: FakeLocationService(state: LocationAvailability.serviceDisabled),
      );

      await tester.pumpWidget(harness.wrap(nearMeSection()));
      await tester.pumpAndSettle();

      expect(find.text('Location is switched off'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Open location settings'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Open location settings'));
      await tester.pumpAndSettle();

      expect(harness.location.settingsOpenedCount, 1);
    });
  });

  group('already granted', () {
    testWidgets('uses the position without asking again', (tester) async {
      final harness = TestHarness(
        location: FakeLocationService(state: LocationAvailability.granted),
      );

      await tester.pumpWidget(harness.wrap(nearMeSection()));
      await tester.pumpAndSettle();

      expect(find.text('Sorted by distance from you'), findsOneWidget);
      expect(harness.location.requestCount, 0);
    });
  });

  group('choosing an area by hand', () {
    testWidgets('is a full substitute for the permission', (tester) async {
      final harness = TestHarness(
        location: FakeLocationService(state: LocationAvailability.deniedForever),
      );

      await tester.pumpWidget(harness.wrap(nearMeSection()));
      await tester.pumpAndSettle();
      expect(find.text('Location is blocked for HomeMate'), findsOneWidget);

      harness.container!.read(nearMeProvider.notifier).useManualArea(
            placeName: 'Mikocheni',
            latitude: -6.7724,
            longitude: 39.2483,
          );
      await tester.pumpAndSettle();

      expect(find.text('Near Mikocheni'), findsOneWidget);
      expect(
        find.text('Location is blocked for HomeMate'),
        findsNothing,
        reason: 'once an area is chosen there is nothing left to ask for',
      );
    });
  });

  group('the home screen', () {
    testWidgets('passes the position into the search, so Near You really is near',
        (tester) async {
      // The server orders by distance the moment it is given a point, so this
      // is the whole feature: if the filters do not carry it, "Near You" is
      // just the newest listings under a misleading heading.
      final harness = TestHarness(
        location: FakeLocationService(state: LocationAvailability.granted),
      );

      await tester.pumpWidget(harness.wrap(const HomeScreen()));
      await tester.pumpAndSettle();

      final filters = harness.catalogue.searches.last;
      expect(filters.latitude, harness.location.latitude);
      expect(filters.longitude, harness.location.longitude);
      expect(filters.radiusMetres, isNotNull);
    });

    testWidgets('sends no position at all when we do not have one', (tester) async {
      // Sending a default city centre as though it were the customer would be
      // worse than sending nothing: it would silently rank listings by
      // distance from a place they have never been.
      final harness = TestHarness();

      await tester.pumpWidget(harness.wrap(const HomeScreen()));
      await tester.pumpAndSettle();

      final filters = harness.catalogue.searches.last;
      expect(filters.latitude, isNull);
      expect(filters.radiusMetres, isNull);
    });

    testWidgets('shows how far away each home is once it knows', (tester) async {
      final harness = TestHarness(
        catalogue: FakeCatalogueRepository(
          properties: [fakeProperty(distanceMetres: 2400)],
        ),
        location: FakeLocationService(state: LocationAvailability.granted),
      );

      await tester.pumpWidget(harness.wrap(const HomeScreen()));
      await tester.pumpAndSettle();

      await reveal(tester, find.text('2.4 km away'));
    });
  });

  group('the distance label', () {
    test('reads in metres up close and kilometres further out', () {
      expect(DistanceLabel.format(120), '100 m away');
      expect(DistanceLabel.format(940), '900 m away');
      expect(DistanceLabel.format(1500), '1.5 km away');
      expect(DistanceLabel.format(24000), '24 km away');
    });

    test('rounds to 100m rather than implying a precision the fix does not have', () {
      expect(DistanceLabel.format(237), '200 m away');
      expect(DistanceLabel.format(289), '300 m away');
    });
  });
}
