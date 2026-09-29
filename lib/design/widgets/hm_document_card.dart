import 'package:flutter/material.dart';

import '../tokens.dart';
import 'hm_button.dart';
import 'hm_card_surface.dart';
import 'hm_icon_box.dart';

/// HM/Partner/DocumentCard: an identity or ownership document in partner
/// setup, with its status and, while it is still wanted, an upload button.
class HmDocumentCard extends StatelessWidget {
  const HmDocumentCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.status,
    this.actionLabel,
    this.actionIcon = Icons.upload_rounded,
    this.onAction,
    this.busy = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget? status;
  final String? actionLabel;
  final IconData actionIcon;
  final VoidCallback? onAction;
  final bool busy;

  @override
  Widget build(BuildContext context) => HmCardSurface(
        padding: const EdgeInsets.all(HmSpace.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                HmIconBox(icon: icon, size: 40, iconSize: 22),
                const SizedBox(width: HmSpace.xl),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: HmColors.textPrimary)),
                      const SizedBox(height: HmSpace.xxs),
                      Text(description, style: const TextStyle(fontSize: 12, height: 16 / 12, color: HmColors.textSecondary)),
                    ],
                  ),
                ),
                if (status != null) ...[const SizedBox(width: HmSpace.md), status!],
              ],
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: HmSpace.xl),
              HmButton(
                label: actionLabel!,
                icon: actionIcon,
                style: HmButtonStyle.outline,
                size: HmButtonSize.medium,
                busy: busy,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      );
}
