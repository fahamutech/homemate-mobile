import 'dart:ui';

/// The languages HomeMate speaks.
///
/// Kiswahili is first and is the default, because it is the language most of
/// the people renting a home in Tanzania actually think in. English is offered
/// because a good share of the market works in it — but nobody should have to
/// change a setting to be spoken to in Kiswahili.
enum AppLocale {
  swahili(code: 'sw', endonym: 'Kiswahili', englishName: 'Swahili'),
  english(code: 'en', endonym: 'English', englishName: 'English');

  const AppLocale({required this.code, required this.endonym, required this.englishName});

  /// The ISO-639-1 tag, and the key this choice is stored under.
  final String code;

  /// What the language calls itself. A language list that says "Swahili" to a
  /// Kiswahili speaker is a list written for somebody else.
  final String endonym;

  final String englishName;

  Locale get locale => Locale(code);

  static const AppLocale fallback = AppLocale.swahili;

  /// The locale for a stored code or a device setting, falling back to
  /// Kiswahili for anything we do not translate.
  static AppLocale fromCode(String? code) {
    if (code == null) return fallback;
    final tag = code.split(RegExp('[-_]')).first.toLowerCase();
    for (final value in AppLocale.values) {
      if (value.code == tag) return value;
    }
    return fallback;
  }

  static List<Locale> get supportedLocales =>
      AppLocale.values.map((value) => value.locale).toList(growable: false);
}
