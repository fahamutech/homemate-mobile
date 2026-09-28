import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_updater.dart';
import 'platform_updater_io.dart' if (dart.library.js_interop) 'platform_updater_web.dart';

/// Keeps [AppUpdateStatus] current: at launch, whenever the app returns to the
/// foreground, and on the platform's own schedule.
class AppUpdateController extends StateNotifier<AppUpdateStatus> with WidgetsBindingObserver {
  AppUpdateController(this._updater) : super(AppUpdateStatus.none) {
    _changes = _updater.changes.listen((status) {
      if (mounted) state = status;
    });
    WidgetsBinding.instance.addObserver(this);
    final every = _updater.pollEvery;
    if (every != null) _poll = Timer.periodic(every, (_) => check());
    check();
  }

  final AppUpdater _updater;
  late final StreamSubscription<AppUpdateStatus> _changes;
  Timer? _poll;

  Future<void> check() async {
    // Once something is downloading or ready, a check can only say the same
    // thing more slowly — and must not flicker the banner back a step.
    if (state == AppUpdateStatus.downloading || state == AppUpdateStatus.ready) return;
    final status = await _updater.check();
    if (mounted) state = status;
  }

  Future<void> apply() async {
    final status = await _updater.apply(state);
    if (mounted) state = status;
  }

  @override
  // ignore: avoid_renaming_method_parameters — `state` is the notifier's own.
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.resumed) check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    _changes.cancel();
    _updater.dispose();
    super.dispose();
  }
}

final appUpdaterProvider = Provider<AppUpdater>((ref) => createPlatformUpdater());

final appUpdateProvider = StateNotifierProvider<AppUpdateController, AppUpdateStatus>(
  (ref) => AppUpdateController(ref.watch(appUpdaterProvider)),
);
