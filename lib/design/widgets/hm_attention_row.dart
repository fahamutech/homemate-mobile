import 'package:flutter/material.dart';

import '../tokens.dart';
import 'hm_icon_box.dart';

/// What kind of work an attention row is, by colour.
enum HmAttentionTone {
  orange(HmColors.orangeBg, HmColors.orangeText),
  red(HmColors.redBg, HmColors.redText),
  blue(HmColors.blueBg, HmColors.blueText),
  green(HmColors.greenBg, HmColors.greenText);

  const HmAttentionTone(this.fill, this.icon);

  final Color fill;
  final Color icon;
}

/// HM/Partner/AttentionRow: one item in a partner home's "Needs you" list.
class HmAttentionRow extends StatelessWidget {
  const HmAttentionRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tone,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final HmAttentionTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HmRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(HmSpace.xl),
          child: Row(
            children: [
              HmIconBox(key: const ValueKey('attention-icon'), icon: icon, fill: tone.fill, colour: tone.icon),
              const SizedBox(width: HmSpace.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: HmColors.textPrimary)),
                    const SizedBox(height: HmSpace.xxs),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: HmColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 18, color: HmColors.textTertiary),
            ],
          ),
        ),
      );
}
