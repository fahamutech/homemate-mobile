import 'package:flutter/material.dart';

import '../tokens.dart';

/// HM/Partner/RoleHeader: the top of a partner home — avatar, greeting, the
/// role chip that opens the role switcher (ROL-002), and the bell.
class HmRoleHeader extends StatelessWidget {
  const HmRoleHeader({
    super.key,
    required this.greeting,
    required this.initials,
    required this.roleLabel,
    required this.roleIcon,
    this.avatar,
    this.onSwitchRole,
    this.onNotifications,
    this.notificationsTooltip,
    this.unreadCount = 0,
  });

  final String greeting;
  final String initials;
  final String roleLabel;
  final IconData roleIcon;

  /// A photo, when there is one; otherwise the initials.
  final Widget? avatar;

  /// Null when the person has only one role, so there is nothing to switch to.
  final VoidCallback? onSwitchRole;
  final VoidCallback? onNotifications;
  final String? notificationsTooltip;
  final int unreadCount;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: HmSpace.xxl, vertical: HmSpace.xl),
        decoration: const BoxDecoration(
          color: HmColors.bgPrimary,
          border: Border(bottom: BorderSide(color: HmColors.borderDefault)),
        ),
        child: Row(
          children: [
            ClipOval(
              child: Container(
                width: 44,
                height: 44,
                color: HmColors.brandSubtle,
                alignment: Alignment.center,
                child: avatar ??
                    Text(
                      initials,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: HmColors.brandPrimary),
                    ),
              ),
            ),
            const SizedBox(width: HmSpace.xl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    greeting,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: HmColors.textPrimary),
                  ),
                  const SizedBox(height: HmSpace.xs),
                  _RoleChip(label: roleLabel, icon: roleIcon, onTap: onSwitchRole),
                ],
              ),
            ),
            if (onNotifications != null)
              IconButton(
                onPressed: onNotifications,
                tooltip: notificationsTooltip,
                icon: Badge(
                  isLabelVisible: unreadCount > 0,
                  backgroundColor: HmColors.error,
                  label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
                  child: const Icon(Icons.notifications_outlined, size: 24, color: HmColors.textPrimary),
                ),
              ),
          ],
        ),
      );
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: onTap != null,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(HmRadius.pill),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: HmSpace.md, vertical: 3),
            decoration: BoxDecoration(
              color: HmColors.brandSubtle,
              borderRadius: BorderRadius.circular(HmRadius.pill),
              border: Border.all(color: HmColors.brandBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: HmColors.brandPrimary),
                const SizedBox(width: HmSpace.xs),
                Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: HmColors.brandPrimary)),
                if (onTap != null) ...[
                  const SizedBox(width: HmSpace.xs),
                  const Icon(Icons.expand_more_rounded, size: 16, color: HmColors.brandPrimary),
                ],
              ],
            ),
          ),
        ),
      );
}
