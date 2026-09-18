import 'package:flutter/material.dart';

import '../tokens.dart';

/// "Tell us why" — the dialog used wherever an action needs a reason.
///
/// It exists because the alternative kept going wrong: a caller creating a
/// `TextEditingController`, awaiting `showDialog`, then disposing it. That
/// future completes when the route is popped, but the dialog is still
/// animating out and its `TextField` rebuilds against a disposed controller.
/// Owning the controller inside a stateful dialog removes the race entirely,
/// and removes four near-identical copies of this dialog with it.
class HmPrompt extends StatefulWidget {
  const HmPrompt({
    super.key,
    required this.title,
    required this.confirmLabel,
    this.message,
    this.fieldLabel = 'Reason',
    this.hintText,
    this.cancelLabel = 'Cancel',
    this.destructive = false,
    this.required = true,
    this.capitalise = TextCapitalization.sentences,
  });

  final String title;
  final String confirmLabel;
  final String? message;
  final String fieldLabel;
  final String? hintText;
  final String cancelLabel;
  final bool destructive;

  /// When false, confirming with an empty field is allowed and returns ''.
  final bool required;
  final TextCapitalization capitalise;

  /// Returns what was typed, or null if the person backed out.
  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String confirmLabel,
    String? message,
    String fieldLabel = 'Reason',
    String? hintText,
    String cancelLabel = 'Cancel',
    bool destructive = false,
    bool required = true,
    TextCapitalization capitalise = TextCapitalization.sentences,
  }) =>
      showDialog<String>(
        context: context,
        builder: (_) => HmPrompt(
          title: title,
          confirmLabel: confirmLabel,
          message: message,
          fieldLabel: fieldLabel,
          hintText: hintText,
          cancelLabel: cancelLabel,
          destructive: destructive,
          required: required,
          capitalise: capitalise,
        ),
      );

  @override
  State<HmPrompt> createState() => _HmPromptState();
}

class _HmPromptState extends State<HmPrompt> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final value = _controller.text.trim();
    if (widget.required && value.isEmpty) {
      setState(() => _error = 'Please say why');
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.message != null) ...[
              Text(widget.message!, style: HmText.body),
              const SizedBox(height: HmSpace.xxl),
            ],
            TextField(
              controller: _controller,
              autofocus: true,
              maxLines: 3,
              minLines: 1,
              textCapitalization: widget.capitalise,
              onSubmitted: (_) => _confirm(),
              decoration: InputDecoration(
                labelText: widget.fieldLabel,
                hintText: widget.hintText,
                errorText: _error,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(
          onPressed: _confirm,
          style: widget.destructive
              ? FilledButton.styleFrom(backgroundColor: HmColors.error)
              : null,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

/// A yes/no with no text to collect.
class HmConfirm {
  const HmConfirm._();

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    String cancelLabel = 'Cancel',
    bool destructive = false,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(message, style: HmText.body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(cancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: destructive
                  ? FilledButton.styleFrom(backgroundColor: HmColors.error)
                  : null,
              child: Text(confirmLabel),
            ),
          ],
        ),
      ) ??
      false;
}
