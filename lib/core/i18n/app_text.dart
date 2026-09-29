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
  String partnerComingSoon(String role) => _s('partner.comingSoon', {'role': role});
  String get partnerSignOut => _s('partner.signOut');
  String partnerStatusApplied(String role) => _s('partner.status.applied', {'role': role});
  String partnerStatusPendingReview(String role) => _s('partner.status.pendingReview', {'role': role});
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
  String listingOpenEnquiries(Object count) => _s('listing.openEnquiries', {'count': count});
  String listingSent(Object date) => _s('listing.sent', {'date': date});
  String get listingSeeNote => _s('listing.seeNote');
  String listingPerMonth(Object amount) => _s('listing.perMonth', {'amount': amount});
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
