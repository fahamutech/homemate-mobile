import '../../../../core/i18n/app_text.dart';
import '../../../../design/widgets/hm_badge.dart';
import '../../../../design/widgets/hm_money.dart';

/// Words and colours for where an earning or a payout stands (BRK-050–052).

String earningStateLabel(AppText text, String state) => switch (state) {
      'being_checked' => text.earningStateBeingChecked,
      'ready' => text.earningStateReady,
      'in_payout' => text.earningStateInPayout,
      'paid' => text.earningStatePaid,
      'on_hold' => text.earningStateOnHold,
      'reversed' => text.earningStateReversed,
      _ => text.earningStateFailed,
    };

HmBadgeTone earningStateTone(String state) => switch (state) {
      'ready' => HmBadgeTone.success,
      'being_checked' || 'in_payout' => HmBadgeTone.info,
      'paid' => HmBadgeTone.neutral,
      'on_hold' => HmBadgeTone.warning,
      _ => HmBadgeTone.error,
    };

String payoutStatusLabel(AppText text, String status) => switch (status) {
      'scheduled' => text.payoutsStatusScheduled,
      'processing' => text.payoutsStatusProcessing,
      'paid' => text.payoutsStatusPaid,
      'on_hold' => text.payoutsStatusOnHold,
      'failed' => text.payoutsStatusFailed,
      _ => text.payoutsStatusCancelled,
    };

HmBadgeTone payoutStatusTone(String status) => switch (status) {
      'scheduled' || 'processing' => HmBadgeTone.info,
      'paid' => HmBadgeTone.success,
      'on_hold' => HmBadgeTone.warning,
      'failed' => HmBadgeTone.error,
      _ => HmBadgeTone.neutral,
    };

/// "+TZS 810,000" for money in, "−TZS 315,000" for a reversal.
String signedMoney(double amount, {String currency = 'TZS'}) =>
    '${amount < 0 ? '−' : '+'}${HmMoney.format(amount.abs(), currency: currency)}';
