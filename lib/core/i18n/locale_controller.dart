import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_locale.dart';
import 'locale_store.dart';

/// Which language the app is in, and the only thing that changes it.
///
/// It starts on Kiswahili rather than on the device language. That is a product
/// decision, not an oversight: an unconfigured phone in this market is very
/// often set to English while the person holding it would rather read
/// Kiswahili, so the app opens in Kiswahili and offers the switch immediately —
/// in the onboarding flow, and afterwards from the home screen.
class LocaleController extends StateNotifier<AppLocale> {
  LocaleController(this._store) : super(AppLocale.fallback) {
    _restore();
  }

  final LocaleStore _store;

  Future<void> _restore() async {
    final stored = await _store.read();
    if (stored == null || !mounted) return;
    state = stored;
  }

  Future<void> select(AppLocale locale) async {
    if (state == locale) return;
    state = locale;
    await _store.write(locale);
  }
}

final localeStoreProvider = Provider<LocaleStore>(
  (ref) => SharedPreferencesLocaleStore(),
);

final localeProvider = StateNotifierProvider<LocaleController, AppLocale>(
  (ref) => LocaleController(ref.watch(localeStoreProvider)),
);
