import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens.dart';

/// HM/Form/TextField: a label (with an optional tag) over a 44pt field on the
/// input surface, with optional leading icon, prefix, trailing icon and a hint
/// that turns into the error when there is one.
class HmTextField extends StatelessWidget {
  const HmTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.placeholder,
    this.errorText,
    this.optionalLabel,
    this.leadingIcon,
    this.prefixText,
    this.trailingIcon,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.textInputAction,
    this.onChanged,
    this.enabled = true,
    this.fieldKey,
  });

  final String label;
  final TextEditingController? controller;

  /// Shown under the field while there is no error.
  final String? hint;

  /// Greyed text inside an empty field.
  final String? placeholder;
  final String? errorText;

  /// The "Optional" tag, in whatever language the screen is in. Absent means
  /// the field is required.
  final String? optionalLabel;
  final IconData? leadingIcon;
  final String? prefixText;
  final IconData? trailingIcon;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: HmColors.textPrimary),
                ),
              ),
              if (optionalLabel != null)
                Text(optionalLabel!, style: const TextStyle(fontSize: 12, color: HmColors.textTertiary)),
            ],
          ),
          const SizedBox(height: HmSpace.sm),
          TextField(
            key: fieldKey,
            controller: controller,
            enabled: enabled,
            maxLines: maxLines,
            minLines: maxLines > 1 ? 3 : 1,
            keyboardType: maxLines > 1 ? TextInputType.multiline : keyboardType,
            inputFormatters: inputFormatters,
            textInputAction: textInputAction,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 14, color: HmColors.textPrimary),
            decoration: InputDecoration(
              isDense: true,
              hintText: placeholder,
              helperText: errorText == null ? hint : null,
              helperStyle: const TextStyle(fontSize: 12, color: HmColors.textSecondary),
              helperMaxLines: 3,
              errorText: errorText,
              errorMaxLines: 3,
              errorStyle: const TextStyle(fontSize: 12, color: HmColors.error),
              contentPadding: const EdgeInsets.symmetric(horizontal: HmSpace.xl, vertical: HmSpace.xl),
              prefixIcon: leadingIcon == null ? null : Icon(leadingIcon, size: 20, color: HmColors.textSecondary),
              prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 20),
              prefix: prefixText == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(right: HmSpace.md),
                      child: Text(
                        prefixText!,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: HmColors.textSecondary),
                      ),
                    ),
              suffixIcon: trailingIcon == null ? null : Icon(trailingIcon, size: 20, color: HmColors.textSecondary),
            ),
          ),
        ],
      );
}
