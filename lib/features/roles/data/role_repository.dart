import '../../../core/network/api_client.dart';
import 'account_role.dart';
import 'app_role.dart';

/// The account's roles and the one last used, from `GET /app/me`.
class RoleSnapshot {
  const RoleSnapshot({required this.roles, this.lastActiveRole});

  final List<AccountRole> roles;
  final AppRole? lastActiveRole;

  factory RoleSnapshot.fromJson(Map<String, dynamic> json) => RoleSnapshot(
        roles: [
          for (final row in (json['roles'] as List? ?? const []))
            if (row is Map<String, dynamic>) ?AccountRole.fromJson(row),
        ],
        lastActiveRole: AppRole.fromName(json['lastActiveRole'] as String?),
      );
}

/// A switched session: the re-signed token the partner routes read.
class RoleSwitch {
  const RoleSwitch({required this.token, required this.activeRole});

  final String token;
  final AppRole activeRole;

  factory RoleSwitch.fromJson(Map<String, dynamic> json) => RoleSwitch(
        token: json['token'] as String? ?? '',
        activeRole: AppRole.fromName(json['activeRole'] as String?) ?? AppRole.customer,
      );
}

/// Every call about roles the app makes (partner roles T01).
abstract class RoleRepository {
  Future<RoleSnapshot> fetch();

  /// ROL-002: act as another *active* role. The server refuses (403) one that
  /// is not active.
  Future<RoleSwitch> setActiveRole(AppRole role);
}

class HttpRoleRepository implements RoleRepository {
  HttpRoleRepository(this._api);

  final ApiClient _api;

  @override
  Future<RoleSnapshot> fetch() async => RoleSnapshot.fromJson(await _api.get('/app/me'));

  @override
  Future<RoleSwitch> setActiveRole(AppRole role) async =>
      RoleSwitch.fromJson(await _api.post('/app/me/active-role', body: {'role': role.name}));
}
