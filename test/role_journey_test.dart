import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:homemate_mobile/core/i18n/app_locale.dart';
import 'package:homemate_mobile/core/providers.dart';
import 'package:homemate_mobile/design/widgets/hm_bottom_nav.dart';
import 'package:homemate_mobile/features/auth/data/customer.dart';
import 'package:homemate_mobile/features/roles/data/app_role.dart';
import 'package:homemate_mobile/routing/app_router.dart';

import 'support/fakes.dart';

/// Figma AUTH-000: one account, three roles — every lane of the flow map.
void main() {
  const newAccount = Customer(id: 'cust-1', phoneNumber: '+255712345678', hasPin: true);
  const returning = Customer(
    id: 'cust-1',
    phoneNumber: '+255712345678',
    fullName: 'Baraka Mwinyi',
    hasPin: true,
    onboardingComplete: true,
  );

  /// The whole app on its real router, with [customer] signed in (or not).
  Future<GoRouter> launch(WidgetTester tester, TestHarness harness, {Customer? customer}) async {
    tester.view.physicalSize = TestHarness.phone * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(overrides: harness.overrides);
    addTearDown(container.dispose);
    if (customer != null) {
      harness.auth.customer = customer;
      await container.read(authControllerProvider.notifier).adopt(AuthSessionStub(token: 'session-token', customer: customer));
    } else {
      await container.read(authControllerProvider.notifier).restore();
    }
    final router = container.read(routerProvider);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: testApp(router)));
    await tester.pumpAndSettle();
    return router;
  }

  List<String> tabLabels(WidgetTester tester) => tester
      .widget<HmBottomNav>(find.byType(HmBottomNav))
      .tabs
      .map((tab) => tab.label)
      .toList();

  group('1 · a new account is asked how it will use HomeMate (AUTH-001)', () {
    testWidgets('Find a home → the customer profile setup', (tester) async {
      final harness = TestHarness();
      final router = await launch(tester, harness, customer: newAccount);
      expect(router.state.matchedLocation, Routes.roleUse);
      expect(find.text('How will you use HomeMate?'), findsOneWidget);
      expect(find.text('Whatever you pick, you can always search for homes too.'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, Routes.profileSetup);
      expect(await harness.rolePreferences.startedAs('cust-1'), AppRole.customer);
    });

    testWidgets('List homes I know → the broker shell, before any application exists', (tester) async {
      final harness = TestHarness();
      final router = await launch(tester, harness, customer: newAccount);
      await tester.tap(find.text('List homes I know'));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // A broker who has not started yet meets the broker intro (BRK-001).
      expect(router.state.matchedLocation, Routes.partnerIntro(AppRole.broker));
      expect(find.text('List the homes you know'), findsOneWidget);
      expect(harness.roles.switches, isEmpty, reason: 'no broker role to switch the token to yet');

      // Closing it lands on the broker shell with its own tabs.
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, Routes.brokerHome);
      expect(tabLabels(tester), ['Home', 'Listings', 'Enquiries', 'Earnings', 'Profile']);
      expect(find.text('Finish setting up your Broker account to start.'), findsOneWidget);
    });

    testWidgets('Let my own home → the landlord shell', (tester) async {
      final harness = TestHarness();
      final router = await launch(tester, harness, customer: newAccount);
      await tester.tap(find.text('Let my own home'));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, Routes.landlordHome);
      expect(tabLabels(tester), ['Home', 'Homes', 'Tenants', 'Money', 'Profile']);
    });

    testWidgets('…and is asked only once', (tester) async {
      final harness = TestHarness();
      await harness.rolePreferences.setStartedAs('cust-1', AppRole.landlord);
      final router = await launch(tester, harness, customer: newAccount);
      expect(router.state.matchedLocation, Routes.landlordHome);
    });
  });

  group('2 · coming back', () {
    testWidgets('only the customer role: straight to the customer home, as before', (tester) async {
      final router = await launch(tester, TestHarness(), customer: returning);
      expect(router.state.matchedLocation, Routes.home);
    });

    testWidgets('a partner with a single role lands on their home', (tester) async {
      final harness = TestHarness(roles: FakeRoleRepository.withPartner(AppRole.broker));
      final router = await launch(tester, harness, customer: newAccount);
      expect(router.state.matchedLocation, Routes.brokerHome);
      expect(harness.roles.switches, [AppRole.broker], reason: 'the token must act as broker for the partner routes');
    });

    testWidgets('several roles: ROL-001, and the pick opens that shell', (tester) async {
      final harness = TestHarness(roles: FakeRoleRepository.withPartner(AppRole.landlord));
      final router = await launch(tester, harness, customer: returning);
      expect(router.state.matchedLocation, Routes.chooseRole);
      expect(find.text('Welcome back, Baraka'), findsOneWidget);

      await tester.tap(find.text('Landlord'));
      await tester.pump();
      expect(find.text('Always open as Landlord on this phone'), findsOneWidget);
      await tester.tap(find.text('Continue as Landlord'));
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, Routes.landlordHome);
      expect(harness.roles.switches, [AppRole.landlord]);
    });

    testWidgets('a partner role under review is marked on ROL-001', (tester) async {
      final harness = TestHarness(roles: FakeRoleRepository.withPartner(AppRole.broker, status: 'pending_review'));
      await launch(tester, harness, customer: returning);
      expect(find.text('Under review'), findsOneWidget);
    });

    testWidgets('"Always open as" skips ROL-001 next time', (tester) async {
      final harness = TestHarness(roles: FakeRoleRepository.withPartner(AppRole.broker));
      final router = await launch(tester, harness, customer: returning);
      await tester.tap(find.text('Broker'));
      await tester.pump();
      await tester.tap(find.text('Always open as Broker on this phone'));
      await tester.pump();
      await tester.tap(find.text('Continue as Broker'));
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, Routes.brokerHome);

      // Same phone, a new launch.
      final again = await launch(tester, harness, customer: returning);
      expect(again.state.matchedLocation, Routes.brokerHome);
      // Unmount inside the test so Riverpod's disposal tick runs here.
      await tester.pumpWidget(const SizedBox());
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    });
  });

  group('3 · while signed in', () {
    testWidgets('the role chip opens ROL-002 and switches shell without a PIN', (tester) async {
      final harness = TestHarness(roles: FakeRoleRepository.withPartner(AppRole.broker));
      await harness.rolePreferences.setAlwaysOpenAs('cust-1', AppRole.broker);
      final router = await launch(tester, harness, customer: returning);
      expect(router.state.matchedLocation, Routes.brokerHome);

      await tester.tap(find.text('Broker'));
      await tester.pumpAndSettle();
      expect(find.text('Switch role'), findsOneWidget);
      expect(find.text('Signed in as +255712345678. Same account, same PIN.'), findsOneWidget);
      expect(find.text('You are here'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('switch-to-customer')));
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, Routes.home);
      expect(harness.roles.switches, [AppRole.broker, AppRole.customer]);
      expect(harness.auth.failedLogins, 0);
    });

    testWidgets('a customer adds a role: Profile → Earn with HomeMate (ROL-003) → ROL-004 → that setup', (tester) async {
      final harness = TestHarness();
      final router = await launch(tester, harness, customer: returning);
      router.go(Routes.profile);
      await tester.pumpAndSettle();

      expect(find.text('Work with HomeMate'), findsOneWidget);
      await tester.tap(find.text('Earn with HomeMate'));
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, Routes.earn);
      expect(find.text('Keep 90% of the tenant fee on every home you let'), findsOneWidget);

      await tester.tap(find.text('Landlord'));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, Routes.landlordHome);
    });

    testWidgets('a role already on the account cannot be added again', (tester) async {
      final harness = TestHarness(roles: FakeRoleRepository.withPartner(AppRole.broker, status: 'pending_review'));
      final router = await launch(tester, harness, customer: returning);
      await tester.tap(find.text('Continue as Customer'));
      await tester.pumpAndSettle();
      router.go(Routes.earn);
      await tester.pumpAndSettle();
      expect(find.text('Already on your account'), findsOneWidget);
    });

    testWidgets('signing out from a partner profile signs out of every role', (tester) async {
      final harness = TestHarness(roles: FakeRoleRepository.withPartner(AppRole.landlord));
      await harness.rolePreferences.setAlwaysOpenAs('cust-1', AppRole.landlord);
      final router = await launch(tester, harness, customer: returning);
      router.go(Routes.landlordProfile);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, Routes.signIn);
    });
  });

  group('in Kiswahili', () {
    testWidgets('AUTH-001, ROL-001 and ROL-004 lay out without overflow', (tester) async {
      final harness = TestHarness(locale: AppLocale.swahili);
      final router = await launch(tester, harness, customer: newAccount);
      expect(find.text('Utatumiaje HomeMate?'), findsOneWidget);

      harness.roles.roles = FakeRoleRepository.withPartner(AppRole.broker, status: 'action_needed').roles;
      final back = await launch(tester, harness, customer: returning);
      expect(back.state.matchedLocation, Routes.chooseRole);
      expect(find.text('Karibu tena, Baraka'), findsOneWidget);
      expect(find.text('Hatua inahitajika'), findsOneWidget);

      await tester.tap(find.text('Endelea kama Mteja'));
      await tester.pumpAndSettle();
      back.go(Routes.earn);
      await tester.pumpAndSettle();
      expect(find.text('Pata kipato na HomeMate'), findsOneWidget);
      expect(router, isNotNull);
      expect(tester.takeException(), isNull);
    });
  });

  group('4 · from an SMS link', () {
    testWidgets('signed out → sign in → the landlord confirmation', (tester) async {
      final harness = TestHarness();
      final router = await launch(tester, harness);
      router.go('/landlord/confirm/prop-9');
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, isNot(startsWith('/landlord')));

      final container = ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
      await container.read(authControllerProvider.notifier).adopt(AuthSessionStub(token: 'session-token', customer: returning));
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, '/landlord/confirm/prop-9');
      expect(find.text('Confirm your home'), findsOneWidget);
    });

    testWidgets('the platform-stripped form lands in the same place when signed in', (tester) async {
      final router = await launch(tester, TestHarness(), customer: returning);
      router.go('/confirm/prop-7');
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, '/landlord/confirm/prop-7');
    });
  });
}
