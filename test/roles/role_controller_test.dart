import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homemate_mobile/core/network/api_exception.dart';
import 'package:homemate_mobile/core/providers.dart';
import 'package:homemate_mobile/features/auth/data/customer.dart';
import 'package:homemate_mobile/features/roles/data/account_role.dart';
import 'package:homemate_mobile/features/roles/data/app_role.dart';
import 'package:homemate_mobile/features/roles/data/role_repository.dart';
import 'package:homemate_mobile/features/roles/domain/role_landing.dart';

import '../support/fakes.dart';

/// The role session: what loads after sign-in, what AUTH-001 and ROL-001
/// remember, and switching without a PIN.
void main() {
  const newCustomer = Customer(id: 'cust-1', phoneNumber: '+255712345678', hasPin: true);
  const existingCustomer = Customer(
    id: 'cust-1',
    phoneNumber: '+255712345678',
    fullName: 'Baraka Mwinyi',
    hasPin: true,
    onboardingComplete: true,
  );

  Future<ProviderContainer> signIn(TestHarness harness, {Customer customer = existingCustomer}) async {
    final container = ProviderContainer(overrides: harness.overrides);
    addTearDown(container.dispose);
    container.read(roleControllerProvider);
    await container.read(authControllerProvider.notifier).adopt(AuthSessionStub(token: 'session-token', customer: customer));
    await pumpEventQueue();
    return container;
  }

  test('a customer-only account opens the customer home, no switch needed', () async {
    final harness = TestHarness();
    final container = await signIn(harness);
    final state = container.read(roleControllerProvider);
    expect(state.loaded, isTrue);
    expect(state.current, AppRole.customer);
    expect(state.landing, isNull);
    expect(harness.roles.switches, isEmpty);
  });

  test('a new account is asked AUTH-001 once; a broker pick opens the broker home locally', () async {
    final harness = TestHarness();
    final container = await signIn(harness, customer: newCustomer);
    expect(container.read(roleControllerProvider).landing, const ChooseUse());
    expect(container.read(roleControllerProvider).current, isNull);

    await container.read(roleControllerProvider.notifier).chooseUse(AppRole.broker);
    expect(container.read(roleControllerProvider).current, AppRole.broker);
    // No broker role yet, so nothing to switch the token to.
    expect(harness.roles.switches, isEmpty);
    expect(await harness.rolePreferences.startedAs('cust-1'), AppRole.broker);

    // Coming back later goes back to the broker setup, not to AUTH-001.
    await container.read(roleControllerProvider.notifier).load(newCustomer);
    expect(container.read(roleControllerProvider).current, AppRole.broker);
  });

  test('several roles ask ROL-001; "Always open as" is remembered and switches the token', () async {
    final harness = TestHarness(roles: FakeRoleRepository.withPartner(AppRole.landlord));
    final container = await signIn(harness);
    expect(container.read(roleControllerProvider).landing, const ChooseRole(preselected: AppRole.customer));

    await container.read(roleControllerProvider.notifier).chooseRole(AppRole.landlord, alwaysOpen: true);
    expect(container.read(roleControllerProvider).current, AppRole.landlord);
    expect(harness.roles.switches, [AppRole.landlord]);
    expect(container.read(authControllerProvider.notifier).token, 'session-token-landlord');
    expect((await harness.store.read())!.token, 'session-token-landlord');

    await container.read(roleControllerProvider.notifier).load(existingCustomer);
    expect(container.read(roleControllerProvider).landing, isNull);
    expect(container.read(roleControllerProvider).current, AppRole.landlord);
  });

  test('without the tick, ROL-001 is asked again with the last role preselected', () async {
    final harness = TestHarness(roles: FakeRoleRepository.withPartner(AppRole.broker));
    final container = await signIn(harness);
    await container.read(roleControllerProvider.notifier).chooseRole(AppRole.broker, alwaysOpen: false);
    await container.read(roleControllerProvider.notifier).load(existingCustomer);
    expect(container.read(roleControllerProvider).landing, const ChooseRole(preselected: AppRole.broker));
  });

  test('switching back to customer re-signs the token too', () async {
    final harness = TestHarness(roles: FakeRoleRepository.withPartner(AppRole.broker, lastActiveRole: AppRole.broker));
    final container = await signIn(harness);
    await container.read(roleControllerProvider.notifier).chooseRole(AppRole.broker, alwaysOpen: false);
    expect(harness.roles.switches, isEmpty, reason: 'the token already acts as broker');

    await container.read(roleControllerProvider.notifier).open(AppRole.customer);
    expect(harness.roles.switches, [AppRole.customer]);
    expect(container.read(roleControllerProvider).current, AppRole.customer);
  });

  test('a partner role under review opens its home without asking the server', () async {
    final harness = TestHarness(roles: FakeRoleRepository.withPartner(AppRole.broker, status: 'pending_review'));
    final container = await signIn(harness);
    await container.read(roleControllerProvider.notifier).open(AppRole.broker);
    expect(container.read(roleControllerProvider).current, AppRole.broker);
    expect(harness.roles.switches, isEmpty);
  });

  test('opening a role under review while the token acts as another partner switches it back to customer', () async {
    // The partner routes ignore X-Partner-Role while the token acts as a
    // partner, so a landlord applicant must not be acting as broker.
    final harness = TestHarness(
      roles: FakeRoleRepository(roles: const [
        AccountRole(role: AppRole.customer, status: 'active'),
        AccountRole(role: AppRole.broker, status: 'active'),
        AccountRole(role: AppRole.landlord, status: 'pending_review'),
      ], lastActiveRole: AppRole.broker),
    );
    final container = await signIn(harness);
    await container.read(roleControllerProvider.notifier).open(AppRole.landlord);
    expect(harness.roles.switches, [AppRole.customer]);
    expect(container.read(roleControllerProvider).current, AppRole.landlord);
  });

  test('a refused switch keeps ROL-001 on screen rather than opening a home', () async {
    final harness = TestHarness(roles: _RefusingRoles());
    final container = await signIn(harness);
    final controller = container.read(roleControllerProvider.notifier);
    await expectLater(controller.chooseRole(AppRole.landlord, alwaysOpen: false), throwsA(isA<ApiException>()));
    expect(container.read(roleControllerProvider).current, isNull);
    expect(container.read(roleControllerProvider).landing, const ChooseRole(preselected: AppRole.customer));
  });

  test('if the roles cannot be read, the customer home opens', () async {
    final harness = TestHarness(roles: _BrokenRoles());
    final container = await signIn(harness);
    expect(container.read(roleControllerProvider).current, AppRole.customer);
  });

  test('signing out forgets the role', () async {
    final harness = TestHarness(roles: FakeRoleRepository.withPartner(AppRole.broker));
    final container = await signIn(harness);
    await container.read(authControllerProvider.notifier).signOut();
    expect(container.read(roleControllerProvider).loaded, isFalse);
    expect(container.read(roleControllerProvider).current, isNull);
  });
}

class _BrokenRoles extends FakeRoleRepository {
  @override
  Future<RoleSnapshot> fetch() async => throw ApiException.unexpected();
}

/// Holds an active landlord role the server then refuses to switch to.
class _RefusingRoles extends FakeRoleRepository {
  _RefusingRoles()
      : super(roles: const [
          AccountRole(role: AppRole.customer, status: 'active'),
          AccountRole(role: AppRole.landlord, status: 'active'),
        ]);

  @override
  Future<RoleSwitch> setActiveRole(AppRole role) async =>
      throw ApiException(code: 'ROLE_NOT_ACTIVE', message: 'Suspended', statusCode: 403);
}
