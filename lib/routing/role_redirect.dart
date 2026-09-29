import '../features/auth/data/auth_controller.dart';
import '../features/roles/data/app_role.dart';
import '../features/roles/data/role_controller.dart';
import '../features/roles/domain/role_landing.dart';
import 'routes.dart';

/// Who may see what, and which shell a signed-in person belongs in
/// (Figma AUTH-000). Pure, so each branch is a one-line test.
String? roleRedirect({required AuthState auth, required RoleState roles, required String location}) {
  String? stayOr(String target) => location == target ? null : target;

  // Still reading storage: hold on the splash rather than flashing the
  // sign-in screen at someone who is already signed in.
  if (auth.stage == AuthStage.restoring) return stayOr(Routes.splash);

  if (!auth.isSignedIn) {
    if (Routes.isPublic(location)) return null;
    // An enrolled device goes to the keypad; a new one to the welcome slides.
    return auth.isPinEnrolled ? Routes.signIn : Routes.onboarding;
  }

  if (location == Routes.devWidgets) return null;
  if (!roles.settled) return stayOr(Routes.splash);

  // The landlord confirmation (from the SMS) is reachable whatever role is in
  // use, and before AUTH-001 or ROL-001: it is what the person came for.
  if (location.startsWith(Routes.landlordConfirmPrefix)) return null;

  switch (roles.landing) {
    case ChooseUse():
      return stayOr(Routes.roleUse);
    case ChooseRole():
      return stayOr(Routes.chooseRole);
    case OpenRole() || null:
      break;
  }

  final current = roles.current ?? AppRole.customer;
  if (current == AppRole.customer) {
    // CUS-008a: a new customer finishes their profile before anything else.
    if (auth.stage == AuthStage.needsProfile) return stayOr(Routes.profileSetup);
    final isEntryScreen = Routes.isPublic(location) ||
        location == Routes.profileSetup ||
        location == Routes.splash ||
        location == Routes.roleUse ||
        location == Routes.chooseRole;
    if (isEntryScreen || Routes.isPartnerLocation(location)) return Routes.home;
    return null;
  }

  final root = current == AppRole.broker ? Routes.brokerHome : Routes.landlordHome;
  if (location == root || location.startsWith('$root/')) return null;
  return root;
}
