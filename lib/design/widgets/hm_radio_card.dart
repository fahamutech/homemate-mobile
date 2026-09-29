import 'package:flutter/material.dart';

import '../tokens.dart';

/// HM/Form/RadioCard: a big pick-one option with an icon — the role choice,
/// "How will you use HomeMate?", an enquiry's outcome.
class HmRadioCard extends StatelessWidget {
  const HmRadioCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.badge,
    this.details = const [],
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;

  /// Usually an [HmBadge] — "Active", "Waiting for review".
  final Widget? badge;

  /// Ticked points under the option — what a role lets you do (ROL-004).
  final List<String> details;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    return Semantics(
      button: true,
      checked: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            key: ValueKey('radio-card-$title'),
            padding: const EdgeInsets.all(HmSpace.xxl),
            decoration: BoxDecoration(
              color: selected ? HmColors.brandSubtle : HmColors.bgPrimary,
              borderRadius: radius,
              border: Border.all(
                color: selected
                    ? HmColors.brandPrimary
                    : HmColors.borderDefault,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: selected
                            ? HmColors.bgPrimary
                            : HmColors.brandSubtle,
                        borderRadius: BorderRadius.circular(HmRadius.md),
                      ),
                      child: Icon(icon, size: 24, color: HmColors.brandPrimary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: HmColors.textPrimary,
                            ),
                          ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 18 / 13,
                                color: HmColors.textSecondary,
                              ),
                            ),
                          ],
                          if (badge != null) ...[
                            const SizedBox(height: HmSpace.sm),
                            badge!,
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: HmSpace.md),
                    Icon(
                      selected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 22,
                      color: selected
                          ? HmColors.brandPrimary
                          : HmColors.borderStrong,
                    ),
                  ],
                ),
                for (final point in details) ...[
                  const SizedBox(height: HmSpace.lg),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: HmColors.brandPrimary,
                      ),
                      const SizedBox(width: HmSpace.md),
                      Expanded(
                        child: Text(
                          point,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 20 / 14,
                            color: HmColors.textBody,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
