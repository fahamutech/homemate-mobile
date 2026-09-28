import 'dart:convert';
import 'dart:js_interop';

import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

import '../config/env.dart';
import 'app_updater.dart';

AppUpdater createPlatformUpdater() => WebVersionUpdater(currentBuild: Env.buildNumber);

/// Notices a newer deploy of the PWA and moves onto it.
///
/// Flutter no longer ships a caching service worker, and Firebase Hosting
/// serves every file `no-cache`, so a reload is always the newest build. What
/// is left is knowing *when* to reload: this compares the build number
/// compiled into the running code with the deployed `version.json`.
///
/// When one is newer it is applied in the least disruptive way available:
/// quietly, when the customer comes back to a tab they left for a while
/// (they would be re-orienting anyway, and the route and session survive a
/// reload), or straight away if they tap the banner.
class WebVersionUpdater extends AppUpdater {
  WebVersionUpdater({required this.currentBuild}) {
    web.document.addEventListener('visibilitychange', _onVisibilityChange.toJS);
  }

  final int currentBuild;
  bool _newer = false;
  DateTime? _hiddenAt;

  /// Long enough that the customer was not in the middle of something — a
  /// photo picker or a mobile-money prompt also hides the page, briefly.
  static const _quietReloadAfter = Duration(minutes: 10);

  @override
  Duration? get pollEvery => const Duration(minutes: 30);

  @override
  Future<AppUpdateStatus> check() async {
    if (currentBuild <= 0) return AppUpdateStatus.none;
    if (!_newer) {
      try {
        final url = Uri.parse(web.document.baseURI).resolve('version.json').replace(
          queryParameters: {'t': '${DateTime.now().millisecondsSinceEpoch}'},
        );
        final response = await http.get(url);
        if (response.statusCode == 200) {
          _newer = isNewerBuild(jsonDecode(response.body), currentBuild);
        }
      } catch (_) {
        // Offline or a half-deployed site: try again on the next check.
      }
    }
    return _newer ? AppUpdateStatus.ready : AppUpdateStatus.none;
  }

  @override
  Future<AppUpdateStatus> apply(AppUpdateStatus status) async {
    if (status == AppUpdateStatus.ready) web.window.location.reload();
    return status;
  }

  void _onVisibilityChange(web.Event _) {
    if (web.document.visibilityState == 'hidden') {
      _hiddenAt = DateTime.now();
      return;
    }
    final hiddenAt = _hiddenAt;
    _hiddenAt = null;
    if (hiddenAt == null || DateTime.now().difference(hiddenAt) < _quietReloadAfter) return;
    check().then((status) {
      if (status == AppUpdateStatus.ready) web.window.location.reload();
    });
  }
}
