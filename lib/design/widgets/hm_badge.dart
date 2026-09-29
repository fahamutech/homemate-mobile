import 'package:flutter/material.dart';

import '../tokens.dart';

/// Figma `Badge`: Success, Warning, Error, Info, Neutral and Primary.
enum HmBadgeTone {
  success(HmColors.greenBg, HmColors.greenText),
  warning(HmColors.amberBg, HmColors.amberText),
  error(HmColors.redBg, HmColors.redText),
  info(HmColors.infoBg, HmColors.infoText),
  neutral(HmColors.surfaceInput, HmColors.textBody),
  primary(HmColors.successSubtle, HmColors.brandPrimaryDark);

  const HmBadgeTone(this.fill, this.text);

  final Color fill;
  final Color text;
}

/// The tone a server status reads in, the same on every partner screen.
HmBadgeTone badgeToneForStatus(String status) => switch (status) {
      'active' || 'approved' || 'confirmed' || 'verified' || 'successful' || 'paid' ||
      'completed' || 'accepted' || 'current' || 'live' =>
        HmBadgeTone.success,
      'pending' || 'pending_review' || 'action_needed' || 'changes_requested' ||
      'awaiting_payment' || 'awaiting_verification' || 'moving_in' || 'on_hold' || 'held' =>
        HmBadgeTone.warning,
      'rejected' || 'cancelled' || 'failed' || 'expired' || 'suspended' || 'disputed' =>
        HmBadgeTone.error,
      'in_review' || 'submitted' || 'responded' || 'processing' || 'applied' || 'invited' =>
        HmBadgeTone.info,
      _ => HmBadgeTone.neutral,
    };

/// A short status label in a tinted pill, with an optional leading icon.
class HmBadge extends StatelessWidget {
  const HmBadge({super.key, required this.label, this.tone = HmBadgeTone.neutral, this.icon});

  final String label;
  final HmBadgeTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: HmSpace.lg, vertical: HmSpace.xs),
        decoration: BoxDecoration(
          color: tone.fill,
          borderRadius: BorderRadius.circular(HmRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: tone.text),
              const SizedBox(width: HmSpace.xs),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tone.text),
              ),
            ),
          ],
        ),
      );
}
