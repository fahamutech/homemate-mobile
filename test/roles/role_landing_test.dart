import 'package:flutter_test/flutter_test.dart';
import 'package:homemate_mobile/features/roles/data/account_role.dart';
import 'package:homemate_mobile/features/roles/data/app_role.dart';
import 'package:homemate_mobile/features/roles/domain/role_landing.dart';

AccountRole role(AppRole role, String status) => AccountRole(role: role, status: status);

final customer = role(AppRole.customer, 'active');

void main() {
  group('AppRole', () {
    test('reads the server’s names and nothing else', () {
      expect(AppRole.fromName('broker'), AppRole.broker);
      expect(AppRole.fromName('landlord'), AppRole.landlord);
      expect(AppRole.fromName('customer'), AppRole.customer);
      expect(AppRole.fromName('agency'), isNull);
      expect(AppRole.fromName(null), isNull);
      expect(AppRole.broker.isPartner, isTrue);
      expect(AppRole.customer.isPartner, isFalse);
    });
  });

  group('AccountRole', () {
    test('parses the /app/me shape', () {
      final parsed = AccountRole.fromJson({
        'role': 'landlord',
        'status': 'action_needed',
        'appliedAt': '2026-09-01T10:00:00Z',
        'activatedAt': null,
        'rejectionReason': null,
      });
      expect(parsed!.role, AppRole.landlord);
      expect(parsed.status, 'action_needed');
      expect(parsed.appliedAt, isNotNull);
      expect(parsed.isActive, isFalse);
    });

    test('a partner role opens its shell while applying, under review or active — not when refused', () {
      for (final status in ['applied', 'pending_review', 'action_needed', 'active']) {
        expect(role(AppRole.broker, status).canOpen, isTrue, reason: status);
      }
      for (final status in ['rejected', 'suspended', 'invited']) {
        expect(role(AppRole.broker, status).canOpen, isFalse, reason: status);
      }
    });
  });

  group('openableRoles', () {
    test('customer always, partner roles in their usual order', () {
      expect(openableRoles([role(AppRole.landlord, 'active'), role(AppRole.broker, 'pending_review')]),
          [AppRole.customer, AppRole.broker, AppRole.landlord]);
      expect(openableRoles(const []), [AppRole.customer]);
    });

    test('the role picked at first launch counts before its application exists', () {
      expect(openableRoles([customer], startedAs: AppRole.landlord), [AppRole.customer, AppRole.landlord]);
    });

    test('but not once that role has been refused', () {
      expect(openableRoles([customer, role(AppRole.landlord, 'rejected')], startedAs: AppRole.landlord), [AppRole.customer]);
    });
  });

  group('decideLanding', () {
    test('a new customer-only account is asked how it will use HomeMate (AUTH-001)', () {
      expect(decideLanding(roles: [customer], isNewAccount: true), const ChooseUse());
    });

    test('…once: after answering, it opens what was picked', () {
      expect(decideLanding(roles: [customer], isNewAccount: true, startedAs: AppRole.customer), const OpenRole(AppRole.customer));
      expect(decideLanding(roles: [customer], isNewAccount: true, startedAs: AppRole.broker), const OpenRole(AppRole.broker));
    });

    test('a broker mid-way through setup goes back to it, not to ROL-001', () {
      expect(
        decideLanding(roles: [customer, role(AppRole.broker, 'pending_review')], isNewAccount: true, startedAs: AppRole.broker),
        const OpenRole(AppRole.broker),
      );
    });

    test('once that role is active, several roles means ROL-001 again', () {
      expect(
        decideLanding(roles: [customer, role(AppRole.broker, 'active')], isNewAccount: false, startedAs: AppRole.broker, lastUsed: AppRole.broker),
        const ChooseRole(preselected: AppRole.broker),
      );
    });

    test('a first-launch pick that was refused falls back to the customer home', () {
      expect(
        decideLanding(roles: [customer, role(AppRole.broker, 'rejected')], isNewAccount: false, startedAs: AppRole.broker),
        const OpenRole(AppRole.customer),
      );
    });

    test('a partner from day one skips AUTH-001 and opens on their only role', () {
      expect(
        decideLanding(roles: [customer, role(AppRole.broker, 'active')], isNewAccount: true),
        const OpenRole(AppRole.broker),
      );
    });

    test('a partner from day one with both partner roles picks between those two', () {
      expect(
        decideLanding(
          roles: [customer, role(AppRole.broker, 'active'), role(AppRole.landlord, 'active')],
          isNewAccount: true,
          lastUsed: AppRole.landlord,
        ),
        const ChooseRole(preselected: AppRole.landlord),
      );
      expect(
        decideLanding(roles: [customer, role(AppRole.broker, 'active'), role(AppRole.landlord, 'active')], isNewAccount: true),
        const ChooseRole(preselected: AppRole.broker),
      );
    });

    test('one role: straight to its home', () {
      expect(decideLanding(roles: [customer], isNewAccount: false), const OpenRole(AppRole.customer));
    });

    test('a refused partner role leaves only the customer home', () {
      expect(decideLanding(roles: [customer, role(AppRole.broker, 'rejected')], isNewAccount: false), const OpenRole(AppRole.customer));
    });

    test('several roles: choose how to continue (ROL-001), the last one used preselected', () {
      expect(
        decideLanding(roles: [customer, role(AppRole.broker, 'active')], isNewAccount: false, lastUsed: AppRole.broker),
        const ChooseRole(preselected: AppRole.broker),
      );
    });

    test('a last-used role no longer held is not preselected', () {
      expect(
        decideLanding(roles: [customer, role(AppRole.broker, 'active')], isNewAccount: false, lastUsed: AppRole.landlord),
        const ChooseRole(preselected: AppRole.customer),
      );
    });

    test('"Always open as" skips ROL-001', () {
      expect(
        decideLanding(roles: [customer, role(AppRole.landlord, 'active')], isNewAccount: false, alwaysOpenAs: AppRole.landlord),
        const OpenRole(AppRole.landlord),
      );
    });

    test('…unless that role can no longer be opened', () {
      expect(
        decideLanding(
          roles: [customer, role(AppRole.broker, 'active'), role(AppRole.landlord, 'suspended')],
          isNewAccount: false,
          alwaysOpenAs: AppRole.landlord,
        ),
        const ChooseRole(preselected: AppRole.customer),
      );
    });
  });

  group('serverActiveRole', () {
    test('mirrors the server: the last one used if still active, else customer', () {
      expect(serverActiveRole([customer, role(AppRole.broker, 'active')], AppRole.broker), AppRole.broker);
      expect(serverActiveRole([customer, role(AppRole.broker, 'pending_review')], AppRole.broker), AppRole.customer);
      expect(serverActiveRole([customer], null), AppRole.customer);
    });
  });
}
