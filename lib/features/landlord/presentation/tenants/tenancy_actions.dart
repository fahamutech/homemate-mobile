import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../core/providers.dart';
import '../../../../design/widgets/hm_feedback.dart';
import '../../../partner_shared/data/partner_providers.dart';
import '../../../partner_shared/presentation/enquiries/enquiry_copy.dart' show firstName;
import '../../data/landlord_providers.dart';
import '../../data/tenancy.dart';
import 'day_sheet.dart';
import 'tenancy_copy.dart';

/// LND-032: asks which day the tenant moved in and starts the tenancy.
/// Returns true when it started.
Future<bool> confirmMoveIn(BuildContext context, WidgetRef ref, Tenancy tenancy) async {
  final text = context.text;
  final window = moveInWindow(tenancy, DateTime.now());
  final answer = await showDaySheet(
    context,
    first: window.first,
    last: window.last,
    copy: DaySheetCopy(
      title: text.tenancyConfirmMoveIn,
      body: text.moveInBody(firstName(tenancy.tenantName)),
      dayLabel: text.moveInDay,
      pick: text.moveInPick,
      required: text.moveInRequired,
      confirm: text.moveInConfirm,
    ),
  );
  if (answer == null || !context.mounted) return false;
  return _run(context, ref, tenancy.id, text.tenancyStarted,
      () => ref.read(tenanciesRepositoryProvider).moveIn(tenancy.id, date: answer.$1));
}

/// Ends a tenancy someone lives in, on a day and with an optional reason.
Future<bool> endTenancy(BuildContext context, WidgetRef ref, Tenancy tenancy) async {
  final text = context.text;
  final window = endWindow(tenancy, DateTime.now());
  final answer = await showDaySheet(
    context,
    first: window.first,
    last: window.last,
    copy: DaySheetCopy(
      title: text.tenancyEnd,
      body: text.endTenancyBody(firstName(tenancy.tenantName)),
      dayLabel: text.endTenancyDay,
      pick: text.moveInPick,
      required: text.endTenancyRequired,
      confirm: text.tenancyEnd,
      reasonLabel: text.tenancyEndReason,
      reasonHint: text.endTenancyReasonHint,
      danger: true,
    ),
  );
  if (answer == null || !context.mounted) return false;
  return _run(context, ref, tenancy.id, text.tenancyEndedDone,
      () => ref.read(tenanciesRepositoryProvider).end(tenancy.id, date: answer.$1, reason: answer.$2));
}

Future<bool> _run(BuildContext context, WidgetRef ref, String id, String done, Future<Tenancy> Function() action) async {
  try {
    await action();
    ref.invalidate(tenancyProvider(id));
    ref.invalidate(tenanciesProvider);
    ref.invalidate(partnerSummaryProvider);
    if (context.mounted) HmFeedback.success(context, done);
    return true;
  } catch (error) {
    if (context.mounted) HmFeedback.failure(context, error);
    return false;
  }
}
