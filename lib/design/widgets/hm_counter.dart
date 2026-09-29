import 'package:flutter/material.dart';

import '../tokens.dart';

/// A whole number stepped with − and + (bedrooms, months of deposit…), with
/// its label above, as the add-a-home steps draw it.
class HmCounter extends StatelessWidget {
  const HmCounter({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 99,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    Widget button(IconData icon, String tooltip, int? next, {required bool brand}) => IconButton(
          tooltip: '$tooltip $label',
          onPressed: next == null ? null : () => onChanged(next),
          style: IconButton.styleFrom(
            backgroundColor: brand ? HmColors.brandSubtle : HmColors.surfaceInput,
            foregroundColor: brand ? HmColors.brandPrimary : HmColors.textPrimary,
            minimumSize: const Size(36, 36),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(HmRadius.sm)),
          ),
          icon: Icon(icon, size: 18),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: HmColors.textPrimary)),
        const SizedBox(height: HmSpace.sm),
        Container(
          padding: const EdgeInsets.all(HmSpace.xs),
          decoration: BoxDecoration(
            color: HmColors.bgPrimary,
            borderRadius: BorderRadius.circular(HmRadius.md),
            border: Border.all(color: HmColors.borderDefault),
          ),
          child: Row(
            children: [
              button(Icons.remove_rounded, 'Decrease', value > min ? value - 1 : null, brand: false),
              Expanded(
                child: Text('$value',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: HmColors.textPrimary)),
              ),
              button(Icons.add_rounded, 'Increase', value < max ? value + 1 : null, brand: true),
            ],
          ),
        ),
      ],
    );
  }
}
