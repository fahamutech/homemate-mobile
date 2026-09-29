import 'package:flutter/material.dart';

import '../tokens.dart';
import 'hm_card_surface.dart';

/// HM/Partner/StatCard: a small number tile on partner homes and money screens.
class HmStatCard extends StatelessWidget {
  const HmStatCard({super.key, required this.label, required this.value, this.sub, this.onTap});

  final String label;
  final String value;
  final String? sub;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => HmCardSurface(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Two lines: "Earned this month" does not fit a third of a phone.
            Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: HmColors.textSecondary)),
            const SizedBox(height: HmSpace.xs),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: HmColors.textPrimary)),
            ),
            if (sub != null) ...[
              const SizedBox(height: HmSpace.xs),
              Text(sub!, style: const TextStyle(fontSize: 11, color: HmColors.textSecondary)),
            ],
          ],
        ),
      );
}
