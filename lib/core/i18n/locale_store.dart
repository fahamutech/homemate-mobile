import 'package:shared_preferences/shared_preferences.dart';

import 'app_locale.dart';

/// Remembers the language the customer chose.
///
/// Kept apart from the session store on purpose: the choice belongs to the
/// device, not to an account, so signing out must not put the app back into a
/// language the person does not read.
abstract class LocaleStore {
  Future<AppLocale?> read();
  Future<void> write(AppLocale locale);
}

class SharedPreferencesLocaleStore implements LocaleStore {
  SharedPreferencesLocaleStore({SharedPreferences? preferences}) : _injected = preferences;

  static const _key = 'hm.locale';

  final SharedPreferences? _injected;
  SharedPreferences? _cached;

  Future<SharedPreferences> get _prefs async =>
      _injected ?? (_cached ??= await SharedPreferences.getInstance());

  @override
  Future<AppLocale?> read() async {
    final code = (await _prefs).getString(_key);
    // Null rather than the fallback, so the caller can tell "chose Kiswahili"
    // from "has not chosen" — only the second may be overridden by the device.
    return code == null ? null : AppLocale.fromCode(code);
  }

  @override
  Future<void> write(AppLocale locale) async => (await _prefs).setString(_key, locale.code);
}

class InMemoryLocaleStore implements LocaleStore {
  InMemoryLocaleStore([this._locale]);

  AppLocale? _locale;

  @override
  Future<AppLocale?> read() async => _locale;

  @override
  Future<void> write(AppLocale locale) async => _locale = locale;
}
