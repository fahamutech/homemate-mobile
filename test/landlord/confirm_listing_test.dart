import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:homemate_mobile/core/providers.dart';
import 'package:homemate_mobile/features/landlord/data/listing_confirmation.dart';
import 'package:homemate_mobile/features/landlord/presentation/confirm/confirm_listing_screen.dart';
import 'package:homemate_mobile/features/roles/data/app_role.dart';

import '../support/fakes.dart';

/// LND-003: from the SMS link, the landlord says the home is theirs — or
/// that something is wrong — and, if they are not a landlord yet, carries on
/// into the landlord setup.
void main() {
  const listing = ListingConfirmation(
    propertyId: 'p1',
    title: 'Masaki Heights Residence',
    addressLine: 'Plot 12, Haile Selassie Rd',
    regionName: 'Dar es Salaam',
    brokerName: 'Juma Broker',
    price: 1200000,
    depositMonths: 2,
    minLeaseMonths: 6,
  );

  Future<TestHarness> open(WidgetTester tester, {FakeRoleRepository? roles, bool waiting = true}) async {
    tester.view.physicalSize = TestHarness.phone * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final harness = TestHarness(roles: roles ?? FakeRoleRepository.withPartner(AppRole.landlord));
    if (waiting) harness.confirmations.waiting['p1'] = listing;
    await tester.pumpWidget(harness.wrap(const ConfirmListingScreen(propertyId: 'p1'), extraRoutes: [
      GoRoute(path: '/landlord', builder: (_, __) => const Scaffold(body: Text('LANDLORD HOME'))),
      GoRoute(path: '/landlord/setup', builder: (_, __) => const Scaffold(body: Text('LANDLORD SETUP'))),
    ]));
    await tester.pumpAndSettle();
    return harness;
  }

  Future<void> tapText(WidgetTester tester, String label) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    final finder = find.text(label).last;
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('shows who listed what, on which terms', (tester) async {
    await open(tester);
    expect(find.text('Masaki Heights Residence'), findsOneWidget);
    expect(find.text('Juma Broker listed this home in your name'), findsOneWidget);
    expect(find.text('TZS 1,200,000'), findsOneWidget);
    expect(find.text('2 months'), findsOneWidget);
    expect(find.text('6 months'), findsOneWidget);
    expect(find.textContaining('Rent and deposit come to you in full'), findsOneWidget);
  });

  testWidgets('an active landlord confirms and goes to their homes', (tester) async {
    final harness = await open(tester);
    await tapText(tester, 'Yes, this is my home');
    expect(harness.confirmations.confirmed, ['p1']);
    expect(find.text('Confirmed. The broker can now send it for review.'), findsOneWidget);
    await tapText(tester, 'Go to my homes');
    expect(find.text('LANDLORD HOME'), findsOneWidget);
    expect(harness.container!.read(roleControllerProvider).current, AppRole.landlord);
  });

  testWidgets('someone who is not a landlord yet confirms, then carries on into the setup', (tester) async {
    final harness = await open(tester, roles: FakeRoleRepository());
    await tapText(tester, 'Yes, this is my home');
    expect(harness.confirmations.confirmed, ['p1']);
    expect(find.text('Finish your landlord account to see enquiries, tenants and rent for this home.'), findsOneWidget);
    await tapText(tester, 'Set up your landlord account');
    expect(find.text('LANDLORD SETUP'), findsOneWidget);
  });

  testWidgets('an invited landlord is not a landlord yet either', (tester) async {
    await open(tester, roles: FakeRoleRepository.withPartner(AppRole.landlord, status: 'invited'));
    await tapText(tester, 'Yes, this is my home');
    expect(find.text('Set up your landlord account'), findsOneWidget);
  });

  testWidgets('a dispute needs a reason; a quick reason fills it', (tester) async {
    final harness = await open(tester);
    await tapText(tester, 'Something is wrong');
    expect(find.text('What is wrong?'), findsOneWidget);
    await tapText(tester, 'Send');
    expect(find.text('Say what is wrong.'), findsOneWidget);
    expect(harness.confirmations.disputed, isEmpty);

    await tapText(tester, 'The rent is wrong');
    await tapText(tester, 'Send');
    expect(harness.confirmations.disputed.single, ('p1', 'The rent is wrong'));
    expect(find.text('Thanks. We told the broker and the HomeMate team.'), findsOneWidget);
    expect(harness.confirmations.confirmed, isEmpty);
  });

  testWidgets('a dismissed dispute sheet changes nothing', (tester) async {
    final harness = await open(tester);
    await tapText(tester, 'Something is wrong');
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(harness.confirmations.disputed, isEmpty);
    expect(find.text('Yes, this is my home'), findsOneWidget);
  });

  testWidgets('a link already answered says so', (tester) async {
    await open(tester, waiting: false);
    expect(find.text('Nothing is waiting for you here. You may have answered already.'), findsOneWidget);
    expect(find.text('Yes, this is my home'), findsNothing);
  });
}
