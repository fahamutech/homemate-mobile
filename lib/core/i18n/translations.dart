import 'app_locale.dart';

/// The string catalogue, one map per language.
///
/// Hand-written rather than generated from ARB: this project has no codegen
/// step, and adding one so that a phrase can be changed would mean nobody can
/// fix a typo without running a builder first.
///
/// Kiswahili is the reference language — it is what the app opens in — but
/// English is the fallback for a key Kiswahili has not got yet, because a
/// missing key must degrade to a real sentence and never to a bare
/// `home.greeting`. [assertCatalogueIsComplete] keeps that from going unnoticed
/// in debug.
const Map<AppLocale, Map<String, String>> kTranslations = {
  AppLocale.english: _en,
  AppLocale.swahili: _sw,
};

const Map<String, String> _en = {
  // --- common ---------------------------------------------------------------
  'common.next': 'Next',
  'common.skip': 'Skip',
  'common.cancel': 'Cancel',
  'common.continue': 'Continue',
  'common.done': 'Done',
  'common.save': 'Save',
  'common.retry': 'Try again',
  'common.close': 'Close',
  'common.seeAll': 'See all',
  'common.change': 'Change',
  'common.search': 'Search',

  // --- languages ------------------------------------------------------------
  'language.title': 'Language',
  'language.sheetTitle': 'Choose your language',
  'language.sheetMessage': 'You can change this at any time from the home screen.',
  'language.tooltip': 'Change language',
  'language.current': 'Current language',

  // --- splash ---------------------------------------------------------------
  'splash.tagline': 'Find a home you can trust',

  // --- onboarding -----------------------------------------------------------
  'onboarding.getStarted': 'Get started',
  'onboarding.find.title': 'Find your home',
  'onboarding.find.body':
      'Browse verified listings across Tanzania, with real photos and honest prices.',
  'onboarding.enquire.title': 'Ask and get accepted',
  'onboarding.enquire.body':
      'Send the landlord an enquiry and hear back in the app. Once they accept, the home is yours to secure.',
  'onboarding.moveIn.title': 'Move in',
  'onboarding.moveIn.body':
      'Pay securely — we verify it, and every receipt and document stays in one place.',

  // --- sign in --------------------------------------------------------------
  'signIn.title': 'Sign in',
  'signIn.message': 'We will send a code to confirm your number.',
  'signIn.sendCode': 'Send code',
  'signIn.pinHint': 'Once you have set a PIN, this phone will sign you in with it — no more codes.',
  'signIn.welcomeBack': 'Welcome back',
  'signIn.notYou': 'Not you? Use a different number',
  'signIn.differentNumber.title': 'Use a different number?',
  'signIn.differentNumber.message':
      'We will send a code to confirm the new number. Your PIN stays on the account you already have.',

  // --- bottom navigation ----------------------------------------------------
  'nav.home': 'Home',
  'nav.search': 'Search',
  'nav.favourite': 'Favourite',
  'nav.activity': 'Activity',
  'nav.profile': 'Profile',

  // --- home -----------------------------------------------------------------
  'home.greeting': 'Hi, {name} 👋',
  'home.greeting.fallbackName': 'there',
  'home.country': 'Tanzania',
  'home.searchPrompt': 'Search by area, price or type',
  'home.searchSemantics': 'Search homes',
  'home.featured': 'Featured Properties',
  'home.nearYou': 'Near You',
  'home.empty.title': 'No listings yet',
  'home.empty.message': 'New homes are added every day — check back shortly.',
  'home.nearby.empty.title': 'Nothing nearby yet',
  'home.nearby.emptyType.title': 'None of those nearby',
  'home.nearby.empty.radius': 'Nothing within 10 km yet. Try another area, or widen your search.',
  'home.nearby.empty.message': 'We will show homes around you as they are listed.',
  'home.nearby.empty.otherType': 'Try another category, or search a different area.',
  'home.notifications': 'Notifications',
  'home.notifications.unread': '{count} unread notifications',

  // --- near me / location ---------------------------------------------------
  'nearMe.chooseArea': 'Choose an area',
  'nearMe.askMe': 'Ask me',
  'nearMe.recheck': 'I have allowed it — check again',
  'nearMe.sortedByDistance': 'Sorted by distance from you',
  'nearMe.near': 'Near {place}',
  'nearMe.recentre': 'Centre on my location',
  'nearMe.searchThisArea': 'Search this area',
  'nearMe.mapCentreHint': 'Centre the map on where you are and see what is around you.',
  'nearMe.mapNoPins': 'No listings with a map location here yet. Try the list view, or move the map.',
  'nearMe.title.off': 'Location is switched off',
  'nearMe.title.blocked': 'Location is blocked for HomeMate',
  'nearMe.title.default': 'See homes near you',
  'nearMe.message.off':
      'Turn on location in your device settings and we will sort listings from nearest to furthest.',
  'nearMe.message.blocked':
      'HomeMate cannot ask again from here. Allow location in Settings, or pick an area instead.',
  'nearMe.message.denied': 'Allow location and we will sort listings from nearest to furthest.',
  'nearMe.message.default':
      'Share your location and we will sort listings from nearest to furthest.',
  'nearMe.action.openLocationSettings': 'Open location settings',
  'nearMe.action.openSettings': 'Open settings',
  'nearMe.action.useMyLocation': 'Use my location',

  // --- area picker ----------------------------------------------------------
  'areaPicker.title': 'Choose an area',
  'areaPicker.message': 'We will show homes near this place instead of near you.',
  'areaPicker.hint': 'Masaki, Mikocheni, Arusha…',
  'areaPicker.minLetters': 'Type at least three letters.',
  'areaPicker.failed': 'Could not search places.',
  'areaPicker.none': 'No places found.',

  // --- distance -------------------------------------------------------------
  'distance.metres': '{value} m away',
  'distance.kilometres': '{value} km away',
};

const Map<String, String> _sw = {
  // --- common ---------------------------------------------------------------
  'common.next': 'Endelea',
  'common.skip': 'Ruka',
  'common.cancel': 'Ghairi',
  'common.continue': 'Endelea',
  'common.done': 'Imekamilika',
  'common.save': 'Hifadhi',
  'common.retry': 'Jaribu tena',
  'common.close': 'Funga',
  'common.seeAll': 'Ona zote',
  'common.change': 'Badilisha',
  'common.search': 'Tafuta',

  // --- languages ------------------------------------------------------------
  'language.title': 'Lugha',
  'language.sheetTitle': 'Chagua lugha yako',
  'language.sheetMessage': 'Unaweza kubadilisha hii wakati wowote kutoka ukurasa wa mwanzo.',
  'language.tooltip': 'Badilisha lugha',
  'language.current': 'Lugha ya sasa',

  // --- splash ---------------------------------------------------------------
  'splash.tagline': 'Pata nyumba unayoweza kuitegemea',

  // --- onboarding -----------------------------------------------------------
  'onboarding.getStarted': 'Anza sasa',
  'onboarding.find.title': 'Pata nyumba yako',
  'onboarding.find.body':
      'Pitia nyumba zilizothibitishwa kote Tanzania, zikiwa na picha za kweli na bei za uwazi.',
  'onboarding.enquire.title': 'Uliza na ukubaliwe',
  'onboarding.enquire.body':
      'Tuma ombi kwa mwenye nyumba na upate jibu ndani ya app. Akikubali, unaweza kulipia ili uipate.',
  'onboarding.moveIn.title': 'Ingia kuishi',
  'onboarding.moveIn.body':
      'Lipa kwa usalama — tunathibitisha malipo, na risiti na nyaraka zote zinabaki sehemu moja.',

  // --- sign in --------------------------------------------------------------
  'signIn.title': 'Ingia',
  'signIn.message': 'Tutakutumia namba ya uthibitisho kwenye simu yako.',
  'signIn.sendCode': 'Tuma namba',
  'signIn.pinHint':
      'Mara utakapoweka PIN, simu hii itakuingiza kwa PIN hiyo — hutahitaji namba za uthibitisho tena.',
  'signIn.welcomeBack': 'Karibu tena',
  'signIn.notYou': 'Si wewe? Tumia namba nyingine',
  'signIn.differentNumber.title': 'Utumie namba nyingine?',
  'signIn.differentNumber.message':
      'Tutatuma namba ya uthibitisho kuithibitisha namba mpya. PIN yako itasalia kwenye akaunti uliyo nayo.',

  // --- bottom navigation ----------------------------------------------------
  'nav.home': 'Mwanzo',
  'nav.search': 'Tafuta',
  'nav.favourite': 'Vipendwa',
  'nav.activity': 'Shughuli',
  'nav.profile': 'Wasifu',

  // --- home -----------------------------------------------------------------
  'home.greeting': 'Habari, {name} 👋',
  'home.greeting.fallbackName': 'karibu',
  'home.country': 'Tanzania',
  'home.searchPrompt': 'Tafuta kwa eneo, bei au aina',
  'home.searchSemantics': 'Tafuta nyumba',
  'home.featured': 'Nyumba Zilizoangaziwa',
  'home.nearYou': 'Karibu Nawe',
  'home.empty.title': 'Hakuna nyumba bado',
  'home.empty.message': 'Nyumba mpya zinaongezwa kila siku — tafadhali angalia tena baadaye.',
  'home.nearby.empty.title': 'Hakuna nyumba karibu bado',
  'home.nearby.emptyType.title': 'Hakuna ya aina hiyo karibu',
  'home.nearby.empty.radius':
      'Hakuna kitu ndani ya kilomita 10 bado. Jaribu eneo lingine, au panua utafutaji wako.',
  'home.nearby.empty.message': 'Tutakuonyesha nyumba zilizo karibu nawe zitakapoorodheshwa.',
  'home.nearby.empty.otherType': 'Jaribu aina nyingine, au tafuta eneo lingine.',
  'home.notifications': 'Taarifa',
  'home.notifications.unread': 'Taarifa {count} hazijafunguliwa',

  // --- near me / location ---------------------------------------------------
  'nearMe.chooseArea': 'Chagua eneo',
  'nearMe.askMe': 'Niulize',
  'nearMe.recheck': 'Nimeruhusu — angalia tena',
  'nearMe.sortedByDistance': 'Zimepangwa kwa ukaribu nawe',
  'nearMe.near': 'Karibu na {place}',
  'nearMe.recentre': 'Nionyeshe nilipo',
  'nearMe.searchThisArea': 'Tafuta eneo hili',
  'nearMe.mapCentreHint': 'Weka ramani pale ulipo na uone kilichopo karibu nawe.',
  'nearMe.mapNoPins': 'Hakuna nyumba yenye eneo kwenye ramani hapa bado. Jaribu mwonekano wa orodha, au sogeza ramani.',
  'nearMe.title.off': 'Mahali pako pamezimwa',
  'nearMe.title.blocked': 'HomeMate imezuiwa kujua mahali pako',
  'nearMe.title.default': 'Ona nyumba zilizo karibu nawe',
  'nearMe.message.off':
      'Washa kitambua mahali katika mipangilio ya simu yako, na tutapanga nyumba kuanzia zilizo karibu zaidi.',
  'nearMe.message.blocked':
      'HomeMate haiwezi kuuliza tena kutoka hapa. Ruhusu kitambua mahali katika Mipangilio, au chagua eneo badala yake.',
  'nearMe.message.denied':
      'Ruhusu kitambua mahali na tutapanga nyumba kuanzia zilizo karibu zaidi.',
  'nearMe.message.default':
      'Shiriki mahali ulipo na tutapanga nyumba kuanzia zilizo karibu zaidi.',
  'nearMe.action.openLocationSettings': 'Fungua mipangilio ya mahali',
  'nearMe.action.openSettings': 'Fungua mipangilio',
  'nearMe.action.useMyLocation': 'Tumia mahali nilipo',

  // --- area picker ----------------------------------------------------------
  'areaPicker.title': 'Chagua eneo',
  'areaPicker.message': 'Tutakuonyesha nyumba zilizo karibu na eneo hili badala ya ulipo.',
  'areaPicker.hint': 'Masaki, Mikocheni, Arusha…',
  'areaPicker.minLetters': 'Andika herufi tatu au zaidi.',
  'areaPicker.failed': 'Imeshindwa kutafuta maeneo.',
  'areaPicker.none': 'Hakuna eneo lililopatikana.',

  // --- distance -------------------------------------------------------------
  'distance.metres': 'mita {value} kutoka hapa',
  'distance.kilometres': 'km {value} kutoka hapa',
};

/// Fails a debug build when a language is missing a key English has, so an
/// untranslated string is caught by the test suite rather than by a customer.
void assertCatalogueIsComplete() {
  assert(() {
    for (final entry in kTranslations.entries) {
      final missing = _en.keys.where((key) => !entry.value.containsKey(key)).toList();
      if (missing.isNotEmpty) {
        throw StateError('${entry.key.englishName} is missing: ${missing.join(', ')}');
      }
      final extra = entry.value.keys.where((key) => !_en.containsKey(key)).toList();
      if (extra.isNotEmpty) {
        throw StateError('${entry.key.englishName} has keys English does not: ${extra.join(', ')}');
      }
    }
    return true;
  }());
}
