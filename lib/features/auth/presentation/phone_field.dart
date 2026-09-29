import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../design/tokens.dart';
import '../../../core/i18n/app_text.dart';

/// A Tanzanian mobile number, entered the way people actually write one.
///
/// Customers type `0712345678`, `712345678` or `+255712345678` depending on
/// habit; the API accepts exactly one of those. Normalising here — in the one
/// widget that collects a number — means no screen has to remember the rule,
/// and nobody is told their own phone number is invalid because of a leading
/// zero.
class PhoneField extends StatelessWidget {
  const PhoneField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.autofocus = false,
    this.onSubmitted,
    this.label,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;
  /// Defaults to "Phone number" in the reader's language.
  final String? label;

  /// Turns whatever was typed into `+255XXXXXXXXX`, or null if it cannot be.
  static String? normalise(String input) {
    final digits = input.replaceAll(RegExp(r'[^\d]'), '');

    // 255712345678 — already international.
    if (digits.length == 12 && digits.startsWith('255')) return '+$digits';
    // 0712345678 — the national form.
    if (digits.length == 10 && digits.startsWith('0')) return '+255${digits.substring(1)}';
    // 712345678 — no prefix at all.
    if (digits.length == 9 && digits.startsWith('7')) return '+255$digits';
    return null;
  }

  static String? validate(AppText text, String? value) =>
      normalise(value ?? '') == null ? text.phoneInvalid : null;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      autofocus: autofocus,
      keyboardType: TextInputType.phone,
      autofillHints: const [AutofillHints.telephoneNumber],
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d +]')),
        LengthLimitingTextInputFormatter(16),
      ],
      textInputAction: TextInputAction.done,
      onFieldSubmitted: onSubmitted,
      validator: (value) => validate(context.text, value),
      decoration: InputDecoration(
        labelText: label ?? context.text.partnerDetailsPhone,
        hintText: '0712 345 678',
        prefixIcon: const Padding(
          padding: EdgeInsets.symmetric(horizontal: HmSpace.xxl),
          child: Text('+255', style: HmText.body),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      ),
    );
  }
}
