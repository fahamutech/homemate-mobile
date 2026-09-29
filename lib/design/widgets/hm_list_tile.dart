import 'package:flutter/material.dart';

import '../tokens.dart';
import 'hm_icon_box.dart';

/// HM/List/ListTile: a profile or settings row — icon (plain or boxed), title,
/// optional subtitle, badge, value and trailing icon.
class HmListTile extends StatelessWidget {
  const HmListTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.boxed = false,
    this.badge,
    this.value,
    this.trailingIcon = Icons.chevron_right_rounded,
    this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool boxed;
  final Widget? badge;
  final String? value;

  /// Null hides it.
  final IconData? trailingIcon;
  final VoidCallback? onTap;

  /// Sign out and the like: the title and icon in red.
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final accent = destructive ? HmColors.error : HmColors.brandPrimary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: HmSpace.xxl, vertical: HmSpace.xl),
        child: Row(
          children: [
            if (boxed)
              HmIconBox(
                key: const ValueKey('list-tile-box'),
                icon: icon,
                colour: accent,
                fill: destructive ? HmColors.redBg : HmColors.brandSubtle,
              )
            else
              Icon(icon, size: 22, color: destructive ? HmColors.error : HmColors.textPrimary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: destructive ? HmColors.error : HmColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: HmSpace.xxs),
                    Text(subtitle!, style: const TextStyle(fontSize: 12, height: 16 / 12, color: HmColors.textSecondary)),
                  ],
                ],
              ),
            ),
            if (badge != null) ...[const SizedBox(width: HmSpace.md), badge!],
            if (value != null) ...[
              const SizedBox(width: HmSpace.md),
              Text(value!, style: const TextStyle(fontSize: 13, color: HmColors.textSecondary)),
            ],
            if (trailingIcon != null) ...[
              const SizedBox(width: HmSpace.md),
              Icon(trailingIcon, size: 18, color: HmColors.textTertiary),
            ],
          ],
        ),
      ),
    );
  }
}
