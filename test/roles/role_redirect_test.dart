import 'package:flutter_test/flutter_test.dart';
import 'package:homemate_mobile/features/auth/data/auth_controller.dart';
import 'package:homemate_mobile/features/roles/data/app_role.dart';
import 'package:homemate_mobile/features/roles/data/role_controller.dart';
import 'package:homemate_mobile/features/roles/domain/role_landing.dart';
import 'package:homemate_mobile/routing/deep_links.dart';
import 'package:homemate_mobile/routing/role_redirect.dart';
import 'package:homemate_mobile/routing/routes.dart';

const ready = AuthState(stage: AuthStage.ready);
const needsProfile = AuthState(stage: AuthStage.needsProfile);
const signedOut = AuthState(stage: AuthStage.signedOut);
const enrolledSignedOut = AuthState(stage: AuthStage.signedOut, pinEnrolledNumber: '+255712345678');

RoleState using(AppRole role) => RoleState(loaded: true, current: role);

void main() {
  group('before the roles are known', () {
    test('restoring holds on the splash', () {
      expect(roleRedirect(auth: const AuthState(stage: AuthStage.restoring), roles: const RoleState(), location: Routes.home), Routes.splash);
      expect(roleRedirect(auth: const AuthState(stage: AuthStage.restoring), roles: const RoleState(), location: Routes.splash), isNull);
    });

    test('signed out: public screens stay, everything else goes to sign-in or onboarding', () {
      expect(roleRedirect(auth: signedOut, roles: const RoleState(), location: Routes.signIn), isNull);
      expect(roleRedirect(auth: signedOut, roles: const RoleState(), location: Routes.brokerHome), Routes.onboarding);
      expect(roleRedirect(auth: enrolledSignedOut, roles: const RoleState(), location: Routes.home), Routes.signIn);
    });

    test('signed in but roles still loading holds on the splash', () {
      expect(roleRedirect(auth: ready, roles: const RoleState(), location: Routes.home), Routes.splash);
    });
  });

  group('questions come first', () {
    test('AUTH-001 while the account has not said how it will use HomeMate', () {
      const roles = RoleState(loaded: true, landing: ChooseUse());
      expect(roleRedirect(auth: needsProfile, roles: roles, location: Routes.profileSetup), Routes.roleUse);
      expect(roleRedirect(auth: needsProfile, roles: roles, location: Routes.roleUse), isNull);
    });

    test('ROL-001 while someone with several roles has not picked one', () {
      const roles = RoleState(loaded: true, landing: ChooseRole(preselected: AppRole.customer));
      expect(roleRedirect(auth: ready, roles: roles, location: Routes.splash), Routes.chooseRole);
      expect(roleRedirect(auth: ready, roles: roles, location: Routes.chooseRole), isNull);
    });
  });

  group('the customer shell', () {
    test('the profile step still holds a new customer', () {
      expect(roleRedirect(auth: needsProfile, roles: using(AppRole.customer), location: Routes.home), Routes.profileSetup);
    });

    test('entry screens and partner shells send a customer home', () {
      for (final location in [Routes.splash, Routes.signIn, Routes.roleUse, Routes.chooseRole, Routes.brokerHome, Routes.landlordTenants]) {
        expect(roleRedirect(auth: ready, roles: using(AppRole.customer), location: location), Routes.home, reason: location);
      }
    });

    test('customer screens and ROL-004 are left alone', () {
      for (final location in [Routes.home, Routes.saved, Routes.earn, '/property/p1']) {
        expect(roleRedirect(auth: ready, roles: using(AppRole.customer), location: location), isNull, reason: location);
      }
    });
  });

  group('the partner shells', () {
    test('a broker stays inside /broker and is brought back to it from anywhere else', () {
      expect(roleRedirect(auth: ready, roles: using(AppRole.broker), location: Routes.brokerEarnings), isNull);
      expect(roleRedirect(auth: ready, roles: using(AppRole.broker), location: Routes.home), Routes.brokerHome);
      expect(roleRedirect(auth: ready, roles: using(AppRole.broker), location: Routes.landlordHome), Routes.brokerHome);
    });

    test('a landlord likewise, and the profile step does not hold a partner', () {
      expect(roleRedirect(auth: needsProfile, roles: using(AppRole.landlord), location: Routes.landlordHomes), isNull);
      expect(roleRedirect(auth: needsProfile, roles: using(AppRole.landlord), location: Routes.profileSetup), Routes.landlordHome);
    });

    test('the landlord confirmation opens from any role', () {
      final confirm = Routes.landlordConfirm('p1');
      for (final role in AppRole.values) {
        expect(roleRedirect(auth: ready, roles: using(role), location: confirm), isNull, reason: '$role');
      }
      // …and ahead of the questions, since it is what the person came for.
      expect(roleRedirect(auth: needsProfile, roles: const RoleState(loaded: true, landing: ChooseUse()), location: confirm), isNull);
    });
  });

  group('deep links', () {
    test('the SMS link becomes the in-app confirmation path', () {
      expect(deepLinkLocation(Uri.parse('homemate://landlord/confirm/p-42')), '/landlord/confirm/p-42');
      // Some platforms hand the router only the path, having taken the host.
      expect(deepLinkLocation(Uri.parse('/confirm/p-42')), '/landlord/confirm/p-42');
      expect(deepLinkLocation(Uri.parse('https://app.homemate.co.tz/landlord/confirm/p-42')), '/landlord/confirm/p-42');
    });

    test('anything else is not a deep link', () {
      expect(deepLinkLocation(Uri.parse('/home')), isNull);
      expect(deepLinkLocation(Uri.parse('homemate://broker/listings')), isNull);
      expect(deepLinkLocation(Uri.parse('homemate://landlord/confirm/')), isNull);
    });

    test('a pending link is taken once', () {
      final pending = PendingDeepLink();
      expect(pending.take(), isNull);
      pending.remember('/landlord/confirm/p1');
      expect(pending.location, '/landlord/confirm/p1', reason: 'looking does not take it');
      expect(pending.take(), '/landlord/confirm/p1');
      expect(pending.take(), isNull);
    });
  });
}
