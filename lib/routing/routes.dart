import 'package:flutter/foundation.dart';

/// Every path in the app, named once.
///
/// Screens navigate with `context.go(Routes.property(id))` rather than a
/// string literal, so a renamed path is a compile error rather than a dead
/// link someone finds in production.
class Routes {
  const Routes._();

  static const splash = '/';
  static const onboarding = '/welcome';
  static const signIn = '/sign-in';
  static const otp = '/verify';
  static const pinSetup = '/set-pin';
  static const forgotPin = '/forgot-pin';
  static const profileSetup = '/complete-profile';

  /// Editing the same details later.
  ///
  /// Deliberately NOT [profileSetup]: that path is where the redirect *holds*
  /// anyone whose profile is outstanding, and sends everyone else straight to
  /// the home screen — which is exactly what "Edit your details" used to do.
  static const profileEdit = '/profile/edit';
  static const identity = '/profile/identity';
  static const preferences = '/profile/preferences';

  static const home = '/home';
  static const search = '/search';
  static const saved = '/saved';
  static const activity = '/activity';
  static const profile = '/profile';
  static const notifications = '/notifications';

  /// The full-screen search, pushed over whatever tab you were on.
  static const searchOverlay = '/search-overlay';

  static String property(String id) => '/property/$id';
  static String gallery(String id, {int index = 0}) => '/property/$id/photos?start=$index';
  static String inquiryForm(String propertyId) => '/property/$propertyId/enquire';
  static const inquiries = '/activity/enquiries';

  /// Detail screens sit outside the tab shell, alongside /property and
  /// /payment. A detail is reachable from a list, from a notification and from
  /// the screen that created it — nesting it inside one tab's navigator means
  /// pushing it from anywhere else collides with that tab's page keys.
  static String inquiry(String id) => '/enquiry/$id';
  static String payment(String id) => '/payment/$id';

  /// Paying for a property once the landlord has accepted the enquiry
  /// (CUS-011 + CUS-014).
  ///
  /// Keyed on the *property*, which is what the customer has in hand from both
  /// the listing and the accepted enquiry. The server works out whether a
  /// reservation already exists.
  static String checkout(String propertyId) => '/property/$propertyId/checkout';

  /// The tenancies a customer is living under, reached from the Active Rents
  /// section of the Favourites tab (CUS-012a/b/c).
  static const rentals = '/rentals';
  static String rental(String bookingId) => '/rentals/$bookingId';
  static String lease(String bookingId) => '/rentals/$bookingId/lease';

  /// One property's timeline — CUS-013b.
  static String propertyActivity(String propertyId) => '/property/$propertyId/activity';

  /// The screens reachable without a session.
  ///
  /// The splash is deliberately NOT one of them. It is only ever correct while
  /// the stored session is being read; treating it as a normal public route
  /// meant the redirect had no reason to move off it once reading finished,
  /// and the app sat on the splash screen forever.
  static const _public = {onboarding, signIn, otp, pinSetup, forgotPin};

  /// AUTH-001 "How will you use HomeMate?" — once per new account.
  static const roleUse = '/how-you-use';

  /// ROL-001 "Choose how to continue" — after the PIN, with several roles.
  static const chooseRole = '/choose-role';

  /// ROL-004 "Earn with HomeMate" — a customer adds a partner role.
  static const earn = '/earn';

  // The broker shell (tabs: Home · Listings · Enquiries · Earnings · Profile).
  static const brokerHome = '/broker';
  static const brokerListings = '/broker/listings';
  static const brokerEnquiries = '/broker/enquiries';
  static const brokerEarnings = '/broker/earnings';
  static const brokerProfile = '/broker/profile';

  // The landlord shell (tabs: Home · Homes · Tenants · Money · Profile).
  static const landlordHome = '/landlord';
  static const landlordHomes = '/landlord/homes';
  static const landlordTenants = '/landlord/tenants';
  static const landlordMoney = '/landlord/money';
  static const landlordProfile = '/landlord/profile';

  /// A landlord answers enquiries on the homes they listed; there is no tab
  /// for them, so "Needs you" and the home link here.
  static const landlordEnquiries = '/landlord/enquiries';

  // Partner setup (BRK/LND-001, -002), outside the shell's tabs but inside
  // its path, so the role redirect keeps them in the partner's space.
  static String partnerIntro(Object role) => '/${_name(role)}/intro';
  static String partnerSetup(Object role, {String? step}) =>
      '/${_name(role)}/setup${step == null ? '' : '?step=$step'}';
  static String partnerApplication(Object role) => '/${_name(role)}/application';

  static String _name(Object role) => role is Enum ? role.name : '$role';

  // A partner's listings: the broker's "Listings" tab, the landlord's "Homes".
  static String partnerListings(Object role) => _name(role) == 'landlord' ? landlordHomes : brokerListings;
  static String partnerListing(Object role, String id) => '${partnerListings(role)}/$id';
  static String partnerListingNew(Object role) => '${partnerListings(role)}/new';
  static String partnerListingEdit(Object role, String id, {String? step}) =>
      '${partnerListings(role)}/$id/edit${step == null ? '' : '?step=$step'}';
  static String partnerListingSent(Object role, String id) => '${partnerListings(role)}/$id/sent';

  static String partnerEnquiry(Object role, String id) => '/${_name(role)}/enquiries/$id';

  // Money: the broker's "Earnings" tab, the landlord's "Money".
  static String partnerMoney(Object role) => _name(role) == 'landlord' ? landlordMoney : brokerEarnings;
  static String partnerEarning(Object role, String id) => '${partnerMoney(role)}/$id';
  static String partnerPayouts(Object role) => '/${_name(role)}/payouts';

  /// LND-031/033: one tenancy.
  static String landlordTenancy(String id) => '$landlordTenants/$id';

  /// LND-033: the lease behind a tenancy.
  static String landlordTenancyLease(String id) => '${landlordTenancy(id)}/lease';

  /// LND-003, from the SMS link `homemate://landlord/confirm/:propertyId`.
  static String landlordConfirm(String propertyId) => '/landlord/confirm/$propertyId';
  static const landlordConfirmPrefix = '/landlord/confirm/';

  static bool isPartnerLocation(String location) =>
      location == brokerHome ||
      location.startsWith('$brokerHome/') ||
      location == landlordHome ||
      location.startsWith('$landlordHome/');

  /// The widget catalogue (T02). Registered, and reachable signed out, only in
  /// a debug build.
  static const devWidgets = '/dev/widgets';

  static bool isPublic(String location) =>
      _public.contains(location) ||
      location.startsWith('$otp?') ||
      location.startsWith('$pinSetup?') ||
      (kDebugMode && location == devWidgets);
}
