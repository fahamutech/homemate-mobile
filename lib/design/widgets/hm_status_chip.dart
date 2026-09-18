import 'package:flutter/material.dart';

import '../tokens.dart';

/// A status, shown the same way everywhere.
///
/// The backend speaks in `awaiting_payment` and `pending_review`; a person
/// should read "Awaiting payment". Doing that conversion here means no screen
/// carries its own half-complete map of statuses to words.
class HmStatusChip extends StatelessWidget {
  const HmStatusChip(this.status, {super.key, this.dense = false});

  final String status;
  final bool dense;

  static String humanise(String value) {
    if (value.isEmpty) return value;
    final words = value.replaceAll('_', ' ');
    return words[0].toUpperCase() + words.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final colour = HmColors.forStatus(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? HmSpace.md : HmSpace.lg,
        vertical: dense ? HmSpace.xxs : HmSpace.xs,
      ),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(HmRadius.pill),
      ),
      child: Text(
        humanise(status),
        style: HmText.caption.copyWith(
          color: colour,
          fontWeight: FontWeight.w600,
          fontSize: dense ? 11 : 12,
        ),
      ),
    );
  }
}
