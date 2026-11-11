import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/auth_controller.dart';
import '../../features/inquiry/data/inquiry_providers.dart';
import '../../features/notifications/data/notification_providers.dart';
import '../../features/payment/data/payment_providers.dart';
import '../../features/shared/journey_providers.dart';
import '../../routing/app_router.dart';
import '../config/env.dart';
import '../i18n/app_text.dart';
import '../providers.dart';
import 'push_messaging.dart';

/// The app-wide messenger, so a push that arrives on any screen can say so.
final scaffoldMessengerKeyProvider = Provider<GlobalKey<ScaffoldMessengerState>>(
  (_) => GlobalKey<ScaffoldMessengerState>(),
);

/// Keeps this install's push registration in step with the session.
///
/// - Signed in: ask for permission once, then hand the FCM token to the
///   server, and every token FCM rotates to after it.
/// - A push while the app is open: refresh the inbox and badges, and show a
///   banner with an Open button — the system shows nothing in that case.
/// - A push tapped in the tray, or the one that launched the app: open it
///   (Routes.openNotification), which waits out sign-in if it has to.
/// - Signing out: tell the server first, while the session still works, then
///   drop the token, so the next person on this phone gets none of it.
final pushControllerProvider = Provider<PushController>((ref) {
  final controller = PushController(ref);
  ref.onDispose(controller.dispose);
  return controller;
});

class PushController {
  PushController(this._ref) {
    final messaging = _ref.read(pushMessagingProvider);
    if (messaging.platform == null) return;

    _subscriptions
      ..add(messaging.tokenRefreshes.listen((token) {
        if (_signedIn) _register(token);
      }))
      ..add(messaging.foregroundMessages.listen(_showBanner))
      ..add(messaging.openedMessages.listen(open));

    _ref.read(authControllerProvider.notifier).addBeforeSignOut(_forget);
    // A first attempt can fail for reasons that pass — a phone that booted a
    // moment ago and has not checked in with Google yet — so coming back to
    // the app tries again until this install is registered.
    _lifecycle = AppLifecycleListener(onResume: () {
      if (_signedIn && _registeredToken == null) {
        _registering ??= _registerThisInstall().whenComplete(() => _registering = null);
      }
    });
    _ref.listen<AuthState>(authControllerProvider, (_, next) => _onAuth(next), fireImmediately: true);
    messaging.launchMessage().then((message) {
      if (message != null) open(message);
    });
  }

  final Ref _ref;
  final _subscriptions = <StreamSubscription<Object>>[];
  AppLifecycleListener? _lifecycle;
  bool _signedIn = false;
  String? _registeredToken;
  Future<void>? _registering;

  PushMessaging get _messaging => _ref.read(pushMessagingProvider);

  void _onAuth(AuthState auth) {
    _signedIn = auth.isSignedIn;
    if (!_signedIn) {
      _registeredToken = null;
      return;
    }
    _registering ??= _registerThisInstall().whenComplete(() => _registering = null);
  }

  Future<void> _registerThisInstall() async {
    if (_registeredToken != null) return;
    if (!await _messaging.requestPermission()) return;
    final token = await _messaging.token();
    if (token != null && _signedIn) await _register(token);
  }

  Future<void> _register(String token) async {
    try {
      await _ref.read(pushDeviceRepositoryProvider).register(
            token: token,
            platform: _messaging.platform!,
            appVersion: Env.buildNumber == 0 ? null : '${Env.buildNumber}',
          );
      _registeredToken = token;
    } catch (error) {
      // The next sign-in or token refresh tries again; push is never worth
      // an error on screen.
      debugPrint('Push registration failed: $error');
    }
  }

  Future<void> _forget() async {
    final token = _registeredToken;
    _registeredToken = null;
    if (token == null) return;
    try {
      await _ref.read(pushDeviceRepositoryProvider).unregister(token);
    } catch (error) {
      debugPrint('Push unregistration failed: $error');
    }
    await _messaging.deleteToken();
  }

  /// A push means something changed on the server, so what the app already
  /// holds about it is stale — a reply opened from a banner must show the
  /// reply that just arrived, not the one cached from the last visit.
  void _refreshInbox() {
    _ref.invalidate(notificationsProvider);
    _ref.invalidate(unreadNotificationsProvider);
    _ref.invalidate(activitySummaryProvider);
    _ref.invalidate(inquiriesProvider);
    _ref.invalidate(inquiryProvider);
    _ref.invalidate(inquiryJourneyProvider);
    _ref.invalidate(propertyJourneyProvider);
    _ref.invalidate(checkoutEligibilityProvider);
    _ref.invalidate(paymentProvider);
    _ref.invalidate(rentalsProvider);
    _ref.invalidate(rentalProvider);
  }

  void _showBanner(PushMessage message) {
    _refreshInbox();
    final messenger = _ref.read(scaffoldMessengerKeyProvider).currentState;
    final context = _ref.read(scaffoldMessengerKeyProvider).currentContext;
    if (messenger == null || context == null || message.title == null) return;
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.title!, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (message.body != null) Text(message.body!, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
        action: SnackBarAction(label: context.text.notificationsOpen, onPressed: () => open(message)),
      ),
    );
  }

  /// Opens what a push is about. Public for the banner and for tests.
  void open(PushMessage message) {
    _refreshInbox();
    _ref.read(routerProvider).go(Routes.openNotificationFor(message.data));
  }

  void dispose() {
    _lifecycle?.dispose();
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
  }
}
