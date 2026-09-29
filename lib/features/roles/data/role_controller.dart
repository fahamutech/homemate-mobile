import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_controller.dart';
import '../../auth/data/customer.dart';
import '../domain/role_landing.dart';
import 'account_role.dart';
import 'app_role.dart';
import 'role_preference_store.dart';
import 'role_repository.dart';

/// Which role the signed-in person is using, and what the app still has to
/// ask them before it can open a home.
class RoleState {
  const RoleState({
    this.loaded = false,
    this.roles = const [],
    this.lastActiveRole,
    this.current,
    this.landing,
    this.alwaysOpenAs,
  });

  /// False until the roles have been read after sign-in; the router holds on
  /// the splash meanwhile.
  final bool loaded;
  final List<AccountRole> roles;

  /// The role the session token acts in (the server's `activeRole`).
  final AppRole? lastActiveRole;

  /// The shell on screen. Null while [landing] is a question.
  final AppRole? current;

  /// AUTH-001 or ROL-001 while one of them has to be answered.
  final RoleLanding? landing;
  final AppRole? alwaysOpenAs;

  /// Loaded and decided: a home to open or a question to ask. In between
  /// (the token being switched) the router keeps the splash up.
  bool get settled => loaded && (current != null || landing != null);

  AccountRole? held(AppRole role) {
    for (final row in roles) {
      if (row.role == role) return row;
    }
    return null;
  }

  /// The roles a person could switch to from ROL-002.
  List<AppRole> get switchable => openableRoles(roles, startedAs: current);

  RoleState copyWith({
    bool? loaded,
    List<AccountRole>? roles,
    Object? lastActiveRole = _unset,
    Object? current = _unset,
    Object? landing = _unset,
    Object? alwaysOpenAs = _unset,
  }) =>
      RoleState(
        loaded: loaded ?? this.loaded,
        roles: roles ?? this.roles,
        lastActiveRole: lastActiveRole == _unset ? this.lastActiveRole : lastActiveRole as AppRole?,
        current: current == _unset ? this.current : current as AppRole?,
        landing: landing == _unset ? this.landing : landing as RoleLanding?,
        alwaysOpenAs: alwaysOpenAs == _unset ? this.alwaysOpenAs : alwaysOpenAs as AppRole?,
      );

  static const Object _unset = Object();
}

/// Loads the roles after sign-in, decides the landing (AUTH-000) and switches
/// role without a PIN (ROL-002).
class RoleController extends StateNotifier<RoleState> {
  RoleController({
    required RoleRepository repository,
    required RolePreferenceStore preferences,
    required AuthController auth,
  })  : _repository = repository,
        _preferences = preferences,
        _auth = auth,
        super(const RoleState());

  final RoleRepository _repository;
  final RolePreferenceStore _preferences;
  final AuthController _auth;
  String? _userId;

  Future<void> load(Customer customer) async {
    _userId = customer.id;
    final RoleSnapshot snapshot;
    try {
      snapshot = await _repository.fetch();
    } catch (_) {
      // Without the roles the customer home is still correct for everyone.
      state = const RoleState(loaded: true, current: AppRole.customer);
      return;
    }
    final startedAs = await _preferences.startedAs(customer.id);
    final alwaysOpenAs = await _preferences.alwaysOpenAs(customer.id);
    final lastUsed = await _preferences.lastUsed(customer.id) ?? snapshot.lastActiveRole;

    final landing = decideLanding(
      roles: snapshot.roles,
      isNewAccount: !customer.onboardingComplete,
      startedAs: startedAs,
      alwaysOpenAs: alwaysOpenAs,
      lastUsed: lastUsed,
    );
    state = RoleState(
      loaded: true,
      roles: snapshot.roles,
      lastActiveRole: serverActiveRole(snapshot.roles, snapshot.lastActiveRole),
      alwaysOpenAs: alwaysOpenAs,
      landing: landing is OpenRole ? null : landing,
    );
    if (landing is OpenRole) await open(landing.role);
  }

  /// AUTH-001: remembered for the account, so it is asked once.
  Future<void> chooseUse(AppRole role) async {
    final userId = _userId;
    if (userId != null) await _preferences.setStartedAs(userId, role);
    await open(role);
  }

  /// ROL-001, with its "Always open as … on this phone" tick.
  Future<void> chooseRole(AppRole role, {required bool alwaysOpen}) async {
    final userId = _userId;
    if (userId != null) await _preferences.setAlwaysOpenAs(userId, alwaysOpen ? role : null);
    state = state.copyWith(alwaysOpenAs: alwaysOpen ? role : null);
    await open(role);
  }

  /// Opens a role's home. An *active* role the token does not act in yet is
  /// switched on the server first, because the partner routes read the
  /// token's role; a partner role still being set up opens locally.
  Future<void> open(AppRole role) async {
    final active = role == AppRole.customer || (state.held(role)?.isActive ?? false);
    if (active && state.lastActiveRole != role) {
      final switched = await _repository.setActiveRole(role);
      await _auth.replaceToken(switched.token);
      state = state.copyWith(lastActiveRole: switched.activeRole);
    }
    final userId = _userId;
    if (userId != null) await _preferences.setLastUsed(userId, role);
    state = state.copyWith(current: role, landing: null);
  }

  /// Re-reads the roles, e.g. after a partner application changes status.
  Future<void> refresh() async {
    final snapshot = await _repository.fetch();
    state = state.copyWith(roles: snapshot.roles);
  }

  void reset() {
    _userId = null;
    state = const RoleState();
  }
}
