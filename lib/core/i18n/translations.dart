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
  'common.optional': 'Optional',
  'common.back': 'Back',
  'common.stepOf': 'Step {current} of {total}',

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
  'nav.listings': 'Listings',
  'nav.enquiries': 'Enquiries',
  'nav.earnings': 'Earnings',
  'nav.homes': 'Homes',
  'nav.tenants': 'Tenants',
  'nav.money': 'Money',

  // --- widget catalogue (debug only) -----------------------------------------
  'dev.widgets.title': 'Widget catalogue',
  'dev.widgets.buttons': 'Buttons',
  'dev.widgets.badges': 'Badges',
  'dev.widgets.forms': 'Forms',
  'dev.widgets.feedback': 'Notes',
  'dev.widgets.data': 'Rows and lists',
  'dev.widgets.partner': 'Partner',
  'dev.widgets.timeline': 'Timeline',
  'dev.widgets.navigation': 'Navigation',
  'dev.widgets.onboarding': 'Onboarding',
  'dev.sample.fieldLabel': 'Full name',
  'dev.sample.fieldHint': 'As on your NIDA card',
  'dev.sample.fieldError': 'Enter your full name',
  'dev.sample.note': 'We check every document before a listing goes live.',
  'dev.sample.home': 'Masaki 3-bedroom apartment',
  'dev.sample.enquiry': 'New enquiry',
  'dev.sample.live': 'Live',
  'dev.sample.pending': 'Waiting for review',
  'dev.sample.rejected': 'Rejected',
  'dev.sample.paid': 'Paid',

  // --- roles (partner roles T07) --------------------------------------------
  'role.customer': 'Customer',
  'role.broker': 'Broker',
  'role.landlord': 'Landlord',
  'role.customer.summary': 'Find a home, enquire and pay',
  'role.broker.summary': 'Your listings, enquiries and earnings',
  'role.landlord.summary': 'Your homes, tenants and rent',
  'role.status.applied': 'Setup not finished',
  'role.status.pendingReview': 'Under review',
  'role.status.actionNeeded': 'Action needed',
  'roleUse.title': 'How will you use HomeMate?',
  'roleUse.subtitle': 'Pick one to start. You can add another later from your profile.',
  'roleUse.customer.title': 'Find a home to rent',
  'roleUse.customer.body': 'Browse, enquire and pay in the app',
  'roleUse.broker.title': 'List homes I know',
  'roleUse.broker.body': 'As a broker (dalali) — earn from every home you let',
  'roleUse.landlord.title': 'Let my own home',
  'roleUse.landlord.body': 'As a landlord — find tenants and get your rent in full',
  'roleUse.note': 'Whatever you pick, you can always search for homes too.',
  'chooseRole.title': 'Welcome back, {name}',
  'chooseRole.titleNoName': 'Welcome back',
  'chooseRole.subtitle': 'You use HomeMate in more than one way. Where would you like to start?',
  'chooseRole.always': 'Always open as {role} on this phone',
  'chooseRole.hint': 'Switch any time from your profile — no need to sign in again.',
  'chooseRole.continueAs': 'Continue as {role}',
  'switchRole.title': 'Switch role',
  'switchRole.subtitle': 'Signed in as {phone}. Same account, same PIN.',
  'switchRole.current': 'You are here',
  'switchRole.note': 'Each role has its own home screen, menu and notifications. Your favourites and enquiries stay in the Customer role.',
  'earn.section': 'Work with HomeMate',
  'earn.title': 'Earn with HomeMate',
  'earn.entryBody': 'List your own home as a landlord, or homes you know as a broker. Same account, same PIN.',
  'earn.subtitle': 'Your partner role is added to the account you already have — same phone number, same PIN.',
  'earn.broker.title': 'Broker (dalali)',
  'earn.broker.body': 'You find homes and tenants yourself',
  'earn.broker.point1': 'List the homes you know',
  'earn.broker.point2': 'Reply to enquiries and accept tenants in the app',
  'earn.broker.point3': 'Keep 90% of the tenant fee on every home you let',
  'earn.landlord.body': 'You own homes and want tenants',
  'earn.landlord.point1': 'List your homes yourself, or let your broker do it',
  'earn.landlord.point2': 'Tenants pay rent in the app and it comes to you',
  'earn.landlord.point3': 'See every tenancy, payment and lease in one place',
  'earn.note': 'You will need your National ID or passport, a selfie and a mobile money or bank account. Landlords also add proof of ownership: a title deed or a utility bill.',
  'earn.alreadyHeld': 'Already on your account',
  'partner.comingSoon': 'This part of your {role} workspace is on its way.',
  'partner.signOut': 'Sign out',
  'partner.status.applied': 'Finish setting up your {role} account to start.',
  'partner.status.pendingReview': 'We are checking your details. We will let you know when your {role} account is verified.',
  'partner.status.actionNeeded': 'We need something more from you before your {role} account is verified.',
  'landlordConfirm.title': 'Confirm your home',
  'landlordConfirm.body': 'A broker listed a home in your name. Check it here before it goes live.',

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

  // --- app updates ----------------------------------------------------------
  'update.available': 'A new version of HomeMate is available.',
  'update.downloading': 'Downloading the new version…',
  'update.ready': 'The new version is ready.',
  'update.action.update': 'Update',
  'update.action.restart': 'Restart',
  'update.action.reload': 'Reload',

  // --- install the web app --------------------------------------------------
  'install.cardTitle': 'Install HomeMate',
  'install.cardBody': 'Add HomeMate to your home screen. It opens full screen, like any other app.',
  'install.action': 'Install',
  'install.notNow': 'Not now',
  'install.profileItem': 'Install the app',
  'install.installed': 'HomeMate is on your home screen.',
  'install.ios.title': 'Add HomeMate to your Home Screen',
  'install.ios.step1': 'Tap the Share button in Safari: the square with an arrow pointing up.',
  'install.ios.step2': 'Scroll down and tap "Add to Home Screen".',
  'install.ios.step3': 'Tap "Add". HomeMate appears with your other apps.',
  'install.menu.title': 'Install HomeMate',
  'install.menu.step1': 'Open your browser menu: ⋮ or ☰, usually at the top or bottom.',
  'install.menu.step2': 'Tap "Install app" or "Add to Home screen".',
  'install.menu.step3': 'Confirm. HomeMate appears with your other apps.',
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
  'common.optional': 'Si lazima',
  'common.back': 'Rudi',
  'common.stepOf': 'Hatua {current} kati ya {total}',

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
  'nav.listings': 'Matangazo',
  'nav.enquiries': 'Maulizo',
  'nav.earnings': 'Mapato',
  'nav.homes': 'Nyumba',
  'nav.tenants': 'Wapangaji',
  'nav.money': 'Pesa',

  // --- widget catalogue (debug only) -----------------------------------------
  'dev.widgets.title': 'Katalogi ya vipengele',
  'dev.widgets.buttons': 'Vitufe',
  'dev.widgets.badges': 'Beji',
  'dev.widgets.forms': 'Fomu',
  'dev.widgets.feedback': 'Taarifa',
  'dev.widgets.data': 'Safu na orodha',
  'dev.widgets.partner': 'Washirika',
  'dev.widgets.timeline': 'Hatua',
  'dev.widgets.navigation': 'Urambazaji',
  'dev.widgets.onboarding': 'Utangulizi',
  'dev.sample.fieldLabel': 'Jina kamili',
  'dev.sample.fieldHint': 'Kama lilivyo kwenye kitambulisho cha NIDA',
  'dev.sample.fieldError': 'Andika jina lako kamili',
  'dev.sample.note': 'Tunakagua kila hati kabla tangazo halijaonekana hewani.',
  'dev.sample.home': 'Nyumba ya vyumba 3, Masaki',
  'dev.sample.enquiry': 'Ulizo jipya',
  'dev.sample.live': 'Hewani',
  'dev.sample.pending': 'Inasubiri ukaguzi',
  'dev.sample.rejected': 'Imekataliwa',
  'dev.sample.paid': 'Imelipwa',

  // --- roles (partner roles T07) --------------------------------------------
  'role.customer': 'Mteja',
  'role.broker': 'Dalali',
  'role.landlord': 'Mwenye nyumba',
  'role.customer.summary': 'Tafuta nyumba, uliza na ulipe',
  'role.broker.summary': 'Matangazo yako, maulizo na mapato',
  'role.landlord.summary': 'Nyumba zako, wapangaji na kodi',
  'role.status.applied': 'Usajili haujakamilika',
  'role.status.pendingReview': 'Inakaguliwa',
  'role.status.actionNeeded': 'Hatua inahitajika',
  'roleUse.title': 'Utatumiaje HomeMate?',
  'roleUse.subtitle': 'Chagua kimoja kuanza. Unaweza kuongeza kingine baadaye kwenye wasifu wako.',
  'roleUse.customer.title': 'Tafuta nyumba ya kupanga',
  'roleUse.customer.body': 'Tazama, uliza na ulipe ndani ya programu',
  'roleUse.broker.title': 'Tangaza nyumba ninazozijua',
  'roleUse.broker.body': 'Kama dalali — pata kipato kwa kila nyumba unayopangisha',
  'roleUse.landlord.title': 'Pangisha nyumba yangu',
  'roleUse.landlord.body': 'Kama mwenye nyumba — pata wapangaji na upokee kodi yako yote',
  'roleUse.note': 'Chochote utakachochagua, bado unaweza kutafuta nyumba pia.',
  'chooseRole.title': 'Karibu tena, {name}',
  'chooseRole.titleNoName': 'Karibu tena',
  'chooseRole.subtitle': 'Unatumia HomeMate kwa njia zaidi ya moja. Ungependa kuanzia wapi?',
  'chooseRole.always': 'Fungua kama {role} kila mara kwenye simu hii',
  'chooseRole.hint': 'Badilisha wakati wowote kwenye wasifu wako — bila kuingia tena.',
  'chooseRole.continueAs': 'Endelea kama {role}',
  'switchRole.title': 'Badilisha jukumu',
  'switchRole.subtitle': 'Umeingia kama {phone}. Akaunti ileile, PIN ileile.',
  'switchRole.current': 'Uko hapa',
  'switchRole.note': 'Kila jukumu lina skrini yake ya mwanzo, menyu na taarifa. Vipendwa na maulizo yako hubaki kwenye jukumu la Mteja.',
  'earn.section': 'Fanya kazi na HomeMate',
  'earn.title': 'Pata kipato na HomeMate',
  'earn.entryBody': 'Tangaza nyumba yako kama mwenye nyumba, au nyumba unazozijua kama dalali. Akaunti ileile, PIN ileile.',
  'earn.subtitle': 'Jukumu lako la ushirika linaongezwa kwenye akaunti uliyonayo — namba ileile ya simu, PIN ileile.',
  'earn.broker.title': 'Dalali',
  'earn.broker.body': 'Unatafuta nyumba na wapangaji mwenyewe',
  'earn.broker.point1': 'Tangaza nyumba unazozijua',
  'earn.broker.point2': 'Jibu maulizo na ukubali wapangaji ndani ya programu',
  'earn.broker.point3': 'Baki na 90% ya ada ya mpangaji kwa kila nyumba unayopangisha',
  'earn.landlord.body': 'Unamiliki nyumba na unataka wapangaji',
  'earn.landlord.point1': 'Tangaza nyumba zako mwenyewe, au mwachie dalali wako afanye hivyo',
  'earn.landlord.point2': 'Wapangaji hulipa kodi ndani ya programu nayo inakufikia wewe',
  'earn.landlord.point3': 'Ona kila upangaji, malipo na mkataba mahali pamoja',
  'earn.note': 'Utahitaji kitambulisho cha Taifa au pasipoti, picha ya uso na akaunti ya pesa kwa simu au ya benki. Wenye nyumba pia huongeza uthibitisho wa umiliki: hati ya kiwanja au bili ya huduma.',
  'earn.alreadyHeld': 'Tayari kwenye akaunti yako',
  'partner.comingSoon': 'Sehemu hii ya eneo lako la {role} inakuja hivi karibuni.',
  'partner.signOut': 'Toka',
  'partner.status.applied': 'Kamilisha usajili wa akaunti yako ya {role} ili uanze.',
  'partner.status.pendingReview': 'Tunakagua taarifa zako. Tutakujulisha akaunti yako ya {role} itakapothibitishwa.',
  'partner.status.actionNeeded': 'Tunahitaji kitu zaidi kutoka kwako kabla akaunti yako ya {role} kuthibitishwa.',
  'landlordConfirm.title': 'Thibitisha nyumba yako',
  'landlordConfirm.body': 'Dalali ametangaza nyumba kwa jina lako. Iangalie hapa kabla haijaonekana hewani.',

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

  // --- app updates ----------------------------------------------------------
  'update.available': 'Toleo jipya la HomeMate linapatikana.',
  'update.downloading': 'Inapakua toleo jipya…',
  'update.ready': 'Toleo jipya liko tayari.',
  'update.action.update': 'Sasisha',
  'update.action.restart': 'Anzisha upya',
  'update.action.reload': 'Pakia upya',

  // --- install the web app --------------------------------------------------
  'install.cardTitle': 'Sakinisha HomeMate',
  'install.cardBody': 'Weka HomeMate kwenye skrini yako ya mwanzo. Itafunguka skrini nzima, kama programu nyingine.',
  'install.action': 'Sakinisha',
  'install.notNow': 'Si sasa',
  'install.profileItem': 'Sakinisha programu',
  'install.installed': 'HomeMate iko kwenye skrini yako ya mwanzo.',
  'install.ios.title': 'Weka HomeMate kwenye skrini ya mwanzo',
  'install.ios.step1': 'Gusa kitufe cha Shiriki kwenye Safari: mraba wenye mshale unaoelekea juu.',
  'install.ios.step2': 'Sogeza chini kisha gusa "Add to Home Screen".',
  'install.ios.step3': 'Gusa "Add". HomeMate itaonekana pamoja na programu zako nyingine.',
  'install.menu.title': 'Sakinisha HomeMate',
  'install.menu.step1': 'Fungua menyu ya kivinjari chako: ⋮ au ☰, mara nyingi juu au chini.',
  'install.menu.step2': 'Gusa "Install app" au "Add to Home screen".',
  'install.menu.step3': 'Thibitisha. HomeMate itaonekana pamoja na programu zako nyingine.',
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
