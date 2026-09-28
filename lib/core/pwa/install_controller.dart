import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'install_prompt.dart';
import 'platform_install_io.dart' if (dart.library.js_interop) 'platform_install_web.dart';

class InstallState {
  const InstallState({this.method = InstallMethod.none, this.dismissed = false});

  final InstallMethod method;

  /// "Not now" on the home-screen card. The profile entry stays regardless.
  final bool dismissed;

  bool get canInstall => method != InstallMethod.none;
  bool get showCard => canInstall && !dismissed;
}

/// Where "Not now" is remembered, so the card does not nag on every launch.
abstract class InstallDismissalStore {
  Future<DateTime?> read();
  Future<void> write(DateTime at);
}

class SharedPreferencesInstallDismissalStore implements InstallDismissalStore {
  static const _key = 'pwa.install.dismissedAt';

  @override
  Future<DateTime?> read() async {
    final millis = (await SharedPreferences.getInstance()).getInt(_key);
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  @override
  Future<void> write(DateTime at) async =>
      (await SharedPreferences.getInstance()).setInt(_key, at.millisecondsSinceEpoch);
}

class InstallController extends StateNotifier<InstallState> {
  InstallController(this._prompt, this._store) : super(const InstallState()) {
    _changes = _prompt.changes.listen((_) => _refresh());
    _restore();
  }

  final InstallPrompt _prompt;
  final InstallDismissalStore _store;
  late final StreamSubscription<void> _changes;

  /// After this long the card may ask once more.
  static const quietPeriod = Duration(days: 14);

  Future<void> _restore() async {
    if (_prompt.method == InstallMethod.none) return;
    final dismissedAt = await _store.read();
    if (!mounted) return;
    state = InstallState(
      method: _prompt.method,
      dismissed: dismissedAt != null && DateTime.now().difference(dismissedAt) < quietPeriod,
    );
  }

  void _refresh() {
    if (mounted) state = InstallState(method: _prompt.method, dismissed: state.dismissed);
  }

  Future<void> dismiss() async {
    state = InstallState(method: state.method, dismissed: true);
    await _store.write(DateTime.now());
  }

  /// The browser's own dialog; true when the customer accepted.
  Future<bool> prompt() async {
    final accepted = await _prompt.prompt();
    _refresh();
    return accepted;
  }

  @override
  void dispose() {
    _changes.cancel();
    super.dispose();
  }
}

final installPromptProvider = Provider<InstallPrompt>((ref) => createPlatformInstallPrompt());

final installDismissalStoreProvider = Provider<InstallDismissalStore>(
  (ref) => SharedPreferencesInstallDismissalStore(),
);

final installProvider = StateNotifierProvider<InstallController, InstallState>(
  (ref) => InstallController(
    ref.watch(installPromptProvider),
    ref.watch(installDismissalStoreProvider),
  ),
);
