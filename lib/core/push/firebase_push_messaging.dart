import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import '../config/env.dart';
import 'push_messaging.dart';

/// [PushMessaging] on Firebase Cloud Messaging.
///
/// Firebase starts on first use rather than in `main`: on the web it downloads
/// the Firebase SDK, and the first frame must not wait for that. A Firebase
/// that cannot start (no network on the web, a platform `flutterfire
/// configure` has not covered) leaves push off, never the app.
class FirebasePushMessaging implements PushMessaging {
  Future<FirebaseMessaging?>? _ready;

  Future<FirebaseMessaging?> _messaging() => _ready ??= _start();

  Future<FirebaseMessaging?> _start() async {
    if (platform == null) return null;
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
          .timeout(const Duration(seconds: 20));
      return FirebaseMessaging.instance;
    } catch (error) {
      debugPrint('Push notifications are unavailable: $error');
      return null;
    }
  }

  @override
  String? get platform {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform == TargetPlatform.android ? 'android' : null;
  }

  @override
  Future<bool> requestPermission() async {
    final messaging = await _messaging();
    if (messaging == null) return false;
    try {
      final settings = await messaging.requestPermission();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (error) {
      debugPrint('Notification permission failed: $error');
      return false;
    }
  }

  @override
  Future<String?> token() async {
    final messaging = await _messaging();
    if (messaging == null) return null;
    try {
      // On the web a VAPID key of our own is optional; without one FCM uses
      // its default key pair.
      return await messaging.getToken(vapidKey: Env.fcmVapidKey.isEmpty ? null : Env.fcmVapidKey);
    } catch (error) {
      debugPrint('No push token: $error');
      return null;
    }
  }

  @override
  Future<void> deleteToken() async {
    final messaging = await _messaging();
    await messaging?.deleteToken().catchError((Object _) {});
  }

  @override
  Stream<String> get tokenRefreshes async* {
    final messaging = await _messaging();
    if (messaging != null) yield* messaging.onTokenRefresh;
  }

  @override
  Stream<PushMessage> get foregroundMessages async* {
    if (await _messaging() != null) yield* FirebaseMessaging.onMessage.map(_toPush);
  }

  @override
  Stream<PushMessage> get openedMessages async* {
    if (await _messaging() != null) yield* FirebaseMessaging.onMessageOpenedApp.map(_toPush);
  }

  @override
  Future<PushMessage?> launchMessage() async {
    final messaging = await _messaging();
    final message = await messaging?.getInitialMessage();
    return message == null ? null : _toPush(message);
  }

  static PushMessage _toPush(RemoteMessage message) => PushMessage(
        title: message.notification?.title,
        body: message.notification?.body,
        data: {for (final entry in message.data.entries) entry.key: '${entry.value}'},
      );
}
