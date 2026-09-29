import '../core/i18n/app_text.dart';

/// The words for a status, frequency or purpose code the API sends
/// (`awaiting_payment` → "Awaiting payment" / "Inasubiri malipo").
///
/// A code with no translation yet is still made readable rather than shown
/// raw, so a new backend state degrades to English words, not to snake_case.
String statusLabel(AppText text, String code) => text.status(code) ?? humanise(code);

/// `awaiting_payment` → "Awaiting payment".
String humanise(String code) {
  if (code.isEmpty) return code;
  final words = code.replaceAll('_', ' ');
  return words[0].toUpperCase() + words.substring(1);
}
