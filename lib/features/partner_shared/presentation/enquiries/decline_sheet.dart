import 'package:flutter/material.dart';

import '../../../../core/i18n/app_text.dart';
import '../reason_sheet.dart';

/// BRK-041b: why the partner is declining. Returns the reason, or null when
/// the sheet is dismissed.
Future<String?> showDeclineSheet(BuildContext context, {required String customerName}) {
  final text = context.text;
  return showReasonSheet(
    context,
    fieldKey: const ValueKey('decline-reason'),
    copy: ReasonSheetCopy(
      title: text.declineTitle,
      body: text.declineBody(customerName),
      label: text.declineReason,
      required: text.declineRequired,
      confirm: text.declineConfirm,
      quickReasons: quickDeclineReasons(text),
    ),
  );
}

/// The quick reasons, in the order the sheet offers them.
List<String> quickDeclineReasons(AppText text) => [
      text.declineQuickUnavailable,
      text.declineQuickDate,
      text.declineQuickBudget,
      text.declineQuickPeople,
    ];
