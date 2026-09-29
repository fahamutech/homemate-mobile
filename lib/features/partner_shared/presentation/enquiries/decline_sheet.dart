import 'package:flutter/material.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../design/tokens.dart';
import '../../../../design/widgets/hm_button.dart';
import '../../../../design/widgets/hm_choice.dart';
import '../../../../design/widgets/hm_text_field.dart';

/// BRK-041b: why the partner is declining. Returns the reason, or null when
/// the sheet is dismissed.
Future<String?> showDeclineSheet(BuildContext context, {required String customerName}) =>
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _DeclineSheet(customerName: customerName),
    );

/// The quick reasons, in the order the sheet offers them.
List<String> quickDeclineReasons(AppText text) => [
      text.declineQuickUnavailable,
      text.declineQuickDate,
      text.declineQuickBudget,
      text.declineQuickPeople,
    ];

class _DeclineSheet extends StatefulWidget {
  const _DeclineSheet({required this.customerName});

  final String customerName;

  @override
  State<_DeclineSheet> createState() => _DeclineSheetState();
}

class _DeclineSheetState extends State<_DeclineSheet> {
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
      setState(() => _error = context.text.declineRequired);
      return;
    }
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    return Padding(
      padding: EdgeInsets.fromLTRB(HmSpace.xxl, 0, HmSpace.xxl, MediaQuery.viewInsetsOf(context).bottom + HmSpace.xxl),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(text.declineTitle, style: HmText.heading),
            const SizedBox(height: HmSpace.md),
            Text(text.declineBody(widget.customerName), style: HmText.body),
            const SizedBox(height: HmSpace.xl),
            Wrap(
              spacing: HmSpace.sm,
              runSpacing: HmSpace.sm,
              children: [
                for (final quick in quickDeclineReasons(text))
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
            const SizedBox(height: HmSpace.xl),
            HmTextField(
              fieldKey: const ValueKey('decline-reason'),
              label: text.declineReason,
              controller: _reason,
              maxLines: 3,
              errorText: _error,
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: HmSpace.xl),
            HmButton(label: text.declineConfirm, style: HmButtonStyle.danger, onPressed: _confirm),
          ],
        ),
      ),
    );
  }
}
