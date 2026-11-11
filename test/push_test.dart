import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:homemate_mobile/core/providers.dart';
import 'package:homemate_mobile/features/inquiry/data/inquiry_providers.dart';
import 'package:homemate_mobile/core/push/push_controller.dart';
import 'package:homemate_mobile/core/push/push_messaging.dart';
import 'package:homemate_mobile/features/auth/data/customer.dart';
import 'package:homemate_mobile/features/roles/data/app_role.dart';
import 'package:homemate_mobile/features/shared/models.dart';
import 'package:homemate_mobile/routing/app_router.dart';

import 'support/fakes.dart';

/// Push notifications on the real router: the install registers after
/// sign-in, a push opens the screen it is about in the role it is for, and
/// signing out stops the pushes before the session goes.
void main() {
  const customer = Customer(
    id: 'cust-1',
    phoneNumber: '+255712345678',
    fullName: 'Neema Mushi',
    hasPin: true,
    onboardingComplete: true,
  );

  PushMessage push({
    String title = 'You have a reply',
    String audience = 'customer',
    String table = 'property_inquiries',
    String subject = 'inq-1',
  }) =>
      PushMessage(
        title: title,
        body: 'Yes, it is free from May.',
        data: {
          'notificationId': 'n-1',
          'kind': 'inquiry_response',
          'audience': audience,
          'subjectTable': table,
          'subjectId': subject,
        },
      );

  /// The app on its real router with push started, as HomeMateApp starts it.
  Future<(GoRouter, ProviderContainer)> launch(
    WidgetTester tester,
    TestHarness harness, {
    bool signedIn = true,
  }) async {
    tester.view.physicalSize = TestHarness.phone * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(overrides: harness.overrides);
    addTearDown(container.dispose);
    harness.auth.customer = customer;
    if (signedIn) {
      await container.read(authControllerProvider.notifier).adopt(AuthSessionStub(token: 'session-token', customer: customer));
    } else {
      await container.read(authControllerProvider.notifier).restore();
    }
    final router = container.read(routerProvider);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: testApp(router)));
    container.read(pushControllerProvider);
    await tester.pumpAndSettle();
    return (router, container);
  }

  testWidgets('after sign-in the install asks once, registers its token, and every rotated one', (tester) async {
    final harness = TestHarness();
    await launch(tester, harness);

    expect(harness.push.permissionRequests, 1);
    expect(harness.pushDevices.registered, [(token: 'fcm-token-install-1', platform: 'android')]);

    harness.push.rotateToken('fcm-token-install-2');
    await tester.pumpAndSettle();
    expect(harness.pushDevices.registered.last, (token: 'fcm-token-install-2', platform: 'android'));
  });

  testWidgets('a first registration that failed is tried again when the app comes back', (tester) async {
    final harness = TestHarness()..push.currentToken = null; // Google not reachable yet
    await launch(tester, harness);
    expect(harness.pushDevices.registered, isEmpty);

    harness.push.currentToken = 'fcm-token-after-checkin';
    for (final state in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused,
        AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();
    expect(harness.pushDevices.registered, [(token: 'fcm-token-after-checkin', platform: 'android')]);
  });

  testWidgets('permission refused: nothing is registered and nothing breaks', (tester) async {
    final harness = TestHarness()..push.grantPermission = false;
    final (router, _) = await launch(tester, harness);

    expect(harness.pushDevices.registered, isEmpty);
    expect(router.state.matchedLocation, Routes.home);
  });

  testWidgets('signing out stops the pushes while the session still works, then drops the token', (tester) async {
    final harness = TestHarness();
    final (router, container) = await launch(tester, harness);
    harness.pushDevices.sessionAliveCheck = () => container.read(authControllerProvider.notifier).token != null;

    await container.read(authControllerProvider.notifier).signOut();
    await tester.pumpAndSettle();

    expect(harness.pushDevices.unregistered, ['fcm-token-install-1']);
    expect(harness.pushDevices.sessionAliveAtUnregister, isTrue);
    expect(harness.push.tokensDeleted, 1);
    expect(router.state.matchedLocation, Routes.signIn);
  });

  testWidgets('a push while the app is open shows a banner whose Open goes to the enquiry, over the inbox', (tester) async {
    final harness = TestHarness();
    harness.activity.notificationList.add(AppNotification(
      id: 'n-1',
      title: 'You have a reply',
      kind: 'inquiry_response',
      createdAt: DateTime(2026, 10, 1),
      audience: 'customer',
    ));
    final (router, _) = await launch(tester, harness);

    harness.push.arriveWhileOpen(push());
    await tester.pumpAndSettle();
    expect(find.text('You have a reply'), findsOneWidget);
    expect(find.text('Yes, it is free from May.'), findsOneWidget);

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(router.state.matchedLocation, Routes.inquiry('inq-1'));
    expect(harness.activity.notificationList.single.isUnread, isFalse, reason: 'opening it reads it');

    router.pop();
    await tester.pumpAndSettle();
    expect(router.state.matchedLocation, '${Routes.home}/notifications', reason: 'Back lands in the inbox');
  });

  testWidgets('a push refreshes what the app cached, so the reply it announces is the reply shown', (tester) async {
    final harness = TestHarness();
    harness.activity.inquiryList.add(fakeInquiry(status: 'accepted', response: 'Yes, it is yours.'));
    final (_, container) = await launch(tester, harness);

    // The enquiry was opened earlier and is cached with the first reply.
    expect((await container.read(inquiryProvider('inq-1').future)).response, 'Yes, it is yours.');
    harness.activity.inquiryList[0] = fakeInquiry(status: 'accepted', response: 'You can pay now.');
    expect((await container.read(inquiryProvider('inq-1').future)).response, 'Yes, it is yours.', reason: 'still cached');

    harness.push.arriveWhileOpen(push());
    await tester.pumpAndSettle();
    expect((await container.read(inquiryProvider('inq-1').future)).response, 'You can pay now.');
  });

  testWidgets('a broker’s push tapped as a customer switches to the broker role and opens the partner enquiry', (tester) async {
    final harness = TestHarness(roles: FakeRoleRepository.withPartner(AppRole.broker, lastActiveRole: AppRole.customer));
    final (router, container) = await launch(tester, harness);
    if (router.state.matchedLocation == Routes.chooseRole) {
      await container.read(roleControllerProvider.notifier).chooseRole(AppRole.customer, alwaysOpen: false);
      await tester.pumpAndSettle();
    }
    expect(container.read(roleControllerProvider).current, AppRole.customer);

    harness.push.tapInTray(push(title: 'New enquiry', audience: 'broker'));
    await tester.pumpAndSettle();

    expect(container.read(roleControllerProvider).current, AppRole.broker);
    expect(harness.roles.switches, contains(AppRole.broker));
    expect(router.state.matchedLocation, Routes.partnerEnquiry(AppRole.broker, 'inq-1'));
  });

  testWidgets('a push tapped while signed out opens once the person signs in', (tester) async {
    final harness = TestHarness();
    final (router, container) = await launch(tester, harness, signedIn: false);

    harness.push.tapInTray(push(table: 'payments', subject: 'pay-1'));
    await tester.pumpAndSettle();
    expect(router.state.matchedLocation, isNot(Routes.payment('pay-1')));

    await container.read(authControllerProvider.notifier).adopt(AuthSessionStub(token: 'session-token', customer: customer));
    await tester.pumpAndSettle();
    expect(router.state.matchedLocation, Routes.payment('pay-1'));
  });

  testWidgets('the push that launched the app from closed is opened', (tester) async {
    final harness = TestHarness();
    harness.push.launchedFrom = push(table: 'bookings', subject: 'bk-1');
    final (router, _) = await launch(tester, harness);

    expect(router.state.matchedLocation, Routes.rental('bk-1'));
  });
}
