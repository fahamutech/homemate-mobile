import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../design/tokens.dart';
import '../../../../design/widgets/hm_button.dart';
import '../../../../design/widgets/hm_feedback.dart';
import '../../../../design/widgets/hm_text_field.dart';

/// The words of a sheet that asks for a day: confirming a move-in (LND-032),
/// ending a tenancy.
class DaySheetCopy {
  const DaySheetCopy({
    required this.title,
    required this.body,
    required this.dayLabel,
    required this.pick,
    required this.required,
    required this.confirm,
    this.reasonLabel,
    this.reasonHint,
    this.danger = false,
  });

  final String title;
  final String body;
  final String dayLabel;
  final String pick;

  /// Shown when no day was picked.
  final String required;
  final String confirm;

  /// A reason field is offered only when this is set; it is optional.
  final String? reasonLabel;
  final String? reasonHint;
  final bool danger;
}

/// Asks for a day in [first]..[last] (and, optionally, a reason). Returns
/// them, or null when the sheet is dismissed.
Future<(DateTime, String?)?> showDaySheet(
  BuildContext context, {
  required DaySheetCopy copy,
  required DateTime first,
  required DateTime last,
}) =>
    showModalBottomSheet<(DateTime, String?)>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _DaySheet(copy: copy, first: first, last: last),
    );

class _DaySheet extends StatefulWidget {
  const _DaySheet({required this.copy, required this.first, required this.last});

  final DaySheetCopy copy;
  final DateTime first;
  final DateTime last;

  @override
  State<_DaySheet> createState() => _DaySheetState();
}

class _DaySheetState extends State<_DaySheet> {
  final _reason = TextEditingController();
  DateTime? _day;
  bool _missing = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _day ?? widget.last,
      firstDate: widget.first,
      lastDate: widget.last,
    );
    if (picked != null && mounted) {
      setState(() {
        _day = picked;
        _missing = false;
      });
    }
  }

  void _confirm() {
    final day = _day;
    if (day == null) {
      setState(() => _missing = true);
      return;
    }
    final reason = _reason.text.trim();
    Navigator.of(context).pop((day, reason.isEmpty ? null : reason));
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
            const SizedBox(height: HmSpace.xl),
            Text(copy.dayLabel, style: HmText.label),
            const SizedBox(height: HmSpace.sm),
            HmButton(
              key: const ValueKey('day-pick'),
              label: _day == null ? copy.pick : DateFormat('EEE d MMM yyyy').format(_day!),
              icon: Icons.calendar_today_outlined,
              style: HmButtonStyle.outline,
              size: HmButtonSize.medium,
              onPressed: _pick,
            ),
            if (_missing) ...[const SizedBox(height: HmSpace.md), HmInlineError(copy.required)],
            if (copy.reasonLabel != null) ...[
              const SizedBox(height: HmSpace.xl),
              HmTextField(
                fieldKey: const ValueKey('end-reason'),
                label: copy.reasonLabel!,
                placeholder: copy.reasonHint,
                controller: _reason,
                maxLines: 3,
              ),
            ],
            const SizedBox(height: HmSpace.xl),
            HmButton(label: copy.confirm, style: copy.danger ? HmButtonStyle.danger : HmButtonStyle.primary, onPressed: _confirm),
          ],
        ),
      ),
    );
  }
}
