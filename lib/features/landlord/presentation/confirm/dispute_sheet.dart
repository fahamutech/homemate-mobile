import 'package:flutter/material.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../partner_shared/presentation/reason_sheet.dart';

/// LND-003 "Something is wrong": what, in the landlord's words. Returns the
/// reason, or null when the sheet is dismissed.
Future<String?> showDisputeSheet(BuildContext context) {
  final text = context.text;
  return showReasonSheet(
    context,
    fieldKey: const ValueKey('dispute-reason'),
    copy: ReasonSheetCopy(
      title: text.disputeTitle,
      body: text.disputeBody,
      label: text.disputeReason,
      required: text.disputeRequired,
      confirm: text.disputeConfirm,
      quickReasons: quickDisputeReasons(text),
    ),
  );
}

List<String> quickDisputeReasons(AppText text) => [
      text.disputeQuickNotMine,
      text.disputeQuickRent,
      text.disputeQuickNotAvailable,
      text.disputeQuickNoBroker,
    ];
