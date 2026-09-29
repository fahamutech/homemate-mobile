import 'package:flutter/widgets.dart';

import 'app_locale.dart';
import 'translations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

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

  /// A phrase that may not exist: the words for a code the server sent, or
  /// null when the catalogue has none, so the caller can fall back.
  String? _maybe(String key) => kTranslations[locale]?[key] ?? kTranslations[AppLocale.english]?[key];

  /// The words for a status / frequency / purpose code, if the catalogue has
  /// them. Use `statusLabel()`, which falls back to readable English.
  String? status(String code) => _maybe('status.$code');

  /// The name of a reference-data item (property type, amenity) by its code,
  /// if the catalogue has one. Use `referenceName()`, which falls back to the
  /// server's name.
  String? reference(String code) => _maybe('ref.$code');

  /// The same, found by the server's English name for a seeded item.
  String? referenceNamed(String english) {
    for (final entry in kTranslations[AppLocale.english]!.entries) {
      if (entry.key.startsWith('ref.') && entry.value == english) return _maybe(entry.key);
    }
    return null;
  }

  /// A count phrase: `$key.one` when [count] is exactly one, else [key].
  String _plural(String key, Object count) {
    final one = count is num ? count == 1 : '$count' == '1';
    final singular = '$key.one';
    final hasSingular = kTranslations[locale]?[singular] != null || kTranslations[AppLocale.english]?[singular] != null;
    return _s(one && hasSingular ? singular : key, {'count': count});
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
  String get optional => _s('common.optional');
  String get back => _s('common.back');
  String stepOf(int current, int total) => _s('common.stepOf', {'current': current, 'total': total});

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
  String get onboardingEnquireTitle => _s('onboarding.enquire.title');
  String get onboardingEnquireBody => _s('onboarding.enquire.body');
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
  String get navListings => _s('nav.listings');
  String get navEnquiries => _s('nav.enquiries');
  String get navEarnings => _s('nav.earnings');
  String get navHomes => _s('nav.homes');
  String get navTenants => _s('nav.tenants');
  String get navMoney => _s('nav.money');

  // --- widget catalogue (debug only) -----------------------------------------
  String get devWidgetsTitle => _s('dev.widgets.title');
  String get devWidgetsButtons => _s('dev.widgets.buttons');
  String get devWidgetsBadges => _s('dev.widgets.badges');
  String get devWidgetsForms => _s('dev.widgets.forms');
  String get devWidgetsFeedback => _s('dev.widgets.feedback');
  String get devWidgetsData => _s('dev.widgets.data');
  String get devWidgetsPartner => _s('dev.widgets.partner');
  String get devWidgetsTimeline => _s('dev.widgets.timeline');
  String get devWidgetsNavigation => _s('dev.widgets.navigation');
  String get devWidgetsOnboarding => _s('dev.widgets.onboarding');
  String get devSampleFieldLabel => _s('dev.sample.fieldLabel');
  String get devSampleFieldHint => _s('dev.sample.fieldHint');
  String get devSampleFieldError => _s('dev.sample.fieldError');
  String get devSampleNote => _s('dev.sample.note');
  String get devSampleHome => _s('dev.sample.home');
  String get devSampleEnquiry => _s('dev.sample.enquiry');
  String get devSampleLive => _s('dev.sample.live');
  String get devSamplePending => _s('dev.sample.pending');
  String get devSampleRejected => _s('dev.sample.rejected');
  String get devSamplePaid => _s('dev.sample.paid');

  // --- roles (partner roles T07) --------------------------------------------
  String get roleCustomer => _s('role.customer');
  String get roleBroker => _s('role.broker');
  String get roleLandlord => _s('role.landlord');
  String get roleCustomerSummary => _s('role.customer.summary');
  String get roleBrokerSummary => _s('role.broker.summary');
  String get roleLandlordSummary => _s('role.landlord.summary');
  String get roleStatusApplied => _s('role.status.applied');
  String get roleStatusPendingReview => _s('role.status.pendingReview');
  String get roleStatusActionNeeded => _s('role.status.actionNeeded');
  String get roleUseTitle => _s('roleUse.title');
  String get roleUseSubtitle => _s('roleUse.subtitle');
  String get roleUseCustomerTitle => _s('roleUse.customer.title');
  String get roleUseCustomerBody => _s('roleUse.customer.body');
  String get roleUseBrokerTitle => _s('roleUse.broker.title');
  String get roleUseBrokerBody => _s('roleUse.broker.body');
  String get roleUseLandlordTitle => _s('roleUse.landlord.title');
  String get roleUseLandlordBody => _s('roleUse.landlord.body');
  String get roleUseNote => _s('roleUse.note');
  String chooseRoleTitle(String name) => _s('chooseRole.title', {'name': name});
  String get chooseRoleTitleNoName => _s('chooseRole.titleNoName');
  String get chooseRoleSubtitle => _s('chooseRole.subtitle');
  String chooseRoleAlways(String role) => _s('chooseRole.always', {'role': role});
  String get chooseRoleHint => _s('chooseRole.hint');
  String chooseRoleContinueAs(String role) => _s('chooseRole.continueAs', {'role': role});
  String get switchRoleTitle => _s('switchRole.title');
  String switchRoleSubtitle(String phone) => _s('switchRole.subtitle', {'phone': phone});
  String get switchRoleCurrent => _s('switchRole.current');
  String get switchRoleNote => _s('switchRole.note');
  String get earnSection => _s('earn.section');
  String get earnTitle => _s('earn.title');
  String get earnEntryBody => _s('earn.entryBody');
  String get earnSubtitle => _s('earn.subtitle');
  String get earnBrokerTitle => _s('earn.broker.title');
  String get earnBrokerBody => _s('earn.broker.body');
  String get earnBrokerPoint1 => _s('earn.broker.point1');
  String get earnBrokerPoint2 => _s('earn.broker.point2');
  String get earnBrokerPoint3 => _s('earn.broker.point3');
  String get earnLandlordBody => _s('earn.landlord.body');
  String get earnLandlordPoint1 => _s('earn.landlord.point1');
  String get earnLandlordPoint2 => _s('earn.landlord.point2');
  String get earnLandlordPoint3 => _s('earn.landlord.point3');
  String get earnNote => _s('earn.note');
  String get earnAlreadyHeld => _s('earn.alreadyHeld');
  String get partnerSignOut => _s('partner.signOut');
  String partnerStatusApplied(String role) => _s('partner.status.applied', {'role': role});
  String partnerStatusActionNeeded(String role) => _s('partner.status.actionNeeded', {'role': role});
  String get landlordConfirmTitle => _s('landlordConfirm.title');
  String get landlordConfirmBody => _s('landlordConfirm.body');

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

  // --- app updates ----------------------------------------------------------
  String get updateAvailable => _s('update.available');
  String get updateDownloading => _s('update.downloading');
  String get updateReady => _s('update.ready');
  String get updateAction => _s('update.action.update');
  String get updateRestart => _s('update.action.restart');
  String get updateReload => _s('update.action.reload');

  // --- install the web app --------------------------------------------------
  String get installCardTitle => _s('install.cardTitle');
  String get installCardBody => _s('install.cardBody');
  String get installAction => _s('install.action');
  String get installNotNow => _s('install.notNow');
  String get installProfileItem => _s('install.profileItem');
  String get installInstalled => _s('install.installed');
  String get installIosTitle => _s('install.ios.title');
  List<String> get installIosSteps =>
      [_s('install.ios.step1'), _s('install.ios.step2'), _s('install.ios.step3')];
  String get installMenuTitle => _s('install.menu.title');
  List<String> get installMenuSteps =>
      [_s('install.menu.step1'), _s('install.menu.step2'), _s('install.menu.step3')];

  // --- partner setup (T09/T10) -----------------------------------------------
  String get brokerIntro1Title => _s('broker.intro1.title');
  String get brokerIntro1Body => _s('broker.intro1.body');
  String get brokerIntro2Title => _s('broker.intro2.title');
  String get brokerIntro2Body => _s('broker.intro2.body');
  String get brokerIntro3Title => _s('broker.intro3.title');
  String get brokerIntro3Body => _s('broker.intro3.body');
  String get brokerIntroStart => _s('broker.intro.start');
  String partnerSetupTitle(Object role) => _s('partner.setupTitle', {'role': role});
  String partnerStepLabel(Object step, Object name) => _s('partner.stepLabel', {'step': step, 'name': name});
  String get partnerStepDetails => _s('partner.step.details');
  String get partnerStepIdentity => _s('partner.step.identity');
  String get partnerStepOwnership => _s('partner.step.ownership');
  String get partnerStepPayout => _s('partner.step.payout');
  String get partnerDetailsIntro => _s('partner.details.intro');
  String get partnerDetailsFullName => _s('partner.details.fullName');
  String get partnerDetailsFullNameHint => _s('partner.details.fullNameHint');
  String get partnerDetailsPhone => _s('partner.details.phone');
  String get partnerDetailsPhoneHint => _s('partner.details.phoneHint');
  String get partnerDetailsDob => _s('partner.details.dob');
  String get partnerDetailsNida => _s('partner.details.nida');
  String get partnerDetailsTin => _s('partner.details.tin');
  String get partnerDetailsAddress => _s('partner.details.address');
  String get partnerDetailsRequired => _s('partner.details.required');
  String get partnerIdentityTitle => _s('partner.identity.title');
  String get partnerIdentityBody => _s('partner.identity.body');
  String get partnerIdentityCarried => _s('partner.identity.carried');
  String get partnerIdentityLater => _s('partner.identity.later');
  String get partnerOwnershipTitle => _s('partner.ownership.title');
  String get partnerOwnershipBody => _s('partner.ownership.body');
  String get partnerDocIdTitle => _s('partner.doc.id.title');
  String get partnerDocIdBody => _s('partner.doc.id.body');
  String get partnerDocSelfieTitle => _s('partner.doc.selfie.title');
  String get partnerDocSelfieBody => _s('partner.doc.selfie.body');
  String get partnerDocTinTitle => _s('partner.doc.tin.title');
  String get partnerDocTinBody => _s('partner.doc.tin.body');
  String get partnerDocLicenceTitle => _s('partner.doc.licence.title');
  String get partnerDocLicenceBody => _s('partner.doc.licence.body');
  String get partnerDocTitleDeedTitle => _s('partner.doc.titleDeed.title');
  String get partnerDocTitleDeedBody => _s('partner.doc.titleDeed.body');
  String get partnerDocUtilityBillTitle => _s('partner.doc.utilityBill.title');
  String get partnerDocUtilityBillBody => _s('partner.doc.utilityBill.body');
  String get partnerDocVerified => _s('partner.doc.verified');
  String get partnerDocNeeded => _s('partner.doc.needed');
  String get partnerDocInReview => _s('partner.doc.inReview');
  String get partnerDocRejected => _s('partner.doc.rejected');
  String get partnerDocTakePhoto => _s('partner.doc.takePhoto');
  String get partnerDocUpload => _s('partner.doc.upload');
  String get partnerDocReplace => _s('partner.doc.replace');
  String partnerDocSent(Object document) => _s('partner.doc.sent', {'document': document});
  String get partnerPayoutTitle => _s('partner.payout.title');
  String get partnerPayoutPayMeBy => _s('partner.payout.payMeBy');
  String get partnerPayoutMobile => _s('partner.payout.mobile');
  String get partnerPayoutBank => _s('partner.payout.bank');
  String get partnerPayoutProvider => _s('partner.payout.provider');
  String get partnerPayoutBankName => _s('partner.payout.bankName');
  String get partnerPayoutMobileNumber => _s('partner.payout.mobileNumber');
  String get partnerPayoutAccountNumber => _s('partner.payout.accountNumber');
  String get partnerPayoutAccountName => _s('partner.payout.accountName');
  String get partnerPayoutAccountNameHint => _s('partner.payout.accountNameHint');
  String get partnerPayoutRequired => _s('partner.payout.required');
  String get partnerExampleTitle => _s('partner.example.title');
  String get partnerExampleRent => _s('partner.example.rent');
  String partnerExampleFee(Object percent) => _s('partner.example.fee', {'percent': percent});
  String partnerExampleShare(Object percent) => _s('partner.example.share', {'percent': percent});
  String get partnerExampleReceive => _s('partner.example.receive');
  String get partnerExampleNote => _s('partner.example.note');
  String get partnerAgree => _s('partner.agree');
  String get partnerAgreeRequired => _s('partner.agreeRequired');
  String get partnerSubmitForReview => _s('partner.submitForReview');
  String partnerMissing(Object steps) => _s('partner.missing', {'steps': steps});
  String partnerAccount(Object role) => _s('partner.account', {'role': role});
  String get partnerReviewTitle => _s('partner.review.title');
  String partnerReviewBody(Object role) => _s('partner.review.body', {'role': role});
  String get partnerReviewDone => _s('partner.review.done');
  String get partnerReviewAccepted => _s('partner.review.accepted');
  String get partnerReviewDocuments => _s('partner.review.documents');
  String get partnerReviewPayout => _s('partner.review.payout');
  String get partnerReviewAgreement => _s('partner.review.agreement');
  String get partnerReviewDraftNote => _s('partner.review.draftNote');
  String get partnerReviewDraftFirst => _s('partner.review.draftFirst');
  String get partnerReviewBackToCustomer => _s('partner.review.backToCustomer');
  String get partnerActionTitle => _s('partner.action.title');
  String get partnerActionBody => _s('partner.action.body');
  String get partnerActionDraftsSafe => _s('partner.action.draftsSafe');
  String get partnerActionUpload => _s('partner.action.upload');
  String get partnerActionNewSelfie => _s('partner.action.newSelfie');
  String get partnerActionResubmit => _s('partner.action.resubmit');
  String get partnerActionEditDetails => _s('partner.action.editDetails');
  String get partnerRejectedTitle => _s('partner.rejected.title');
  String partnerSuspendedTitle(Object role) => _s('partner.suspended.title', {'role': role});
  String get partnerHomeVerifyingTitle => _s('partner.home.verifyingTitle');
  String get partnerHomeVerifyingBody => _s('partner.home.verifyingBody');
  String get partnerHomeSetupTitle => _s('partner.home.setupTitle');
  String get partnerHomeActionTitle => _s('partner.home.actionTitle');
  String get partnerHomeGetStarted => _s('partner.home.getStarted');
  String get partnerCheckDetailsSub => _s('partner.check.detailsSub');
  String get partnerCheckIdentityTitle => _s('partner.check.identityTitle');
  String get partnerCheckIdentityReviewing => _s('partner.check.identityReviewing');
  String get partnerCheckIdentityTodo => _s('partner.check.identityTodo');
  String get partnerCheckPayoutTodo => _s('partner.check.payoutTodo');
  String get partnerCheckFirstHomeTitle => _s('partner.check.firstHomeTitle');
  String get partnerCheckFirstHomeSub => _s('partner.check.firstHomeSub');
  String get partnerHomeDraftListing => _s('partner.home.draftListing');
  String get partnerHomeContinueSetup => _s('partner.home.continueSetup');
  String get partnerHomeEnquiriesEmpty => _s('partner.home.enquiriesEmpty');
  String get brokerHomeLive => _s('broker.home.live');
  String get brokerHomeOpen => _s('broker.home.open');
  String get partnerHomeEarnedThisMonth => _s('partner.home.earnedThisMonth');
  String get partnerHomeNeedsYou => _s('partner.home.needsYou');
  String get partnerHomeNothing => _s('partner.home.nothing');
  String get partnerHomeAddHome => _s('partner.home.addHome');
  String get partnerHomeYourListings => _s('partner.home.yourListings');
  String get partnerNeedsEnquiry => _s('partner.needs.enquiry');
  String get partnerNeedsListingChanges => _s('partner.needs.listingChanges');
  String get partnerNeedsConfirmListing => _s('partner.needs.confirmListing');
  String get partnerNeedsMoveIn => _s('partner.needs.moveIn');
  String get partnerNeedsPaymentChecking => _s('partner.needs.paymentChecking');
  String get partnerNeedsPaymentVerified => _s('partner.needs.paymentVerified');

  // --- listing statuses (T09/T10) --------------------------------------------
  String get listingStatusDraft => _s('listing.status.draft');
  String get listingStatusPendingReview => _s('listing.status.pendingReview');
  String get listingStatusChangesRequested => _s('listing.status.changesRequested');
  String get listingStatusApproved => _s('listing.status.approved');
  String get listingStatusRejected => _s('listing.status.rejected');
  String get listingStatusRented => _s('listing.status.rented');
  String get listingStatusArchived => _s('listing.status.archived');
  String listingOpenEnquiries(Object count) => _plural('listing.openEnquiries', count);
  String listingSent(Object date) => _s('listing.sent', {'date': date});
  String get listingSeeNote => _s('listing.seeNote');
  String listingPerMonth(Object amount) => _s('listing.perMonth', {'amount': amount});

  // --- listings and the add-a-home wizard (T09/T10) --------------------------
  String get listingsTitle => _s('listings.title');
  String get listingsAll => _s('listings.all');
  String get listingsEmpty => _s('listings.empty');
  String get listingsEmptyAll => _s('listings.emptyAll');
  String get listingsAdd => _s('listings.add');
  String get listingChangesTitle => _s('listing.changesTitle');
  String get listingFromReview => _s('listing.fromReview');
  String get listingSummary => _s('listing.summary');
  String get listingRent => _s('listing.rent');
  String listingRentPerMonth(Object amount) => _s('listing.rentPerMonth', {'amount': amount});
  String get listingPaymentMode => _s('listing.paymentMode');
  String get listingDeposit => _s('listing.deposit');
  String listingMonths(Object count) => _plural('listing.months', count);
  String get listingAvailableFrom => _s('listing.availableFrom');
  String get listingLandlord => _s('listing.landlord');
  String get listingHistory => _s('listing.history');
  String get listingHistoryCreated => _s('listing.history.created');
  String get listingHistorySent => _s('listing.history.sent');
  String get listingHistoryChanges => _s('listing.history.changes');
  String get listingHistoryRejected => _s('listing.history.rejected');
  String get listingHistoryLive => _s('listing.history.live');
  String get listingHistoryAfterApproval => _s('listing.history.afterApproval');
  String get listingFixAndResubmit => _s('listing.fixAndResubmit');
  String get listingContinueEditing => _s('listing.continueEditing');
  String get listingArchive => _s('listing.archive');
  String get listingArchiveConfirm => _s('listing.archiveConfirm');
  String get listingArchived => _s('listing.archived');
  String get listingLandlordPending => _s('listing.landlordPending');
  String listingLandlordDisputed(Object reason) => _s('listing.landlordDisputed', {'reason': reason});
  String get frequencyMonthly => _s('frequency.monthly');
  String get frequencyQuarterly => _s('frequency.quarterly');
  String get frequencySemiAnnual => _s('frequency.semiAnnual');
  String get frequencyAnnual => _s('frequency.annual');
  String get frequencyCustom => _s('frequency.custom');
  String frequencyEvery(Object period) => _s('frequency.every', {'period': period});
  String get wizardTitle => _s('wizard.title');
  String get wizardSaveDraft => _s('wizard.saveDraft');
  String get wizardSaved => _s('wizard.saved');
  String get wizardStepBasics => _s('wizard.step.basics');
  String get wizardStepLocation => _s('wizard.step.location');
  String get wizardStepTerms => _s('wizard.step.terms');
  String get wizardStepAmenities => _s('wizard.step.amenities');
  String get wizardStepLandlord => _s('wizard.step.landlord');
  String get wizardStepPhotos => _s('wizard.step.photos');
  String get wizardTitleField => _s('wizard.titleField');
  String get wizardTitleHint => _s('wizard.titleHint');
  String get wizardTitleRequired => _s('wizard.titleRequired');
  String get wizardDescription => _s('wizard.description');
  String get wizardPropertyType => _s('wizard.propertyType');
  String get wizardBedrooms => _s('wizard.bedrooms');
  String get wizardBathrooms => _s('wizard.bathrooms');
  String get wizardSize => _s('wizard.size');
  String get wizardSizeHint => _s('wizard.sizeHint');
  String get wizardFurnishing => _s('wizard.furnishing');
  String get wizardFurnishingNone => _s('wizard.furnishing.none');
  String get wizardFurnishingSemi => _s('wizard.furnishing.semi');
  String get wizardFurnishingFully => _s('wizard.furnishing.fully');
  String get wizardRegion => _s('wizard.region');
  String get wizardDistrict => _s('wizard.district');
  String get wizardWard => _s('wizard.ward');
  String get wizardStreet => _s('wizard.street');
  String get wizardPinHint => _s('wizard.pinHint');
  String get wizardUseLocation => _s('wizard.useLocation');
  String get wizardPinNote => _s('wizard.pinNote');
  String get wizardPinSet => _s('wizard.pinSet');
  String get wizardMonthlyRent => _s('wizard.monthlyRent');
  String get wizardPaysEvery => _s('wizard.paysEvery');
  String get wizardCustomMonths => _s('wizard.customMonths');
  String get wizardDepositMonths => _s('wizard.depositMonths');
  String get wizardAdvanceMonths => _s('wizard.advanceMonths');
  String get wizardMinLease => _s('wizard.minLease');
  String get wizardNotice => _s('wizard.notice');
  String get wizardMoveInTitle => _s('wizard.moveIn.title');
  String get wizardMoveInFirstRent => _s('wizard.moveIn.firstRent');
  String get wizardMoveInAdvance => _s('wizard.moveIn.advance');
  String get wizardMoveInDeposit => _s('wizard.moveIn.deposit');
  String wizardMoveInFee(Object percent) => _s('wizard.moveIn.fee', {'percent': percent});
  String get wizardMoveInTotal => _s('wizard.moveIn.total');
  String wizardYouEarn(Object amount) => _s('wizard.youEarn', {'amount': amount});
  String get wizardRentRequired => _s('wizard.rentRequired');
  String get wizardAmenities => _s('wizard.amenities');
  String get wizardHouseRules => _s('wizard.houseRules');
  String get wizardPets => _s('wizard.pets');
  String get wizardSmoking => _s('wizard.smoking');
  String get wizardMaxOccupants => _s('wizard.maxOccupants');
  String get wizardCharges => _s('wizard.charges');
  String get wizardChargesHint => _s('wizard.chargesHint');
  String get wizardAddCharge => _s('wizard.addCharge');
  String get wizardChargeName => _s('wizard.chargeName');
  String get wizardChargeAmount => _s('wizard.chargeAmount');
  String get wizardChargeRequired => _s('wizard.chargeRequired');
  String get wizardRemoveCharge => _s('wizard.removeCharge');
  String get wizardLandlordTitle => _s('wizard.landlord.title');
  String get wizardLandlordBody => _s('wizard.landlord.body');
  String get wizardLandlordPhone => _s('wizard.landlord.phone');
  String get wizardLandlordFind => _s('wizard.landlord.find');
  String wizardLandlordOnHomeMate(Object count) => _s('wizard.landlord.onHomeMate', {'count': count});
  String get wizardLandlordInvited => _s('wizard.landlord.invited');
  String get wizardLandlordNotFound => _s('wizard.landlord.notFound');
  String get wizardLandlordName => _s('wizard.landlord.name');
  String get wizardLandlordInvite => _s('wizard.landlord.invite');
  String get wizardLandlordRequired => _s('wizard.landlord.required');
  String get wizardLandlordCredit => _s('wizard.landlord.credit');
  String get wizardLandlordListedBy => _s('wizard.landlord.listedBy');
  String wizardLandlordYou(Object name) => _s('wizard.landlord.you', {'name': name});
  String get wizardLandlordLock => _s('wizard.landlord.lock');
  String get wizardPhotosTitle => _s('wizard.photos.title');
  String get wizardPhotosBody => _s('wizard.photos.body');
  String get wizardPhotosCover => _s('wizard.photos.cover');
  String get wizardPhotosAdd => _s('wizard.photos.add');
  String get wizardPhotosHint => _s('wizard.photos.hint');
  String get wizardPhotosMakeCover => _s('wizard.photos.makeCover');
  String get wizardPhotosEarlier => _s('wizard.photos.earlier');
  String get wizardPhotosLater => _s('wizard.photos.later');
  String get wizardPhotosRemove => _s('wizard.photos.remove');
  String wizardPhotosUploading(Object done, Object total) => _s('wizard.photos.uploading', {'done': done, 'total': total});
  String get wizardReview => _s('wizard.review');
  String get wizardReviewTitle => _s('wizard.review.title');
  String get wizardEdit => _s('wizard.edit');
  String wizardReviewBasics(Object type, Object bedrooms, Object bathrooms) => _s('wizard.review.basics', {'type': type, 'bedrooms': bedrooms, 'bathrooms': bathrooms});
  String get wizardReviewPinSet => _s('wizard.review.pinSet');
  String get wizardReviewNoPin => _s('wizard.review.noPin');
  String wizardReviewTerms(Object period, Object deposit) => _s('wizard.review.terms', {'period': period, 'deposit': deposit});
  String wizardReviewAmenities(Object amenities, Object charges) => _s('wizard.review.amenities', {'amenities': amenities, 'charges': charges});
  String wizardReviewPhotos(Object count) => _s('wizard.review.photos', {'count': count});
  String get wizardReviewMissing => _s('wizard.review.missing');
  String get wizardReviewWhenLet => _s('wizard.review.whenLet');
  String wizardReviewYouEarn(Object amount) => _s('wizard.review.youEarn', {'amount': amount});
  String wizardReviewFeeLine(Object fee) => _s('wizard.review.feeLine', {'fee': fee});
  String get wizardReviewRentLine => _s('wizard.review.rentLine');
  String get wizardSend => _s('wizard.send');
  String get wizardSendNote => _s('wizard.sendNote');
  String get wizardCannotSend => _s('wizard.cannotSend');
  String get wizardSentTitle => _s('wizard.sent.title');
  String get wizardSentBody => _s('wizard.sent.body');
  String get wizardSentAnother => _s('wizard.sent.another');
  String get wizardSentListings => _s('wizard.sent.listings');

  // --- enquiries, money, partner profile (T09/T10) ---------------------------
  String get enquiriesTitle => _s('enquiries.title');
  String get enquiriesTabNew => _s('enquiries.tab.new');
  String get enquiriesTabReplied => _s('enquiries.tab.replied');
  String get enquiriesTabAccepted => _s('enquiries.tab.accepted');
  String get enquiriesTabClosed => _s('enquiries.tab.closed');
  String get enquiriesEmpty => _s('enquiries.empty');
  String enquiriesPrefers(Object channel) => _s('enquiries.prefers', {'channel': channel});
  String get enquiriesChannelWhatsapp => _s('enquiries.channel.whatsapp');
  String get enquiriesChannelCall => _s('enquiries.channel.call');
  String get enquiriesChannelSms => _s('enquiries.channel.sms');
  String enquiriesMoveIn(Object date) => _s('enquiries.moveIn', {'date': date});
  String enquiriesPeople(Object count) => _plural('enquiries.people', count);
  String enquiriesBudget(Object amount) => _s('enquiries.budget', {'amount': amount});
  String get enquiriesReply => _s('enquiries.reply');
  String get enquiriesOpen => _s('enquiries.open');
  String get enquiriesCall => _s('enquiries.call');
  String get enquiriesWhatsapp => _s('enquiries.whatsapp');
  String get enquiryTitle => _s('enquiry.title');
  String get enquiryIdVerified => _s('enquiry.idVerified');
  String get enquiryMoveIn => _s('enquiry.moveIn');
  String get enquiryPeople => _s('enquiry.people');
  String get enquiryBudget => _s('enquiry.budget');
  String get enquiryBestTime => _s('enquiry.bestTime');
  String get enquiryNext => _s('enquiry.next');
  String get enquiryOutcomeReply => _s('enquiry.outcome.reply');
  String get enquiryOutcomeReplyBody => _s('enquiry.outcome.replyBody');
  String get enquiryOutcomeAccept => _s('enquiry.outcome.accept');
  String enquiryOutcomeAcceptBody(Object name) => _s('enquiry.outcome.acceptBody', {'name': name});
  String get enquiryOutcomeDecline => _s('enquiry.outcome.decline');
  String enquiryOutcomeDeclineBody(Object name) => _s('enquiry.outcome.declineBody', {'name': name});
  String get enquiryOutcomeClose => _s('enquiry.outcome.close');
  String get enquiryYourReply => _s('enquiry.yourReply');
  String get enquiryReplyRequired => _s('enquiry.replyRequired');
  String get enquirySendReply => _s('enquiry.send.reply');
  String get enquirySendAccept => _s('enquiry.send.accept');
  String get enquirySendDecline => _s('enquiry.send.decline');
  String get enquirySendClose => _s('enquiry.send.close');
  String get enquiryReadOnly => _s('enquiry.readOnly');
  String get enquiryAnswered => _s('enquiry.answered');
  String get enquirySent => _s('enquiry.sent');
  String get declineTitle => _s('decline.title');
  String declineBody(Object name) => _s('decline.body', {'name': name});
  String get declineReason => _s('decline.reason');
  String get declineRequired => _s('decline.required');
  String get declineQuickUnavailable => _s('decline.quick.unavailable');
  String get declineQuickDate => _s('decline.quick.date');
  String get declineQuickBudget => _s('decline.quick.budget');
  String get declineQuickPeople => _s('decline.quick.people');
  String get declineConfirm => _s('decline.confirm');
  String get journeyTitle => _s('journey.title');
  String journeyCustomerPays(Object name) => _s('journey.customerPays', {'name': name});
  String get journeyFirstRent => _s('journey.firstRent');
  String get journeyAdvance => _s('journey.advance');
  String get journeyDeposit => _s('journey.deposit');
  String journeyFee(Object percent) => _s('journey.fee', {'percent': percent});
  String get journeyTotal => _s('journey.total');
  String get journeyYourEarning => _s('journey.yourEarning');
  String journeyHold(Object name) => _s('journey.hold', {'name': name});
  String journeyWhatsappName(Object name) => _s('journey.whatsappName', {'name': name});
  String journeyStepEnquiryReceived(Object name) => _s('journey.step.enquiry_received', {'name': name});
  String get journeyStepDecision => _s('journey.step.decision');
  String journeyStepAwaitingPayment(Object name) => _s('journey.step.awaiting_payment', {'name': name});
  String get journeyStepPaymentVerified => _s('journey.step.payment_verified');
  String get journeyStepMovedIn => _s('journey.step.moved_in');
  String get journeyStepEnded => _s('journey.step.ended');
  String get earningsTitle => _s('earnings.title');
  String get earningsReady => _s('earnings.ready');
  String earningsNextPayout(Object account) => _s('earnings.nextPayout', {'account': account});
  String get earningsBeingChecked => _s('earnings.beingChecked');
  String earningsPaidThisYear(Object year) => _s('earnings.paidThisYear', {'year': year});
  String get earningsRecent => _s('earnings.recent');
  String get earningsPayouts => _s('earnings.payouts');
  String get earningsEmpty => _s('earnings.empty');
  String get earningsNote => _s('earnings.note');
  String get earningStateBeingChecked => _s('earning.state.being_checked');
  String get earningStateReady => _s('earning.state.ready');
  String get earningStateInPayout => _s('earning.state.in_payout');
  String get earningStatePaid => _s('earning.state.paid');
  String get earningStateOnHold => _s('earning.state.on_hold');
  String get earningStateReversed => _s('earning.state.reversed');
  String get earningStateFailed => _s('earning.state.failed');
  String get earningReadyLong => _s('earning.readyLong');
  String earningFeeLine(Object amount) => _s('earning.feeLine', {'amount': amount});
  String get earningRentLine => _s('earning.rentLine');
  String get earningYours => _s('earning.yours');
  String get earningHow => _s('earning.how');
  String get earningMonthlyRent => _s('earning.monthlyRent');
  String earningFee(Object percent) => _s('earning.fee', {'percent': percent});
  String earningShare(Object percent) => _s('earning.share', {'percent': percent});
  String get earningReceive => _s('earning.receive');
  String get earningRest => _s('earning.rest');
  String get earningToLandlord => _s('earning.toLandlord');
  String get earningToBroker => _s('earning.toBroker');
  String get earningToHomeMate => _s('earning.toHomeMate');
  String get earningRestNote => _s('earning.restNote');
  String get earningTimeline => _s('earning.timeline');
  String earningTimelinePaid(Object name) => _s('earning.timeline.paid', {'name': name});
  String get earningTimelineVerified => _s('earning.timeline.verified');
  String get earningTimelinePayoutCreated => _s('earning.timeline.payout_created');
  String get earningTimelinePaidOut => _s('earning.timeline.paid_out');
  String earningHoldReason(Object reason) => _s('earning.holdReason', {'reason': reason});
  String get payoutsTitle => _s('payouts.title');
  String get payoutsWhere => _s('payouts.where');
  String get payoutsNoAccount => _s('payouts.noAccount');
  String get payoutsEmpty => _s('payouts.empty');
  String get payoutsStatusScheduled => _s('payouts.status.scheduled');
  String get payoutsStatusProcessing => _s('payouts.status.processing');
  String get payoutsStatusPaid => _s('payouts.status.paid');
  String get payoutsStatusOnHold => _s('payouts.status.on_hold');
  String get payoutsStatusFailed => _s('payouts.status.failed');
  String get payoutsStatusCancelled => _s('payouts.status.cancelled');
  String payoutsReceipt(Object reference) => _s('payouts.receipt', {'reference': reference});
  String payoutsTo(Object account) => _s('payouts.to', {'account': account});
  String payoutsOnHold(Object reason) => _s('payouts.onHold', {'reason': reason});
  String get payoutsUpdate => _s('payouts.update');
  String get payoutsNote => _s('payouts.note');
  String get profileYourRoles => _s('profile.yourRoles');
  String profileAccount(Object role) => _s('profile.account', {'role': role});
  String get profileEditDetails => _s('profile.editDetails');
  String get profileIdentity => _s('profile.identity');
  String get profilePayout => _s('profile.payout');
  String get profileAgreement => _s('profile.agreement');
  String get profileAgreementSigned => _s('profile.agreementSigned');
  String get profileNotifications => _s('profile.notifications');
  String get profileHelp => _s('profile.help');
  String get profileHelpBody => _s('profile.helpBody');
  String get profileHomesLet => _s('profile.homesLet');
  String profileEarnedYear(Object year) => _s('profile.earnedYear', {'year': year});

  // --- Landlord workspace (T10) ----------------------------------------------
  String get landlordIntro1Title => _s('landlordIntro.1.title');
  String get landlordIntro1Body => _s('landlordIntro.1.body');
  String get landlordIntro2Title => _s('landlordIntro.2.title');
  String get landlordIntro2Body => _s('landlordIntro.2.body');
  String get landlordIntro3Title => _s('landlordIntro.3.title');
  String get landlordIntro3Body => _s('landlordIntro.3.body');
  String get landlordIntroStart => _s('landlordIntro.start');
  String get landlordHomeHomes => _s('landlordHome.homes');
  String get landlordHomeLet => _s('landlordHome.let');
  String get landlordHomePaidThisMonth => _s('landlordHome.paidThisMonth');
  String get landlordHomeYourHomes => _s('landlordHome.yourHomes');
  String landlordConfirmListedBy(Object name) => _s('landlordConfirm.listedBy', {'name': name});
  String get landlordConfirmTerms => _s('landlordConfirm.terms');
  String get landlordConfirmRent => _s('landlordConfirm.rent');
  String get landlordConfirmDeposit => _s('landlordConfirm.deposit');
  String landlordConfirmMonths(Object count) => _plural('landlordConfirm.months', count);
  String get landlordConfirmMinLease => _s('landlordConfirm.minLease');
  String get landlordConfirmAvailable => _s('landlordConfirm.available');
  String get landlordConfirmYes => _s('landlordConfirm.yes');
  String get landlordConfirmWrong => _s('landlordConfirm.wrong');
  String get landlordConfirmNote => _s('landlordConfirm.note');
  String get landlordConfirmConfirmed => _s('landlordConfirm.confirmed');
  String get landlordConfirmDisputed => _s('landlordConfirm.disputed');
  String get landlordConfirmNothing => _s('landlordConfirm.nothing');
  String get landlordConfirmSetupBody => _s('landlordConfirm.setupBody');
  String get landlordConfirmContinueSetup => _s('landlordConfirm.continueSetup');
  String get landlordConfirmGoHome => _s('landlordConfirm.goHome');
  String get landlordConfirmDone => _s('landlordConfirm.done');
  String get disputeTitle => _s('dispute.title');
  String get disputeBody => _s('dispute.body');
  String get disputeReason => _s('dispute.reason');
  String get disputeRequired => _s('dispute.required');
  String get disputeQuickNotMine => _s('dispute.quick.notMine');
  String get disputeQuickRent => _s('dispute.quick.rent');
  String get disputeQuickNotAvailable => _s('dispute.quick.notAvailable');
  String get disputeQuickNoBroker => _s('dispute.quick.noBroker');
  String get disputeConfirm => _s('dispute.confirm');
  String get listingListedByYou => _s('listing.listedByYou');
  String listingListedByBroker(Object name) => _s('listing.listedByBroker', {'name': name});
  String get landlordListingBroker => _s('landlordListing.broker');
  String landlordListingBrokerNote(Object name) => _s('landlordListing.brokerNote', {'name': name});
  String get landlordListingConfirmNow => _s('landlordListing.confirmNow');
  String get tenantsTabMovingIn => _s('tenants.tab.movingIn');
  String get tenantsTabCurrent => _s('tenants.tab.current');
  String get tenantsTabPast => _s('tenants.tab.past');
  String get tenantsEmptyMovingIn => _s('tenants.empty.movingIn');
  String get tenantsEmptyCurrent => _s('tenants.empty.current');
  String get tenantsEmptyPast => _s('tenants.empty.past');
  String tenantsMovesIn(Object date) => _s('tenants.movesIn', {'date': date});
  String tenantsNextRent(Object date) => _s('tenants.nextRent', {'date': date});
  String tenantsEnded(Object date) => _s('tenants.ended', {'date': date});
  String tenantsPerMonth(Object amount) => _s('tenants.perMonth', {'amount': amount});
  String get tenancyTitle => _s('tenancy.title');
  String get tenancyPaid => _s('tenancy.paid');
  String get tenancyOutstanding => _s('tenancy.outstanding');
  String get tenancyRent => _s('tenancy.rent');
  String get tenancyDeposit => _s('tenancy.deposit');
  String get tenancyLease => _s('tenancy.lease');
  String tenancyLeaseMonths(Object count) => _plural('tenancy.leaseMonths', count);
  String get tenancyMoveIn => _s('tenancy.moveIn');
  String get tenancyMonthsLeft => _s('tenancy.monthsLeft');
  String get tenancyAgreement => _s('tenancy.agreement');
  String get tenancyPayments => _s('tenancy.payments');
  String get tenancyNoPayments => _s('tenancy.noPayments');
  String get tenancyConfirmMoveIn => _s('tenancy.confirmMoveIn');
  String tenancyMovingInNote(Object name) => _s('tenancy.movingInNote', {'name': name});
  String get tenancyEnd => _s('tenancy.end');
  String get tenancyEndReason => _s('tenancy.endReason');
  String get tenancyStarted => _s('tenancy.started');
  String get tenancyEndedDone => _s('tenancy.endedDone');
  String moveInBody(Object name) => _s('moveIn.body', {'name': name});
  String get moveInDay => _s('moveIn.day');
  String get moveInPick => _s('moveIn.pick');
  String get moveInConfirm => _s('moveIn.confirm');
  String get moveInRequired => _s('moveIn.required');
  String endTenancyBody(Object name) => _s('endTenancy.body', {'name': name});
  String get endTenancyDay => _s('endTenancy.day');
  String get endTenancyRequired => _s('endTenancy.required');
  String get endTenancyReasonHint => _s('endTenancy.reasonHint');
  String get earningsEmptyLandlord => _s('earnings.emptyLandlord');
  String get earningsNoteLandlord => _s('earnings.noteLandlord');

  // --- Lease contract (CUS-012c / LND-033) -----------------------------------
  String get leaseTitle => _s('lease.title');
  String get leaseNotReady => _s('lease.notReady');
  String get leaseParties => _s('lease.parties');
  String get leaseTenant => _s('lease.tenant');
  String get leaseLandlord => _s('lease.landlord');
  String get leaseContact => _s('lease.contact');
  String get leaseProperty => _s('lease.property');
  String get leaseAddress => _s('lease.address');
  String get leaseTerm => _s('lease.term');
  String get leaseType => _s('lease.type');
  String get leaseTypeFixed => _s('lease.type.fixed');
  String get leaseTypePeriodic => _s('lease.type.periodic');
  String get leaseTypeMonthly => _s('lease.type.monthly');
  String get leaseStarts => _s('lease.starts');
  String get leaseEnds => _s('lease.ends');
  String get leaseDuration => _s('lease.duration');
  String get leaseNotice => _s('lease.notice');
  String leaseNoticeDays(Object count) => _plural('lease.noticeDays', count);
  String get leaseMoney => _s('lease.money');
  String get leaseRent => _s('lease.rent');
  String get leaseDeposit => _s('lease.deposit');
  String get leaseBookingRef => _s('lease.bookingRef');
  String get leaseAgreementRef => _s('lease.agreementRef');
  String get leaseTerms => _s('lease.terms');
  String get leaseHouseRules => _s('lease.houseRules');
  String leaseAcceptedOn(Object date) => _s('lease.acceptedOn', {'date': date});
  String leaseAcceptedOnVersion(Object date, Object version) => _s('lease.acceptedOnVersion', {'date': date, 'version': version});
  String get leaseDownload => _s('lease.download');
  String get leasePdfNotReady => _s('lease.pdfNotReady');
  String get leaseOpenFailed => _s('lease.openFailed');

  // --- Forgot PIN (AUTH) -----------------------------------------------------
  String get forgotPinSent => _s('forgotPin.sent');
  String get forgotPinTitle => _s('forgotPin.title');
  String get forgotPinHeading => _s('forgotPin.heading');
  String get forgotPinBody => _s('forgotPin.body');

  // --- Sign-in code (AUTH) ---------------------------------------------------
  String get otpEnterCode => _s('otp.enterCode');
  String get otpResent => _s('otp.resent');
  String get otpTitle => _s('otp.title');
  String get otpHeading => _s('otp.heading');
  String otpSentTo(Object phone) => _s('otp.sentTo', {'phone': phone});
  String get otpVerify => _s('otp.verify');
  String otpResendIn(Object seconds) => _s('otp.resendIn', {'seconds': seconds});
  String get otpSendAnother => _s('otp.sendAnother');

  // --- PIN setup (AUTH) ------------------------------------------------------
  String get pinSetupTitleReset => _s('pinSetup.titleReset');
  String get pinSetupTitle => _s('pinSetup.title');
  String get pinSetupBody => _s('pinSetup.body');
  String get pinSetupNewPin => _s('pinSetup.newPin');
  String get pinSetupConfirmPin => _s('pinSetup.confirmPin');
  String get pinSetupMismatch => _s('pinSetup.mismatch');
  String get pinSetupHint => _s('pinSetup.hint');
  String get pinSetupSaveNew => _s('pinSetup.saveNew');
  String get pinSetupCreate => _s('pinSetup.create');
  String get pinSetupLength => _s('pinSetup.length');
  String get pinSetupPredictable => _s('pinSetup.predictable');

  // --- Errors and shared widgets ---------------------------------------------
  String get errorOffline => _s('error.offline');
  String get errorTimeout => _s('error.timeout');
  String get errorUnexpected => _s('error.unexpected');
  String errorAnnounce(Object message) => _s('error.announce', {'message': message});
  String get commonNothingYet => _s('common.nothingYet');
  String get notFoundMessage => _s('notFound.message');
  String get notFoundGoHome => _s('notFound.goHome');
  String get pinEnter => _s('pin.enter');
  String get pinForgot => _s('pin.forgot');
  String get pinDeleteDigit => _s('pin.deleteDigit');
  String feeTitle(Object amount) => _s('fee.title', {'amount': amount});
  String feeIncludedNow(Object percent) => _s('fee.includedNow', {'percent': percent});
  String feeInFirstPayment(Object percent) => _s('fee.inFirstPayment', {'percent': percent});
  String get feeYouSave => _s('fee.youSave');

  // --- Profile setup (AUTH) --------------------------------------------------
  String get profileSetupTitle => _s('profileSetup.title');
  String get profileSetupBackStep => _s('profileSetup.backStep');
  String get profileSetupSkipForNow => _s('profileSetup.skipForNow');
  String get profileSetupComplete => _s('profileSetup.complete');
  String get profileSetupDobHelp => _s('profileSetup.dobHelp');
  String get photoTake => _s('photo.take');
  String get photoFromGallery => _s('photo.fromGallery');
  String get photoSaved => _s('photo.saved');
  String get profileFieldFullName => _s('profileField.fullName');
  String get profileFieldNameRequired => _s('profileField.nameRequired');
  String get profileFieldNameHint => _s('profileField.nameHint');
  String get profileFieldDob => _s('profileField.dob');
  String get profileFieldDobPlaceholder => _s('profileField.dobPlaceholder');
  String get profileFieldGender => _s('profileField.gender');
  String get genderMale => _s('gender.male');
  String get genderFemale => _s('gender.female');
  String get genderOther => _s('gender.other');
  String get profileFieldPhone => _s('profileField.phone');
  String get profileFieldPhoneHelp => _s('profileField.phoneHelp');
  String get profileFieldEmail => _s('profileField.email');
  String get profileFieldEmailInvalid => _s('profileField.emailInvalid');
  String get profileFieldEmailHelp => _s('profileField.emailHelp');
  String get photoTapToChange => _s('photo.tapToChange');
  String get profileSetupOptionsFailed => _s('profileSetup.optionsFailed');
  String get prefsLocation => _s('prefs.location');
  String get prefsAnywhere => _s('prefs.anywhere');
  String get prefsPropertyType => _s('prefs.propertyType');
  String get prefsBedrooms => _s('prefs.bedrooms');
  String get prefsStudio => _s('prefs.studio');
  String get prefsBudget => _s('prefs.budget');
  String get prefsTimeline => _s('prefs.timeline');
  String get prefsTimelineNow => _s('prefs.timeline.now');
  String get prefsTimelineTwoWeeks => _s('prefs.timeline.twoWeeks');
  String get prefsTimelineMonth => _s('prefs.timeline.month');
  String get prefsTimelineFlexible => _s('prefs.timeline.flexible');
  String get prefsAmenities => _s('prefs.amenities');
  String get prefsAny => _s('prefs.any');
  String get identitySent => _s('identity.sent');
  String get identityPhotographId => _s('identity.photographId');
  String get identityExistingPhoto => _s('identity.existingPhoto');
  String get profileSetupAlmostDone => _s('profileSetup.almostDone');
  String get profileSetupVerifyToUnlock => _s('profileSetup.verifyToUnlock');
  String get identityIdTitle => _s('identity.idTitle');
  String get identityIdSubtitle => _s('identity.idSubtitle');
  String get identityUpload => _s('identity.upload');
  String get identitySelfieTitle => _s('identity.selfieTitle');
  String get identitySelfieSubtitle => _s('identity.selfieSubtitle');
  String get identityTakePhoto => _s('identity.takePhoto');
  String get profileSetupSkipVerification => _s('profileSetup.skipVerification');
  String get profileSetupAgree => _s('profileSetup.agree');
  String get identityBadgeVerified => _s('identity.badge.verified');
  String get identityBadgeInReview => _s('identity.badge.inReview');
  String get identityBadgeRejected => _s('identity.badge.rejected');
  String get identityBadgeNotVerified => _s('identity.badge.notVerified');
  String get profileEditSaved => _s('profileEdit.saved');
  String get profileEditSave => _s('profileEdit.save');

  // --- Filters (DSC) ---------------------------------------------------------
  String filterAvailableOn(Object date) => _s('filter.availableOn', {'date': date});
  String get filterAvailableBy => _s('filter.availableBy');
  String get filterSectionType => _s('filter.section.type');
  String get filterSectionRent => _s('filter.section.rent');
  String get filterSectionBedrooms => _s('filter.section.bedrooms');
  String get filterSectionBathrooms => _s('filter.section.bathrooms');
  String get filterSectionArea => _s('filter.section.area');
  String get filterSectionAmenities => _s('filter.section.amenities');
  String get filterSectionAvailability => _s('filter.section.availability');
  String get filterAnyTime => _s('filter.anyTime');
  String get filterThisMonth => _s('filter.thisMonth');
  String get filterCustomDate => _s('filter.customDate');
  String get filterClose => _s('filter.close');
  String get filterTitle => _s('filter.title');
  String get filterReset => _s('filter.reset');
  String get filterNoAmenities => _s('filter.noAmenities');
  String get filterVerifiedOnly => _s('filter.verifiedOnly');
  String get filterVerifiedOnlyHelp => _s('filter.verifiedOnlyHelp');
  String get filterCounting => _s('filter.counting');
  String get filterBasedOn => _s('filter.basedOn');
  String get filterShow => _s('filter.show');
  String get filterOptionsFailed => _s('filter.optionsFailed');

  // --- Filters (DSC) counts --------------------------------------------------
  String filterMatches(Object count) => _plural('filter.matches', count);

  // --- Property facts --------------------------------------------------------
  String factBeds(Object count) => _s('fact.beds', {'count': count});
  String factBaths(Object count) => _s('fact.baths', {'count': count});

  // --- Home (DSC) ------------------------------------------------------------
  String get savedRemove => _s('saved.remove');
  String get savedAdd => _s('saved.add');
  String get activityToPay => _s('activity.toPay');
  String get homeMyActivity => _s('home.myActivity');
  String get commonSeeAllTitle => _s('common.seeAllTitle');

  // --- Search counts (DSC) ---------------------------------------------------
  String searchHomes(Object count) => _plural('search.homes', count);

  // --- Search (DSC) ----------------------------------------------------------
  String get searchSearching => _s('search.searching');
  String get searchList => _s('search.list');
  String get searchMap => _s('search.map');
  String get searchNoMatch => _s('search.noMatch');
  String get searchWiden => _s('search.widen');
  String get searchTryDifferent => _s('search.tryDifferent');
  String get searchClearFilters => _s('search.clearFilters');
  String searchLabelWith(Object query) => _s('search.labelWith', {'query': query});
  String get searchPlaceholder => _s('search.placeholder');
  String get searchClear => _s('search.clear');
  String searchFiltersCount(Object count) => _s('search.filtersCount', {'count': count});

  // --- Search overlay (DSC) --------------------------------------------------
  String get overlayRecent => _s('overlay.recent');
  String get overlayClearRecent => _s('overlay.clearRecent');
  String get overlayPopular => _s('overlay.popular');
  String get overlayFeatured => _s('overlay.featured');
  String get overlayLocations => _s('overlay.locations');
  String get overlayProperties => _s('overlay.properties');
  String get overlayClose => _s('overlay.close');
  String get overlayHint => _s('overlay.hint');
  String overlayFiltersActive(Object count) => _s('overlay.filtersActive', {'count': count});
  String get overlayNoPlaces => _s('overlay.noPlaces');
  String get overlayFailed => _s('overlay.failed');
  String get overlayNoHomes => _s('overlay.noHomes');

  // --- Property counts (DSC) -------------------------------------------------
  String propertyActiveListings(Object count) => _plural('property.activeListings', count);

  // --- Property (DSC) lines --------------------------------------------------
  String get propertyDeposit => _s('property.deposit');
  String get propertyAdvance => _s('property.advance');
  String propertyRefundable(Object name) => _s('property.refundable', {'name': name});
  String get propertyStepAccepts => _s('property.step.accepts');
  String get propertyStepPay => _s('property.step.pay');
  String get propertyStepVerified => _s('property.step.verified');

  // --- Property (DSC) --------------------------------------------------------
  String propertyAllIn(Object amount) => _s('property.allIn', {'amount': amount});
  String get propertyAbout => _s('property.about');
  String get propertyNoDescription => _s('property.noDescription');
  String get propertyShowLess => _s('property.showLess');
  String get propertyReadMore => _s('property.readMore');
  String get propertyListedByHomeMate => _s('property.listedByHomeMate');
  String propertyVerifiedContact(Object role) => _s('property.verifiedContact', {'role': role});
  String get propertyChat => _s('property.chat');
  String get propertyPriceBreakdown => _s('property.priceBreakdown');
  String get propertyMonthlyTotal => _s('property.monthlyTotal');
  String get propertyBeforeMoveIn => _s('property.beforeMoveIn');
  String get propertyFirstMonth => _s('property.firstMonth');
  String propertyFeeLine(Object percent) => _s('property.feeLine', {'percent': percent});
  String get propertyMoveInTotal => _s('property.moveInTotal');
  String get propertyEstimate => _s('property.estimate');
  String get propertyPaymentOptions => _s('property.paymentOptions');
  String get propertyHowToRent => _s('property.howToRent');
  String propertyPhotoOf(Object n, Object total) => _s('property.photoOf', {'n': n, 'total': total});
  String get propertyBeds => _s('property.beds');
  String get propertyBaths => _s('property.baths');
  String get propertyParking => _s('property.parking');
  String get propertyRentPaid => _s('property.rentPaid');
  String get propertyMinStay => _s('property.minStay');
  String get propertyPets => _s('property.pets');
  String get propertyPetsAllowed => _s('property.petsAllowed');
  String get propertyPetsNotAllowed => _s('property.petsNotAllowed');
  String get propertyTerms => _s('property.terms');
  String get propertySomeonePaying => _s('property.someonePaying');
  String get propertyContinuePayment => _s('property.continuePayment');
  String get propertyPayToSecure => _s('property.payToSecure');
  String get propertyViewEnquiry => _s('property.viewEnquiry');
  String get propertyEnquire => _s('property.enquire');

  // --- Gallery (DSC) ---------------------------------------------------------
  String get galleryEmpty => _s('gallery.empty');
  String get galleryClose => _s('gallery.close');
  String galleryPhotoOf(Object n, Object total) => _s('gallery.photoOf', {'n': n, 'total': total});
  String get galleryPinch => _s('gallery.pinch');

  // --- Rental detail (RNT) ---------------------------------------------------
  String rentalDueDay(Object day, Object suffix) => _s('rental.dueDay', {'day': day, 'suffix': suffix});
  String rentalNoticeRequired(Object days, Object date) => _s('rental.noticeRequired', {'days': days, 'date': date});
  String rentalRenewalBody(Object date) => _s('rental.renewalBody', {'date': date});
  String rentalComingSoon(Object what) => _s('rental.comingSoon', {'what': what});
  String rentalExitGive(Object days) => _s('rental.exitGive', {'days': days});
  String rentalExitFrom(Object date, Object days) => _s('rental.exitFrom', {'date': date, 'days': days});
  String rentalAgreement(Object version) => _s('rental.agreement', {'version': version});
  String rentalPaidOn(Object date) => _s('rental.paidOn', {'date': date});
  String get rentalStatePaid => _s('rental.state.paid');
  String get rentalStateProcessing => _s('rental.state.processing');
  String get rentalStateFailed => _s('rental.state.failed');
  String get rentalStateDue => _s('rental.state.due');

  // --- Rental detail (RNT) labels --------------------------------------------
  String get rentalTitle => _s('rental.title');
  String get rentalYourHome => _s('rental.yourHome');
  String get rentalFinancial => _s('rental.financial');
  String get rentalMonthlyRent => _s('rental.monthlyRent');
  String get rentalDeposit => _s('rental.deposit');
  String get rentalPaymentDue => _s('rental.paymentDue');
  String get rentalNextPayment => _s('rental.nextPayment');
  String get rentalLease => _s('rental.lease');
  String get rentalLeasePeriod => _s('rental.leasePeriod');
  String get rentalLeaseType => _s('rental.leaseType');
  String get rentalTypeMonthly => _s('rental.type.monthly');
  String get rentalTypeFixed => _s('rental.type.fixed');
  String get rentalHistory => _s('rental.history');
  String get rentalViewAll => _s('rental.viewAll');
  String get rentalNoPayments => _s('rental.noPayments');
  String get rentalIncluded => _s('rental.included');
  String get rentalJourney => _s('rental.journey');
  String get rentalRequestRenewal => _s('rental.requestRenewal');
  String get rentalRenewalTitle => _s('rental.renewalTitle');
  String get rentalRenewalAsk => _s('rental.renewalAsk');
  String get rentalGotIt => _s('rental.gotIt');
  String get rentalSchedule => _s('rental.schedule');
  String get rentalScheduling => _s('rental.scheduling');
  String get rentalReport => _s('rental.report');
  String get rentalReporting => _s('rental.reporting');
  String get rentalRequestExit => _s('rental.requestExit');
  String get rentalViewContract => _s('rental.viewContract');
  String get rentalTerms => _s('rental.terms');

  // --- Rentals (RNT) ---------------------------------------------------------
  String rentalsFrom(Object date) => _s('rentals.from', {'date': date});
  String rentalsUntil(Object date) => _s('rentals.until', {'date': date});

  // --- Rentals list (RNT) ----------------------------------------------------
  String get rentalsTitle => _s('rentals.title');
  String get rentalsEmpty => _s('rentals.empty');
  String get rentalsEmptyBody => _s('rentals.emptyBody');
  String get rentalsFind => _s('rentals.find');
  String rentalsRemaining(Object time) => _s('rentals.remaining', {'time': time});

  // --- Rentals remaining (RNT) -----------------------------------------------
  String get rentalsActive => _s('rentals.active');

  // --- Saved counts (CUS) ----------------------------------------------------
  String savedItems(Object count) => _plural('saved.items', count);

  // --- Saved (CUS) -----------------------------------------------------------
  String get savedSubtitle => _s('saved.subtitle');
  String get savedEmptyBody => _s('saved.emptyBody');
  String get savedBrowse => _s('saved.browse');
  String get savedActiveRents => _s('saved.activeRents');
  String get savedFavorites => _s('saved.favorites');
  String get savedFavoritesEmpty => _s('saved.favoritesEmpty');
  String get savedRecentInquiries => _s('saved.recentInquiries');
  String get savedInquiriesEmpty => _s('saved.inquiriesEmpty');
  String savedNextPayment(Object date) => _s('saved.nextPayment', {'date': date});
  String savedInquiredOn(Object date) => _s('saved.inquiredOn', {'date': date});

  // --- Activity (CUS) --------------------------------------------------------
  String get activityTitle => _s('activity.title');
  String get activityRentalsCaption => _s('activity.rentalsCaption');
  String get activityYourEnquiries => _s('activity.yourEnquiries');
  String get activityHowItWorks => _s('activity.howItWorks');
  String get enquiriesNone => _s('enquiries.none');
  String get activityEmptyBody => _s('activity.emptyBody');

  // --- Property activity (CUS) -----------------------------------------------
  String get pactivityEmptyBody => _s('pactivity.emptyBody');

  // --- Notifications (CUS) ---------------------------------------------------
  String get notificationsMarkAll => _s('notifications.markAll');
  String get notificationsEmpty => _s('notifications.empty');
  String get notificationsEmptyBody => _s('notifications.emptyBody');

  // --- Enquiries list (CUS) --------------------------------------------------
  String get inquiriesTitle => _s('inquiries.title');
  String get inquiriesEmptyBody => _s('inquiries.emptyBody');

  // --- Identity & preferences (CUS) ------------------------------------------
  String get prefsSaved => _s('prefs.saved');
  String get prefsTitle => _s('prefs.title');

  // --- Profile (CUS) ---------------------------------------------------------
  String get customerProfileFavourites => _s('customerProfile.favourites');
  String get customerProfileRentals => _s('customerProfile.rentals');
  String get customerProfileAccount => _s('customerProfile.account');
  String get customerProfileChangePin => _s('customerProfile.changePin');
  String get customerProfileSupport => _s('customerProfile.support');
  String get customerProfileTerms => _s('customerProfile.terms');
  String get customerProfileTermsAt => _s('customerProfile.termsAt');
  String get customerProfileSignOutQ => _s('customerProfile.signOutQ');
  String get customerProfileSignOutBody => _s('customerProfile.signOutBody');
  String get customerProfileStay => _s('customerProfile.stay');
  String get customerProfileChangePinTitle => _s('customerProfile.changePinTitle');
  String get customerProfileCurrentPin => _s('customerProfile.currentPin');
  String get customerProfilePinChanged => _s('customerProfile.pinChanged');

  // --- Payment (PAY) lines ---------------------------------------------------
  String paymentConfirmed(Object amount) => _s('payment.confirmed', {'amount': amount});
  String paymentConfirmedOn(Object amount, Object date) => _s('payment.confirmedOn', {'amount': amount, 'date': date});
  String get paymentAccountNumber => _s('payment.accountNumber');
  String get paymentPayToNumber => _s('payment.payToNumber');

  // --- Payment (PAY) ---------------------------------------------------------
  String get paymentTitle => _s('payment.title');
  String get paymentThanks => _s('payment.thanks');
  String get paymentConfirmTitle => _s('payment.confirmTitle');
  String get paymentConfirmBody => _s('payment.confirmBody');
  String get paymentCodeLabel => _s('payment.codeLabel');
  String get paymentCodeHint => _s('payment.codeHint');
  String get paymentIHavePaid => _s('payment.iHavePaid');
  String get paymentOnlyOnce => _s('payment.onlyOnce');
  String get paymentHowTo => _s('payment.howTo');
  String get paymentPayTo => _s('payment.payTo');
  String get paymentAccountName => _s('payment.accountName');
  String get paymentReference => _s('payment.reference');
  String get paymentQuoteReference => _s('payment.quoteReference');
  String paymentCopy(Object label) => _s('payment.copy', {'label': label});
  String paymentCopied(Object label) => _s('payment.copied', {'label': label});
  String get paymentPreparing => _s('payment.preparing');
  String get paymentPreparingBody => _s('payment.preparingBody');
  String get paymentChecking => _s('payment.checking');
  String get paymentCheckingBody => _s('payment.checkingBody');
  String paymentYourCode(Object code) => _s('payment.yourCode', {'code': code});
  String get paymentReceived => _s('payment.received');
  String paymentReceipt(Object reference) => _s('payment.receipt', {'reference': reference});
  String get paymentFailed => _s('payment.failed');
  String get paymentContactSupport => _s('payment.contactSupport');

  // --- Checkout (PAY) --------------------------------------------------------
  String get checkoutTitle => _s('checkout.title');
  String get checkoutReserving => _s('checkout.reserving');
  String get checkoutHeld => _s('checkout.held');
  String get checkoutCannotPay => _s('checkout.cannotPay');
  String get checkoutKeepLooking => _s('checkout.keepLooking');
  String get checkoutChooseMethod => _s('checkout.chooseMethod');
  String get checkoutEnterNumber => _s('checkout.enterNumber');
  String get checkoutNothingLeft => _s('checkout.nothingLeft');
  String get checkoutExpired => _s('checkout.expired');
  String get checkoutHoldAgain => _s('checkout.holdAgain');
  String get checkoutReservation => _s('checkout.reservation');
  String get checkoutMoveIn => _s('checkout.moveIn');
  String get checkoutToBeAgreed => _s('checkout.toBeAgreed');
  String get checkoutLeaseDuration => _s('checkout.leaseDuration');
  String get checkoutBreakdown => _s('checkout.breakdown');
  String get checkoutTotalDue => _s('checkout.totalDue');
  String get checkoutSelectMethod => _s('checkout.selectMethod');
  String get checkoutNoMethods => _s('checkout.noMethods');
  String checkoutRegisteredNumber(Object method) => _s('checkout.registeredNumber', {'method': method});
  String checkoutPrompt(Object method) => _s('checkout.prompt', {'method': method});
  String get checkoutSafety => _s('checkout.safety');
  String checkoutPay(Object amount) => _s('checkout.pay', {'amount': amount});
  String get checkoutYoursOnceVerified => _s('checkout.yoursOnceVerified');
  String get checkoutTotalCaps => _s('checkout.totalCaps');

  // --- Enquiry form (INQ) default --------------------------------------------
  String get inquiryFormDefaultMessage => _s('inquiryForm.defaultMessage');
  String inquiryDetailWaiting(Object days) => _s('inquiryDetail.waiting', {'days': days});
  String inquiryDetailDeclinedWhy(Object reason) => _s('inquiryDetail.declinedWhy', {'reason': reason});

  // --- Enquiry form (INQ) ----------------------------------------------------
  String get inquiryFormSent => _s('inquiryForm.sent');
  String get inquiryFormTitle => _s('inquiryForm.title');
  String get inquiryFormMessage => _s('inquiryForm.message');
  String get inquiryFormMessageRequired => _s('inquiryForm.messageRequired');
  String get inquiryFormMessageHint => _s('inquiryForm.messageHint');
  String get inquiryFormMoveIn => _s('inquiryForm.moveIn');
  String get inquiryFormChooseDate => _s('inquiryForm.chooseDate');
  String get inquiryFormPeople => _s('inquiryForm.people');
  String get inquiryFormBudget => _s('inquiryForm.budget');
  String get inquiryFormReach => _s('inquiryForm.reach');
  String get inquiryFormInApp => _s('inquiryForm.inApp');
  String get inquiryFormSend => _s('inquiryForm.send');

  // --- Enquiry detail (INQ) --------------------------------------------------
  String get inquiryDetailWithdrawQ => _s('inquiryDetail.withdrawQ');
  String get inquiryDetailWithdrawBody => _s('inquiryDetail.withdrawBody');
  String get inquiryDetailKeep => _s('inquiryDetail.keep');
  String get inquiryDetailWithdraw => _s('inquiryDetail.withdraw');
  String get inquiryDetailWithdrawn => _s('inquiryDetail.withdrawn');
  String get inquiryDetailTitle => _s('inquiryDetail.title');
  String get inquiryDetailTimeline => _s('inquiryDetail.timeline');
  String get inquiryDetailAsked => _s('inquiryDetail.asked');
  String get inquiryDetailReplied => _s('inquiryDetail.replied');
  String get inquiryDetailWithdrawEnquiry => _s('inquiryDetail.withdrawEnquiry');
  String get inquiryDetailReminderSent => _s('inquiryDetail.reminderSent');
  String get inquiryDetailDeclined => _s('inquiryDetail.declined');
  String get inquiryDetailFindAnother => _s('inquiryDetail.findAnother');
  String get inquiryDetailVerified => _s('inquiryDetail.verified');
  String get inquiryDetailViewRental => _s('inquiryDetail.viewRental');
  String get inquiryDetailVerifying => _s('inquiryDetail.verifying');
  String get inquiryDetailWithLandlord => _s('inquiryDetail.withLandlord');
  String get inquiryDetailNudge => _s('inquiryDetail.nudge');
  String get inquiryDetailOneADay => _s('inquiryDetail.oneADay');
  String get inquiryDetailSomeonePaying => _s('inquiryDetail.someonePaying');
  String get inquiryDetailPayNow => _s('inquiryDetail.payNow');

  // --- Checkout reasons and methods (PAY) ------------------------------------
  String get checkoutReasonAccepted => _s('checkout.reason.accepted');
  String get checkoutReasonBooking => _s('checkout.reason.booking');
  String get checkoutReasonBlocked => _s('checkout.reason.blocked');
  String get checkoutReasonPending => _s('checkout.reason.pending');
  String get checkoutReasonEnquireFirst => _s('checkout.reason.enquireFirst');
  String get paymentKindMobileMoney => _s('payment.kind.mobileMoney');
  String get paymentKindCard => _s('payment.kind.card');
  String get paymentKindBank => _s('payment.kind.bank');
  String get paymentKindCash => _s('payment.kind.cash');
  String get holdExpired => _s('hold.expired');
  String get holdHeld => _s('hold.held');
  String get holdExpiredBody => _s('hold.expiredBody');
  String get holdHeldBody => _s('hold.heldBody');
  String holdMinutesLeft(Object minutes) => _s('hold.minutesLeft', {'minutes': minutes});
  String get holdUnderAMinute => _s('hold.underAMinute');
  String get promptSayWhy => _s('prompt.sayWhy');
  String get phoneInvalid => _s('phone.invalid');

  // --- Status words (shared) -------------------------------------------------

  // --- Reference data: read through reference(code) --------------------------
}

/// Hands [AppText] to the widget tree through `Localizations`, so a language
/// change rebuilds every screen that reads a string without any screen having
/// to watch a provider.
class AppTextDelegate extends LocalizationsDelegate<AppText> {
  const AppTextDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocale.values.any((value) => value.code == locale.languageCode);

  /// Loading a language also makes it the one dates are written in: every
  /// `DateFormat(pattern)` built after this reads "3 Ago" in Kiswahili and
  /// "3 Aug" in English, with no screen passing a locale.
  @override
  Future<AppText> load(Locale locale) async {
    final appLocale = AppLocale.fromCode(locale.languageCode);
    await initializeDateFormatting(appLocale.code);
    Intl.defaultLocale = appLocale.code;
    return AppText(appLocale);
  }

  @override
  bool shouldReload(AppTextDelegate old) => false;
}

extension AppTextContext on BuildContext {
  /// The app's words. `context.text.featured`.
  AppText get text => AppText.of(this);
}
