import 'package:flutter/material.dart';

import '../tokens.dart';

/// Figma HM/Data/KeyValue emphasis: Default and Strong for detail rows, Total
/// and Brand for the bottom line of a breakdown.
enum HmKeyValueEmphasis { normal, strong, total, brand }

/// A label on the left, its value on the right.
///
/// [HmDetailRow] (hm_section.dart) is the customer screens' version of the
/// same row and stays as it is.
class HmKeyValue extends StatelessWidget {
  const HmKeyValue({super.key, required this.label, required this.value, this.emphasis = HmKeyValueEmphasis.normal});

  final String label;
  final String value;
  final HmKeyValueEmphasis emphasis;

  @override
  Widget build(BuildContext context) {
    final labelColour = switch (emphasis) {
      HmKeyValueEmphasis.normal || HmKeyValueEmphasis.strong => HmColors.textSecondary,
      HmKeyValueEmphasis.total || HmKeyValueEmphasis.brand => HmColors.textPrimary,
    };
    final valueColour = emphasis == HmKeyValueEmphasis.brand ? HmColors.brandPrimary : HmColors.textPrimary;
    final valueWeight = emphasis == HmKeyValueEmphasis.normal ? FontWeight.w500 : FontWeight.w600;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: HmSpace.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: labelColour))),
          const SizedBox(width: HmSpace.xl),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 14, fontWeight: valueWeight, color: valueColour),
            ),
          ),
        ],
      ),
    );
  }
}
