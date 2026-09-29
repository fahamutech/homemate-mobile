import 'package:flutter/material.dart';

import '../tokens.dart';
import '../../core/i18n/app_text.dart';
import '../../core/network/error_text.dart';

/// Telling the user how an action went.
///
/// A screen should not have to remember the colour for a failure or how to
/// pull a message out of an exception, so both live here.
class HmFeedback {
  const HmFeedback._();

  static void success(BuildContext context, String message) =>
      _show(context, message, HmColors.success, Icons.check_circle_outline);

  static void failure(BuildContext context, Object error) => _show(
        context,
        errorText(context.text, error),
        HmColors.error,
        Icons.error_outline,
      );

  static void info(BuildContext context, String message) =>
      _show(context, message, HmColors.textPrimary, Icons.info_outline);

  static void _show(BuildContext context, String message, Color accent, IconData icon) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: accent, size: 20),
              const SizedBox(width: HmSpace.xl),
              Expanded(child: Text(message)),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );
  }
}

/// An inline error inside a form, where a snackbar would be missed.
class HmInlineError extends StatelessWidget {
  const HmInlineError(this.message, {super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: HmSpace.xxl),
      padding: const EdgeInsets.all(HmSpace.xl),
      decoration: BoxDecoration(
        color: HmColors.error.withValues(alpha: 0.08),
        borderRadius: HmRadius.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: HmColors.error, size: 18),
          const SizedBox(width: HmSpace.lg),
          Expanded(
            child: Text(
              message!,
              // Announced by a screen reader the moment it appears, rather
              // than only being found by someone re-reading the form.
              semanticsLabel: context.text.errorAnnounce(message!),
              style: HmText.caption.copyWith(color: HmColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
