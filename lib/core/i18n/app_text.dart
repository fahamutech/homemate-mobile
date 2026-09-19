import 'package:flutter/widgets.dart';

import 'app_locale.dart';
import 'translations.dart';

/// The app's words, in whichever language is current.
///
/// Named getters rather than `t('some.key')` at the call sites: a mistyped key
/// should be a compile error, not a screen that reads `home.featured`. The keys
/// live here, once, and every screen asks for `context.text.featured`.
class AppText {
  const AppText(this.locale);

  final AppLocale locale;

  static AppText of(BuildContext context) =>
      Localizations.of<AppText>(context, AppText) ?? const AppText(AppLocale.fallback);

  /// Looks the key up in this language, then in English, then gives back the
  /// key — which only happens for a key that is in no catalogue at all, and
  /// [assertCatalogueIsComplete] makes that a failing test.
  String _s(String key, [Map<String, Object?>? params]) {
    final value = kTranslations[locale]?[key] ??
        kTranslations[AppLocale.english]?[key] ??
        key;
    if (params == null) return value;
    return params.entries.fold(
      value,
      (text, param) => text.replaceAll('{${param.key}}', '${param.value}'),
    );
  }

  // --- common ---------------------------------------------------------------
  String get next => _s('common.next');
  String get skip => _s('common.skip');
  String get cancel => _s('common.cancel');
  String get continueLabel => _s('common.continue');
  String get done => _s('common.done');
  String get save => _s('common.save');
  String get retry => _s('common.retry');
  String get close => _s('common.close');
  String get seeAll => _s('common.seeAll');
  String get change => _s('common.change');
  String get search => _s('common.search');

  // --- languages ------------------------------------------------------------
  String get language => _s('language.title');
  String get languageSheetTitle => _s('language.sheetTitle');
  String get languageSheetMessage => _s('language.sheetMessage');
  String get languageTooltip => _s('language.tooltip');
  String get currentLanguage => _s('language.current');

  // --- splash ---------------------------------------------------------------
  String get splashTagline => _s('splash.tagline');

  // --- onboarding -----------------------------------------------------------
  String get getStarted => _s('onboarding.getStarted');
  String get onboardingFindTitle => _s('onboarding.find.title');
  String get onboardingFindBody => _s('onboarding.find.body');
  String get onboardingViewingsTitle => _s('onboarding.viewings.title');
  String get onboardingViewingsBody => _s('onboarding.viewings.body');
  String get onboardingMoveInTitle => _s('onboarding.moveIn.title');
  String get onboardingMoveInBody => _s('onboarding.moveIn.body');

  // --- sign in --------------------------------------------------------------
  String get signInTitle => _s('signIn.title');
  String get signInMessage => _s('signIn.message');
  String get sendCode => _s('signIn.sendCode');
  String get signInPinHint => _s('signIn.pinHint');
  String get welcomeBack => _s('signIn.welcomeBack');
  String get notYou => _s('signIn.notYou');
  String get differentNumberTitle => _s('signIn.differentNumber.title');
  String get differentNumberMessage => _s('signIn.differentNumber.message');

  // --- bottom navigation ----------------------------------------------------
  String get navHome => _s('nav.home');
  String get navSearch => _s('nav.search');
  String get navFavourite => _s('nav.favourite');
  String get navActivity => _s('nav.activity');
  String get navProfile => _s('nav.profile');

  // --- home -----------------------------------------------------------------
  String greeting(String? name) =>
      _s('home.greeting', {'name': name ?? _s('home.greeting.fallbackName')});
  String get country => _s('home.country');
  String get homeSearchPrompt => _s('home.searchPrompt');
  String get homeSearchSemantics => _s('home.searchSemantics');
  String get featured => _s('home.featured');
  String get nearYou => _s('home.nearYou');
  String get homeEmptyTitle => _s('home.empty.title');
  String get homeEmptyMessage => _s('home.empty.message');
  String get nearbyEmptyTitle => _s('home.nearby.empty.title');
  String get nearbyEmptyTypeTitle => _s('home.nearby.emptyType.title');
  String get nearbyEmptyRadius => _s('home.nearby.empty.radius');
  String get nearbyEmptyMessage => _s('home.nearby.empty.message');
  String get nearbyEmptyOtherType => _s('home.nearby.empty.otherType');
  String get notifications => _s('home.notifications');
  String unreadNotifications(int count) => _s('home.notifications.unread', {'count': count});

  // --- near me / location ---------------------------------------------------
  String get chooseArea => _s('nearMe.chooseArea');
  String get askMe => _s('nearMe.askMe');
  String get recheckLocation => _s('nearMe.recheck');
  String get sortedByDistance => _s('nearMe.sortedByDistance');
  String nearPlace(String place) => _s('nearMe.near', {'place': place});
  String get recentre => _s('nearMe.recentre');
  String get searchThisArea => _s('nearMe.searchThisArea');
  String get mapCentreHint => _s('nearMe.mapCentreHint');
  String get mapNoPins => _s('nearMe.mapNoPins');
  String get locationOffTitle => _s('nearMe.title.off');
  String get locationBlockedTitle => _s('nearMe.title.blocked');
  String get locationDefaultTitle => _s('nearMe.title.default');
  String get locationOffMessage => _s('nearMe.message.off');
  String get locationBlockedMessage => _s('nearMe.message.blocked');
  String get locationDeniedMessage => _s('nearMe.message.denied');
  String get locationDefaultMessage => _s('nearMe.message.default');
  String get openLocationSettings => _s('nearMe.action.openLocationSettings');
  String get openSettings => _s('nearMe.action.openSettings');
  String get useMyLocation => _s('nearMe.action.useMyLocation');

  // --- area picker ----------------------------------------------------------
  String get areaPickerTitle => _s('areaPicker.title');
  String get areaPickerMessage => _s('areaPicker.message');
  String get areaPickerHint => _s('areaPicker.hint');
  String get areaPickerMinLetters => _s('areaPicker.minLetters');
  String get areaPickerFailed => _s('areaPicker.failed');
  String get areaPickerNone => _s('areaPicker.none');

  // --- distance -------------------------------------------------------------
  String metresAway(String value) => _s('distance.metres', {'value': value});
  String kilometresAway(String value) => _s('distance.kilometres', {'value': value});
}

/// Hands [AppText] to the widget tree through `Localizations`, so a language
/// change rebuilds every screen that reads a string without any screen having
/// to watch a provider.
class AppTextDelegate extends LocalizationsDelegate<AppText> {
  const AppTextDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocale.values.any((value) => value.code == locale.languageCode);

  @override
  Future<AppText> load(Locale locale) async =>
      AppText(AppLocale.fromCode(locale.languageCode));

  @override
  bool shouldReload(AppTextDelegate old) => false;
}

extension AppTextContext on BuildContext {
  /// The app's words. `context.text.featured`.
  AppText get text => AppText.of(this);
}
