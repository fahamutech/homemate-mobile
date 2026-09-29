import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../design/tokens.dart';
import '../../../../design/widgets/hm_async.dart';
import '../../../../design/widgets/hm_badge.dart';
import '../../../../design/widgets/hm_key_value.dart';
import '../../../../design/widgets/hm_money.dart';
import '../../../../design/widgets/hm_note.dart';
import '../../../../design/widgets/hm_section.dart';
import '../../../../design/widgets/hm_timeline_step.dart';
import '../../../../design/widgets/hm_top_bar.dart';
import '../../../roles/data/app_role.dart';
import '../../data/partner_money.dart';
import '../../data/partner_providers.dart';
import '../enquiries/enquiry_copy.dart' show percentLabel;
import 'earning_state.dart';

/// BRK-051 / LND-041: one earning — how it was worked out from the booking's
/// own fee snapshot, where the rest of the payment went, and its timeline.
class EarningDetailScreen extends ConsumerWidget {
  const EarningDetailScreen({super.key, required this.role, required this.earningId});

  final AppRole role;
  final String earningId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => HmAsync<EarningDetail>(
        value: ref.watch(earningProvider(earningId)),
        onRetry: () => ref.invalidate(earningProvider(earningId)),
        data: (detail) => Scaffold(
          appBar: HmTopBar(title: detail.earning.propertyTitle ?? context.text.earningYours),
          body: ListView(
            padding: const EdgeInsets.all(HmSpace.xxl),
            children: [
              _Hero(earning: detail.earning),
              if (detail.hasFee) ...[
                const SizedBox(height: HmSpace.xl),
                _HowItsWorkedOut(detail: detail),
              ],
              if (detail.split.any((line) => !line.you)) ...[
                const SizedBox(height: HmSpace.xl),
                _TheRest(split: detail.split),
              ],
              if (detail.timeline.isNotEmpty) ...[
                const SizedBox(height: HmSpace.xl),
                _Timeline(detail: detail),
              ],
            ],
          ),
        ),
      );
}

class _Hero extends StatelessWidget {
  const _Hero({required this.earning});

  final Earning earning;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    return HmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(text.earningYours, style: HmText.label.copyWith(color: HmColors.textSecondary))),
            HmBadge(label: earningStateLabel(text, earning.state), tone: earningStateTone(earning.state)),
          ]),
          const SizedBox(height: HmSpace.sm),
          Text(HmMoney.format(earning.amount, currency: earning.currency), style: HmText.heading.copyWith(fontSize: 28)),
          if ((earning.paymentReference ?? '').isNotEmpty) Text(earning.paymentReference!, style: HmText.caption),
          if (earning.state == 'on_hold' && (earning.holdReason ?? '').isNotEmpty) ...[
            const SizedBox(height: HmSpace.md),
            HmNote(text: text.earningHoldReason(earning.holdReason!), tone: HmNoteTone.warning),
          ],
        ],
      ),
    );
  }
}

class _HowItsWorkedOut extends StatelessWidget {
  const _HowItsWorkedOut({required this.detail});

  final EarningDetail detail;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    return HmCard(
      title: text.earningHow,
      child: Column(children: [
        if (detail.monthlyRent != null) HmKeyValue(label: text.earningMonthlyRent, value: HmMoney.format(detail.monthlyRent)),
        HmKeyValue(label: text.earningFee(percentLabel(detail.feePercentage ?? 0)), value: HmMoney.format(detail.feeAmount)),
        if (detail.platformAmount != null)
          HmKeyValue(
            label: text.earningShare(percentLabel(detail.platformPercentage ?? 0)),
            value: '− ${HmMoney.format(detail.platformAmount)}',
          ),
        const Divider(),
        HmKeyValue(label: text.earningReceive, value: HmMoney.format(detail.yourShare ?? detail.earning.amount), emphasis: HmKeyValueEmphasis.total),
      ]),
    );
  }
}

/// Where the rest of the payment went: never a secret, and never a cut of rent.
class _TheRest extends StatelessWidget {
  const _TheRest({required this.split});

  final List<SplitLine> split;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    String label(SplitLine line) => switch (line.beneficiary) {
          'landlord' => text.earningToLandlord,
          'broker' || 'agent' => text.earningToBroker,
          _ => text.earningToHomeMate,
        };
    return HmCard(
      title: text.earningRest,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final line in split.where((line) => !line.you)) HmKeyValue(label: label(line), value: HmMoney.format(line.amount)),
        const SizedBox(height: HmSpace.md),
        Text(text.earningRestNote, style: HmText.caption),
      ]),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.detail});

  final EarningDetail detail;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final points = detail.timeline;
    final firstOpen = points.indexWhere((p) => !p.done);
    String title(TimelinePoint point) => switch (point.key) {
          'paid' => text.earningTimelinePaid(detail.earning.tenantName ?? ''),
          'verified' => text.earningTimelineVerified,
          'payout_created' => text.earningTimelinePayoutCreated,
          _ => text.earningTimelinePaidOut,
        };
    return HmCard(
      title: text.earningTimeline,
      child: Column(children: [
        for (final (index, point) in points.indexed)
          HmTimelineStep(
            title: title(point).trim(),
            state: point.done ? HmStepState.done : (index == firstOpen ? HmStepState.current : HmStepState.upcoming),
            date: point.at == null ? null : DateFormat('d MMM yyyy').format(point.at!.toLocal()),
            isLast: index == points.length - 1,
          ),
      ]),
    );
  }
}
