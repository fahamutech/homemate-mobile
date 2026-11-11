import 'dart:async';

import 'package:homemate_mobile/core/push/push_device_repository.dart';
import 'package:homemate_mobile/core/push/push_messaging.dart';

/// FCM on the phone, in memory: a test decides whether permission is given,
/// which token the install has, and when a push arrives or is tapped.
class FakePushMessaging implements PushMessaging {
  FakePushMessaging({this.platform = 'android'});

  @override
  final String? platform;

  bool grantPermission = true;
  int permissionRequests = 0;
  String? currentToken = 'fcm-token-install-1';
  int tokensDeleted = 0;
  PushMessage? launchedFrom;

  final _refreshes = StreamController<String>.broadcast();
  final _foreground = StreamController<PushMessage>.broadcast();
  final _opened = StreamController<PushMessage>.broadcast();

  void rotateToken(String token) {
    currentToken = token;
    _refreshes.add(token);
  }

  void arriveWhileOpen(PushMessage message) => _foreground.add(message);
  void tapInTray(PushMessage message) => _opened.add(message);

  @override
  Future<bool> requestPermission() async {
    permissionRequests += 1;
    return grantPermission;
  }

  @override
  Future<String?> token() async => currentToken;

  @override
  Future<void> deleteToken() async {
    tokensDeleted += 1;
    currentToken = null;
  }

  @override
  Stream<String> get tokenRefreshes => _refreshes.stream;

  @override
  Stream<PushMessage> get foregroundMessages => _foreground.stream;

  @override
  Stream<PushMessage> get openedMessages => _opened.stream;

  @override
  Future<PushMessage?> launchMessage() async => launchedFrom;
}

/// The server's device list, as the push controller changes it.
class FakePushDeviceRepository implements PushDeviceRepository {
  final registered = <({String token, String platform})>[];
  final unregistered = <String>[];

  /// Set by a test to see what the session looked like when sign-out called.
  bool Function()? sessionAliveCheck;
  bool? sessionAliveAtUnregister;

  @override
  Future<void> register({required String token, required String platform, String? appVersion}) async {
    registered.add((token: token, platform: platform));
  }

  @override
  Future<void> unregister(String token) async {
    sessionAliveAtUnregister = sessionAliveCheck?.call();
    unregistered.add(token);
  }
}
