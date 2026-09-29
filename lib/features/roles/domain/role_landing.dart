import '../data/account_role.dart';
import '../data/app_role.dart';

/// Where a signed-in person lands (Figma AUTH-000, lane 2).
sealed class RoleLanding {
  const RoleLanding();
}

/// AUTH-001 "How will you use HomeMate?".
class ChooseUse extends RoleLanding {
  const ChooseUse();

  @override
  bool operator ==(Object other) => other is ChooseUse;

  @override
  int get hashCode => 0;
}

/// ROL-001 "Choose how to continue".
class ChooseRole extends RoleLanding {
  const ChooseRole({required this.preselected});

  final AppRole preselected;

  @override
  bool operator ==(Object other) => other is ChooseRole && other.preselected == preselected;

  @override
  int get hashCode => preselected.hashCode;

  @override
  String toString() => 'ChooseRole($preselected)';
}

/// Straight to that role's home.
class OpenRole extends RoleLanding {
  const OpenRole(this.role);

  final AppRole role;

  @override
  bool operator ==(Object other) => other is OpenRole && other.role == role;

  @override
  int get hashCode => role.hashCode;

  @override
  String toString() => 'OpenRole($role)';
}

/// The roles whose home this person can open, customer first.
///
/// [startedAs] is the answer to AUTH-001: a new broker or landlord has no
/// application yet, but their home (which starts one) must open all the same.
List<AppRole> openableRoles(List<AccountRole> roles, {AppRole? startedAs}) {
  final byRole = {for (final role in roles) role.role: role};
  return AppRole.values.where((role) {
    if (role == AppRole.customer) return true;
    final held = byRole[role];
    if (held != null) return held.canOpen;
    return startedAs == role;
  }).toList();
}

/// Decides AUTH-001, ROL-001 or a home, from the account's roles and what
/// this phone remembers.
///
/// Every account holds the customer role, but someone who never finished the
/// customer profile ([isNewAccount]) and holds a partner role is a partner
/// from day one: only their partner roles count, so a broker with one role
/// opens straight on the broker home.
RoleLanding decideLanding({
  required List<AccountRole> roles,
  required bool isNewAccount,
  AppRole? startedAs,
  AppRole? alwaysOpenAs,
  AppRole? lastUsed,
}) {
  final holdsPartnerRole = roles.any((role) => role.role.isPartner);
  if (isNewAccount && startedAs == null && !holdsPartnerRole) return const ChooseUse();

  final openable = openableRoles(roles, startedAs: startedAs);
  final partners = openable.where((role) => role.isPartner).toList();
  final inUse = isNewAccount && partners.isNotEmpty ? partners : openable;

  // Mid-way through the setup they picked at first launch: back to it.
  final holdsActivePartnerRole = roles.any((role) => role.role.isPartner && role.isActive);
  if (startedAs != null && startedAs.isPartner && !holdsActivePartnerRole && inUse.contains(startedAs)) {
    return OpenRole(startedAs);
  }
  if (alwaysOpenAs != null && inUse.contains(alwaysOpenAs)) return OpenRole(alwaysOpenAs);
  if (inUse.length == 1) return OpenRole(inUse.single);
  return ChooseRole(preselected: inUse.contains(lastUsed) ? lastUsed! : inUse.first);
}

/// The role the server put in the session token: the last one used if still
/// active, else customer — `pickActiveRole` in homemate-functions.
AppRole serverActiveRole(List<AccountRole> roles, AppRole? lastActiveRole) {
  final active = roles.any((role) => role.role == lastActiveRole && role.isActive);
  return active ? lastActiveRole! : AppRole.customer;
}
