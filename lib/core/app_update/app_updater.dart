/// How far along getting onto the newest build is.
enum AppUpdateStatus {
  /// Nothing to offer: already current, or this platform cannot tell.
  none,

  /// Android: Google Play has a newer build and the customer has not started
  /// it yet.
  available,

  /// Android: the flexible update is downloading in the background, and the
  /// app stays usable while it does.
  downloading,

  /// A newer build is ready to take over — a restart on Android, a reload on
  /// the web.
  ready,
}

/// One platform's way of noticing and applying a newer build.
///
/// Android asks Google Play (the in-app updates API); the web compares its own
/// build number with the deployed `version.json`. Everything else — iOS, the
/// desktop, the test VM — has nothing to ask, which is [NoAppUpdater].
abstract class AppUpdater {
  /// Asks whether there is something newer.
  Future<AppUpdateStatus> check();

  /// What the banner's button does for [status]; returns the status after.
  Future<AppUpdateStatus> apply(AppUpdateStatus status);

  /// Changes the platform reports without being asked, such as a download
  /// starting.
  Stream<AppUpdateStatus> get changes => const Stream.empty();

  /// How often to look again while the app stays open. Null checks only at
  /// launch and whenever the app comes back to the foreground.
  Duration? get pollEvery => null;

  void dispose() {}
}

class NoAppUpdater extends AppUpdater {
  @override
  Future<AppUpdateStatus> check() async => AppUpdateStatus.none;

  @override
  Future<AppUpdateStatus> apply(AppUpdateStatus status) async => status;
}

/// Whether the deployed `version.json` describes a newer build than
/// [currentBuild]. Kept apart from the fetching so it can be tested on the VM.
///
/// A missing or malformed number is never "newer": a broken file must not put
/// every open tab into a reload loop.
bool isNewerBuild(Object? versionJson, int currentBuild) {
  if (currentBuild <= 0 || versionJson is! Map) return false;
  final deployed = int.tryParse('${versionJson['build_number']}');
  return deployed != null && deployed > currentBuild;
}
