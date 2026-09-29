import 'package:flutter/material.dart';

import '../tokens.dart';

/// The pill the designs use everywhere a choice is made — property type,
/// bedrooms, timeline, the home screen's category row.
///
/// Material's own `ChoiceChip` is close but not the same shape: the designs
/// use a fully rounded pill with a filled brand state and no check mark, and
/// having one widget for it means the filter sheet, the onboarding steps and
/// the home screen cannot drift apart a pixel at a time.
class HmChoicePill extends StatelessWidget {
  const HmChoicePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.dense = false,
    this.showCheck = false,
    this.count,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool dense;

  /// HM/Form/Chip's check mark, shown while selected.
  final bool showCheck;

  /// HM/Form/Chip's count bubble — "Pending 3".
  final int? count;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? HmColors.textOnBrand : HmColors.textPrimary;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? HmColors.brandPrimary : HmColors.bgPrimary,
        borderRadius: BorderRadius.circular(HmRadius.pill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(HmRadius.pill),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: dense ? HmSpace.xl : HmSpace.xxl,
              vertical: dense ? HmSpace.md : HmSpace.xl,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(HmRadius.pill),
              border: Border.all(
                color: selected ? HmColors.brandPrimary : HmColors.borderDefault,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showCheck && selected) ...[
                  Icon(Icons.check_rounded, size: 16, color: foreground),
                  const SizedBox(width: HmSpace.sm),
                ] else if (icon != null) ...[
                  Icon(icon, size: 16, color: foreground),
                  const SizedBox(width: HmSpace.sm),
                ],
                Text(
                  label,
                  style: HmText.label.copyWith(
                    color: foreground,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: HmSpace.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: HmSpace.sm),
                    decoration: BoxDecoration(
                      color: selected ? HmColors.bgPrimary : HmColors.surfaceInput,
                      borderRadius: BorderRadius.circular(HmRadius.pill),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: HmColors.brandPrimary,
                      ),
                    ),
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

/// A row of pills that behave as one segmented control — "Any / Studio / 1 / 2
/// / 3 / 4+" in the filter and the onboarding steps.
class HmSegmentedPills<T> extends StatelessWidget {
  const HmSegmentedPills({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.optionKey,
  });

  /// Value / label pairs, in the order they should read.
  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;

  /// A key for each option's tap target, for a screen that is driven by tests.
  final Key Function(T option)? optionKey;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(HmSpace.xs),
        decoration: BoxDecoration(
          color: HmColors.surfaceInput,
          borderRadius: BorderRadius.circular(HmRadius.md),
        ),
        child: Row(
          children: [
            for (final (option, label) in options)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: option == value,
                  child: InkWell(
                    key: optionKey?.call(option),
                    onTap: () => onChanged(option),
                    borderRadius: BorderRadius.circular(HmRadius.sm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: HmSpace.xl),
                      decoration: BoxDecoration(
                        color: option == value ? HmColors.brandPrimary : Colors.transparent,
                        borderRadius: BorderRadius.circular(HmRadius.sm),
                      ),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: HmText.label.copyWith(
                          color: option == value ? HmColors.textOnBrand : HmColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}

/// A labelled checkbox in a soft tile — the amenities grid in both the filter
/// sheet and the onboarding preferences step.
class HmCheckTile extends StatelessWidget {
  const HmCheckTile({
    super.key,
    required this.label,
    required this.checked,
    required this.onChanged,
  });

  final String label;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
        checked: checked,
        child: InkWell(
          onTap: () => onChanged(!checked),
          borderRadius: HmRadius.card,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: HmSpace.xl,
              vertical: HmSpace.xl,
            ),
            decoration: BoxDecoration(
              color: checked ? HmColors.brandPrimarySoft : HmColors.bgSecondary,
              borderRadius: HmRadius.card,
              border: Border.all(
                color: checked ? HmColors.brandPrimary : HmColors.borderDefault,
              ),
            ),
            child: Row(
              children: [
                _Box(checked: checked),
                const SizedBox(width: HmSpace.xl),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HmText.label.copyWith(
                      color: checked ? HmColors.brandPrimaryDark : HmColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _Box extends StatelessWidget {
  const _Box({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) => Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: checked ? HmColors.brandPrimary : HmColors.bgPrimary,
          borderRadius: BorderRadius.circular(HmRadius.sm / 2),
          border: Border.all(color: checked ? HmColors.brandPrimary : HmColors.borderStrong),
        ),
        child: checked
            ? const Icon(Icons.check, size: 14, color: HmColors.textOnBrand)
            : null,
      );
}

/// The "STEP 2 OF 3" heading and its progress bars.
class HmStepHeader extends StatelessWidget {
  const HmStepHeader({super.key, required this.step, required this.of});

  final int step;
  final int of;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STEP $step OF $of',
            style: HmText.label.copyWith(
              color: HmColors.brandPrimary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: HmSpace.md),
          Row(
            children: [
              for (var index = 1; index <= of; index++) ...[
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: index <= step ? HmColors.brandPrimary : HmColors.borderDefault,
                      borderRadius: BorderRadius.circular(HmRadius.pill),
                    ),
                  ),
                ),
                if (index < of) const SizedBox(width: HmSpace.md),
              ],
            ],
          ),
        ],
      );
}
