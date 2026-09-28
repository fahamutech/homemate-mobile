import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_app_update/in_app_update.dart';

import 'app_updater.dart';

/// Android release builds ask Google Play; everything else has no store to ask.
///
/// Release only: the Play API answers solely for an app Play installed, so a
/// debug build from `flutter run` would get an error on every launch.
AppUpdater createPlatformUpdater() =>
    !kIsWeb && Platform.isAndroid && kReleaseMode ? PlayStoreUpdater() : NoAppUpdater();

/// Google Play's in-app updates.
///
/// The normal path is the *flexible* flow: a banner offers the update, Play
/// downloads it while the app stays usable, and a second tap restarts into it.
/// A release pushed with in-app update priority 4 or 5 (set through the Play
/// Developer API) instead gets Play's full-screen *immediate* flow once per
/// launch — for a build the old one must not keep running without.
class PlayStoreUpdater extends AppUpdater {
  final _changes = StreamController<AppUpdateStatus>.broadcast();
  bool _offeredImmediate = false;

  static const _immediatePriority = 4;

  @override
  Stream<AppUpdateStatus> get changes => _changes.stream;

  @override
  Future<AppUpdateStatus> check() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      switch (info.installStatus) {
        case InstallStatus.downloaded:
          return AppUpdateStatus.ready;
        case InstallStatus.pending || InstallStatus.downloading:
          return AppUpdateStatus.downloading;
        default:
          break;
      }
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return AppUpdateStatus.none;
      }
      if (info.updatePriority >= _immediatePriority &&
          info.immediateUpdateAllowed &&
          !_offeredImmediate) {
        _offeredImmediate = true;
        final result = await InAppUpdate.performImmediateUpdate();
        // Accepted means Play restarts the app into the new build; a refusal
        // falls back to the banner rather than blocking the customer.
        if (result == AppUpdateResult.success) return AppUpdateStatus.none;
      }
      return info.flexibleUpdateAllowed ? AppUpdateStatus.available : AppUpdateStatus.none;
    } on PlatformException {
      // Sideloaded, no Play Store, or Play unreachable: nothing to offer.
      return AppUpdateStatus.none;
    }
  }

  @override
  Future<AppUpdateStatus> apply(AppUpdateStatus status) async {
    try {
      switch (status) {
        case AppUpdateStatus.available:
          _changes.add(AppUpdateStatus.downloading);
          // Completes once the download has finished, not when it starts.
          final result = await InAppUpdate.startFlexibleUpdate();
          return result == AppUpdateResult.success
              ? AppUpdateStatus.ready
              : AppUpdateStatus.available;
        case AppUpdateStatus.ready:
          // Play installs and restarts the app; nothing after this runs.
          await InAppUpdate.completeFlexibleUpdate();
          return AppUpdateStatus.none;
        case AppUpdateStatus.none || AppUpdateStatus.downloading:
          return status;
      }
    } on PlatformException {
      return status == AppUpdateStatus.ready ? AppUpdateStatus.ready : AppUpdateStatus.available;
    }
  }

  @override
  void dispose() => _changes.close();
}
