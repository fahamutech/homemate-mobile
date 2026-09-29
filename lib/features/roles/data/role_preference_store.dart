import 'package:shared_preferences/shared_preferences.dart';

import 'app_role.dart';

/// What this phone remembers about how a person opens the app, per account.
///
/// None of it is secret — it only decides which home opens — so it sits in
/// shared preferences next to the session rather than in a keychain.
abstract class RolePreferenceStore {
  /// The answer to AUTH-001; set once per account.
  Future<AppRole?> startedAs(String userId);
  Future<void> setStartedAs(String userId, AppRole role);

  /// "Always open as …" from ROL-001; null when it is not ticked.
  Future<AppRole?> alwaysOpenAs(String userId);
  Future<void> setAlwaysOpenAs(String userId, AppRole? role);

  /// The role used last, to preselect on ROL-001.
  Future<AppRole?> lastUsed(String userId);
  Future<void> setLastUsed(String userId, AppRole role);
}

class SharedPreferencesRolePreferenceStore implements RolePreferenceStore {
  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  static String _key(String what, String userId) => 'hm.roles.$what.$userId';

  Future<AppRole?> _read(String what, String userId) async =>
      AppRole.fromName((await _prefs).getString(_key(what, userId)));

  Future<void> _write(String what, String userId, AppRole? role) async {
    final prefs = await _prefs;
    if (role == null) {
      await prefs.remove(_key(what, userId));
    } else {
      await prefs.setString(_key(what, userId), role.name);
    }
  }

  @override
  Future<AppRole?> startedAs(String userId) => _read('startedAs', userId);

  @override
  Future<void> setStartedAs(String userId, AppRole role) => _write('startedAs', userId, role);

  @override
  Future<AppRole?> alwaysOpenAs(String userId) => _read('alwaysOpenAs', userId);

  @override
  Future<void> setAlwaysOpenAs(String userId, AppRole? role) => _write('alwaysOpenAs', userId, role);

  @override
  Future<AppRole?> lastUsed(String userId) => _read('lastUsed', userId);

  @override
  Future<void> setLastUsed(String userId, AppRole role) => _write('lastUsed', userId, role);
}

class InMemoryRolePreferenceStore implements RolePreferenceStore {
  final Map<String, AppRole> _values = {};

  AppRole? _read(String what, String userId) => _values['$what.$userId'];

  void _write(String what, String userId, AppRole? role) {
    if (role == null) {
      _values.remove('$what.$userId');
    } else {
      _values['$what.$userId'] = role;
    }
  }

  @override
  Future<AppRole?> startedAs(String userId) async => _read('startedAs', userId);

  @override
  Future<void> setStartedAs(String userId, AppRole role) async => _write('startedAs', userId, role);

  @override
  Future<AppRole?> alwaysOpenAs(String userId) async => _read('alwaysOpenAs', userId);

  @override
  Future<void> setAlwaysOpenAs(String userId, AppRole? role) async => _write('alwaysOpenAs', userId, role);

  @override
  Future<AppRole?> lastUsed(String userId) async => _read('lastUsed', userId);

  @override
  Future<void> setLastUsed(String userId, AppRole role) async => _write('lastUsed', userId, role);
}
