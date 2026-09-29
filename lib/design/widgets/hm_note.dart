import 'package:flutter/material.dart';

import '../tokens.dart';

/// HM/Feedback/Note tones: tint, edge and icon colour. The body text is the
/// same grey in all of them.
enum HmNoteTone {
  neutral(HmColors.surfaceInput, HmColors.borderDefault, HmColors.textSecondary, Icons.info_outline_rounded),
  brand(HmColors.brandSubtle, HmColors.brandBorder, HmColors.brandPrimary, Icons.info_outline_rounded),
  success(HmColors.greenBg, HmColors.success, HmColors.success, Icons.check_circle_outline_rounded),
  warning(HmColors.orangeBg, HmColors.orangeBorder, HmColors.orangeAccent, Icons.warning_amber_rounded),
  info(HmColors.blueBg, HmColors.blueBorder, HmColors.info, Icons.info_outline_rounded);

  const HmNoteTone(this.fill, this.border, this.icon, this.defaultIcon);

  final Color fill;
  final Color border;
  final Color icon;
  final IconData defaultIcon;
}

/// HM/Feedback/Note: an inline notice. [HmNotice] (hm_section.dart) is the
/// customer screens' older warning-only version.
class HmNote extends StatelessWidget {
  const HmNote({super.key, required this.text, this.tone = HmNoteTone.neutral, this.icon, this.action});

  final String text;
  final HmNoteTone tone;
  final IconData? icon;

  /// A link or button under the text — "Upload again".
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(HmSpace.xl),
        decoration: BoxDecoration(
          color: tone.fill,
          borderRadius: BorderRadius.circular(HmRadius.md),
          border: Border.all(color: tone.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon ?? tone.defaultIcon, size: 18, color: tone.icon),
            const SizedBox(width: HmSpace.xl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(text, style: const TextStyle(fontSize: 13, height: 18 / 13, color: HmColors.textBody)),
                  if (action != null) ...[const SizedBox(height: HmSpace.md), action!],
                ],
              ),
            ),
          ],
        ),
      );
}
