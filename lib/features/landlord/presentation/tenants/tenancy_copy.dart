import 'package:intl/intl.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../design/widgets/hm_badge.dart';
import '../../data/tenancy.dart';

/// Words for a tenancy, shared by the list and the tenancy screen.

String tenancyStageLabel(AppText text, TenancyStage stage) => switch (stage) {
      TenancyStage.movingIn => text.tenantsTabMovingIn,
      TenancyStage.current => text.tenantsTabCurrent,
      TenancyStage.past => text.tenantsTabPast,
    };

HmBadgeTone tenancyStageTone(TenancyStage stage) => switch (stage) {
      TenancyStage.movingIn => HmBadgeTone.warning,
      TenancyStage.current => HmBadgeTone.success,
      TenancyStage.past => HmBadgeTone.neutral,
    };

String tenancyStageEmpty(AppText text, TenancyStage stage) => switch (stage) {
      TenancyStage.movingIn => text.tenantsEmptyMovingIn,
      TenancyStage.current => text.tenantsEmptyCurrent,
      TenancyStage.past => text.tenantsEmptyPast,
    };

/// The one date that matters at each stage: the move-in, the next rent, the end.
String? tenancyWhen(AppText text, Tenancy tenancy) {
  String day(DateTime date) => DateFormat('d MMM').format(date);
  return switch (tenancy.stage) {
    TenancyStage.movingIn => tenancy.leaseStartDate == null ? null : text.tenantsMovesIn(day(tenancy.leaseStartDate!)),
    TenancyStage.current => tenancy.nextPaymentDate == null ? null : text.tenantsNextRent(day(tenancy.nextPaymentDate!)),
    TenancyStage.past => tenancy.endedOn == null ? null : text.tenantsEnded(day(tenancy.endedOn!)),
  };
}

/// The days a move-in may be confirmed for: from a week before the lease
/// starts (the server's rule, 030) up to today.
({DateTime first, DateTime last}) moveInWindow(Tenancy tenancy, DateTime today) {
  final last = DateTime(today.year, today.month, today.day);
  final start = tenancy.leaseStartDate?.subtract(const Duration(days: 7)) ?? last.subtract(const Duration(days: 365));
  return (first: start.isAfter(last) ? last : start, last: last);
}

/// The days a tenancy may end on: from the move-in up to today.
({DateTime first, DateTime last}) endWindow(Tenancy tenancy, DateTime today) {
  final last = DateTime(today.year, today.month, today.day);
  final start = tenancy.moveInDate ?? tenancy.leaseStartDate ?? last.subtract(const Duration(days: 365 * 5));
  return (first: start.isAfter(last) ? last : start, last: last);
}
