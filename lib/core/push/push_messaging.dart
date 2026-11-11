/// A push as the app sees it: the words, and the data that says what it is
/// about (`notificationId`, `kind`, `audience`, `subjectTable`, `subjectId` —
/// see the backend's push-outbox.mjs).
class PushMessage {
  const PushMessage({this.title, this.body, this.data = const {}});

  final String? title;
  final String? body;
  final Map<String, String> data;
}

/// The device side of push notifications, behind an interface so tests (and
/// platforms without Firebase set up) never touch the vendor.
abstract class PushMessaging {
  /// `android` or `web` — or null where push is not set up (iOS, today), in
  /// which case nothing is asked and nothing registered.
  String? get platform;

  /// Asks the person, once; later calls answer from what they chose.
  Future<bool> requestPermission();

  /// This install's registration token, or null when there is none to give.
  Future<String?> token();

  Future<void> deleteToken();

  /// FCM rotates tokens; each new one must reach the server.
  Stream<String> get tokenRefreshes;

  /// Arrived while the app was open. The system shows nothing for these, so
  /// the app does.
  Stream<PushMessage> get foregroundMessages;

  /// Tapped in the notification tray while the app was in the background.
  Stream<PushMessage> get openedMessages;

  /// The push whose tap launched the app from closed, if any.
  Future<PushMessage?> launchMessage();
}

/// For builds and tests with no push at all.
class NoPushMessaging implements PushMessaging {
  const NoPushMessaging();

  @override
  String? get platform => null;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<String?> token() async => null;

  @override
  Future<void> deleteToken() async {}

  @override
  Stream<String> get tokenRefreshes => const Stream.empty();

  @override
  Stream<PushMessage> get foregroundMessages => const Stream.empty();

  @override
  Stream<PushMessage> get openedMessages => const Stream.empty();

  @override
  Future<PushMessage?> launchMessage() async => null;
}
