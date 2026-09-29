import 'app_role.dart';

/// One of the account's roles as `GET /app/me` reports it.
class AccountRole {
  const AccountRole({
    required this.role,
    required this.status,
    this.appliedAt,
    this.activatedAt,
    this.rejectionReason,
  });

  final AppRole role;

  /// `active`, or for a partner role: `invited`, `applied`, `pending_review`,
  /// `action_needed`, `rejected`, `suspended`.
  final String status;
  final DateTime? appliedAt;
  final DateTime? activatedAt;
  final String? rejectionReason;

  bool get isActive => status == 'active';

  /// Statuses whose shell opens. A partner still applying or under review
  /// lands on their partner home, which shows it "before verification".
  static const _openable = {'active', 'applied', 'pending_review', 'action_needed'};

  bool get canOpen => role == AppRole.customer || _openable.contains(status);

  /// Null for a role the app does not know (agency) — it is skipped.
  static AccountRole? fromJson(Map<String, dynamic> json) {
    final role = AppRole.fromName(json['role'] as String?);
    if (role == null) return null;
    return AccountRole(
      role: role,
      status: json['status'] as String? ?? 'active',
      appliedAt: DateTime.tryParse('${json['appliedAt'] ?? ''}'),
      activatedAt: DateTime.tryParse('${json['activatedAt'] ?? ''}'),
      rejectionReason: json['rejectionReason'] as String?,
    );
  }
}
