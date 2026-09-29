import 'package:flutter/material.dart';

import '../tokens.dart';

/// HM/Form/StepProgress: "STEP 2 OF 6 · DOCUMENTS" over one bar per step.
///
/// The label is the caller's, already translated; this only draws it.
class HmStepProgress extends StatelessWidget {
  const HmStepProgress({super.key, required this.current, required this.total, this.label})
      : assert(total > 0 && current >= 0 && current <= total);

  final int current;
  final int total;
  final String? label;

  @override
  Widget build(BuildContext context) => Semantics(
        value: '$current / $total',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label != null) ...[
              Text(
                label!,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: HmColors.brandPrimary),
              ),
              const SizedBox(height: HmSpace.md),
            ],
            Row(
              children: [
                for (var step = 1; step <= total; step++) ...[
                  Expanded(
                    child: Container(
                      key: ValueKey(step <= current ? 'step-done' : 'step-todo'),
                      height: 6,
                      decoration: BoxDecoration(
                        color: step <= current ? HmColors.brandPrimary : HmColors.borderDefault,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  if (step < total) const SizedBox(width: HmSpace.sm),
                ],
              ],
            ),
          ],
        ),
      );
}
