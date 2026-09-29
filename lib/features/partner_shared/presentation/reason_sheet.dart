import 'package:flutter/material.dart';

import '../../../design/tokens.dart';
import '../../../design/widgets/hm_button.dart';
import '../../../design/widgets/hm_choice.dart';
import '../../../design/widgets/hm_text_field.dart';

/// The words of one reason sheet: declining an enquiry (BRK-041b), disputing
/// a listing (LND-003).
class ReasonSheetCopy {
  const ReasonSheetCopy({
    required this.title,
    required this.body,
    required this.label,
    required this.required,
    required this.confirm,
    this.quickReasons = const [],
    this.danger = true,
  });

  final String title;
  final String body;
  final String label;

  /// Shown when the reason is left empty.
  final String required;
  final String confirm;
  final List<String> quickReasons;
  final bool danger;
}

/// Asks why. Returns the reason, or null when the sheet is dismissed.
Future<String?> showReasonSheet(BuildContext context, {required ReasonSheetCopy copy, Key? fieldKey}) =>
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ReasonSheet(copy: copy, fieldKey: fieldKey),
    );

class _ReasonSheet extends StatefulWidget {
  const _ReasonSheet({required this.copy, this.fieldKey});

  final ReasonSheetCopy copy;
  final Key? fieldKey;

  @override
  State<_ReasonSheet> createState() => _ReasonSheetState();
}

class _ReasonSheetState extends State<_ReasonSheet> {
  final _reason = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _confirm() {
    final reason = _reason.text.trim();
    if (reason.isEmpty) {
      setState(() => _error = widget.copy.required);
      return;
    }
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    final copy = widget.copy;
    return Padding(
      padding: EdgeInsets.fromLTRB(HmSpace.xxl, 0, HmSpace.xxl, MediaQuery.viewInsetsOf(context).bottom + HmSpace.xxl),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(copy.title, style: HmText.heading),
            const SizedBox(height: HmSpace.md),
            Text(copy.body, style: HmText.body),
            if (copy.quickReasons.isNotEmpty) ...[
              const SizedBox(height: HmSpace.xl),
              Wrap(
                spacing: HmSpace.sm,
                runSpacing: HmSpace.sm,
                children: [
                  for (final quick in copy.quickReasons)
                    HmChoicePill(
                      label: quick,
                      dense: true,
                      selected: _reason.text == quick,
                      onTap: () => setState(() {
                        _reason.text = quick;
                        _error = null;
                      }),
                    ),
                ],
              ),
            ],
            const SizedBox(height: HmSpace.xl),
            HmTextField(
              fieldKey: widget.fieldKey,
              label: copy.label,
              controller: _reason,
              maxLines: 3,
              errorText: _error,
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: HmSpace.xl),
            HmButton(
              label: copy.confirm,
              style: copy.danger ? HmButtonStyle.danger : HmButtonStyle.primary,
              onPressed: _confirm,
            ),
          ],
        ),
      ),
    );
  }
}
