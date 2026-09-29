import 'package:flutter/material.dart';

import '../tokens.dart';

/// HM/Form/Segmented: pick one of two or three on a grey track, the choice
/// lifted onto white. Used for payout method, listing type and the like.
///
/// [HmSegmentedPills] (hm_choice.dart) is the older, filled-teal version the
/// customer filter still uses.
class HmSegmented<T> extends StatelessWidget {
  const HmSegmented({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.label,
    this.hint,
  });

  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;
  final String? label;
  final String? hint;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null) ...[
            Text(label!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: HmColors.textPrimary)),
            const SizedBox(height: HmSpace.sm),
          ],
          Container(
            padding: const EdgeInsets.all(HmSpace.xs),
            decoration: BoxDecoration(
              color: HmColors.surfaceInput,
              borderRadius: BorderRadius.circular(HmRadius.md),
              border: Border.all(color: HmColors.borderDefault),
            ),
            child: Row(
              children: [
                for (final (index, (option, text)) in options.indexed) ...[
                  if (index > 0) const SizedBox(width: HmSpace.xs),
                  Expanded(child: _Segment(
                    key: ValueKey('segment-$option'),
                    label: text,
                    selected: option == value,
                    onTap: () => onChanged(option),
                  )),
                ],
              ],
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: HmSpace.sm),
            Text(hint!, style: const TextStyle(fontSize: 12, height: 16 / 12, color: HmColors.textSecondary)),
          ],
        ],
      );
}

class _Segment extends StatelessWidget {
  const _Segment({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        inMutuallyExclusiveGroup: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            height: 36,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: HmSpace.sm),
            decoration: BoxDecoration(
              color: selected ? HmColors.bgPrimary : Colors.transparent,
              borderRadius: BorderRadius.circular(HmRadius.sm),
              boxShadow: selected
                  ? const [BoxShadow(color: HmColors.shadowSoft, blurRadius: 3, offset: Offset(0, 1))]
                  : null,
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? HmColors.textPrimary : HmColors.textSecondary,
              ),
            ),
          ),
        ),
      );
}
