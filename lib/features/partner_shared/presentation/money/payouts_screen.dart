import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../core/providers.dart';
import '../../../../design/tokens.dart';
import '../../../../design/widgets/hm_async.dart';
import '../../../../design/widgets/hm_badge.dart';
import '../../../../design/widgets/hm_button.dart';
import '../../../../design/widgets/hm_money.dart';
import '../../../../design/widgets/hm_note.dart';
import '../../../../design/widgets/hm_section.dart';
import '../../../../design/widgets/hm_top_bar.dart';
import '../../../../routing/routes.dart';
import '../../../roles/data/app_role.dart';
import '../../data/partner_money.dart';
import '../../data/partner_providers.dart';
import '../payout_labels.dart';
import '../setup/setup_step.dart';
import 'earning_state.dart';

/// BRK-052: where payouts go, each payout finance has made, and — when one
/// is held — why, with the way to fix it.
class PayoutsScreen extends ConsumerWidget {
  const PayoutsScreen({super.key, required this.role});

  final AppRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = context.text;
    final reference = ref.watch(referenceDataProvider).valueOrNull;
    String bankName(String code) => reference?.banks.where((b) => b.code == code).map((b) => b.name).firstOrNull ?? code;

    return Scaffold(
      appBar: HmTopBar(title: text.payoutsTitle),
      body: HmAsync<PayoutsOverview>(
        value: ref.watch(payoutsProvider),
        onRetry: () => ref.invalidate(payoutsProvider),
        data: (overview) => ListView(
          padding: const EdgeInsets.all(HmSpace.xxl),
          children: [
            HmCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (overview.hasAccount) ...[
                    Text(
                      maskedAccountLine(
                        method: overview.accountMethod,
                        provider: overview.accountProvider,
                        masked: overview.accountNumber,
                        bankName: bankName,
                      ),
                      style: HmText.label.copyWith(fontSize: 16),
                    ),
                    if ((overview.accountName ?? '').isNotEmpty) Text(overview.accountName!, style: HmText.caption),
                    Text(text.payoutsWhere, style: HmText.caption),
                  ] else
                    Text(text.payoutsNoAccount, style: HmText.label),
                  const SizedBox(height: HmSpace.xl),
                  HmButton(
                    label: text.payoutsUpdate,
                    style: HmButtonStyle.outline,
                    size: HmButtonSize.medium,
                    onPressed: () => context.push(Routes.partnerSetup(role, step: SetupStep.payout.name)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: HmSpace.xxl),
            if (overview.items.isEmpty)
              Text(text.payoutsEmpty, textAlign: TextAlign.center, style: HmText.body)
            else
              for (final payout in overview.items) ...[
                _PayoutCard(payout: payout),
                const SizedBox(height: HmSpace.xl),
              ],
            const SizedBox(height: HmSpace.xl),
            HmNote(text: text.payoutsNote),
          ],
        ),
      ),
    );
  }
}

class _PayoutCard extends StatelessWidget {
  const _PayoutCard({required this.payout});

  final Payout payout;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final when = payout.paidAt ?? payout.scheduledFor ?? payout.createdAt;
    return HmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(HmMoney.format(payout.amount, currency: payout.currency), style: HmText.label.copyWith(fontSize: 16)),
                Text(
                  [payout.reference ?? '', if (when != null) DateFormat('d MMM yyyy').format(when.toLocal())]
                      .where((part) => part.isNotEmpty)
                      .join(' · '),
                  style: HmText.caption,
                ),
              ]),
            ),
            HmBadge(label: payoutStatusLabel(text, payout.status), tone: payoutStatusTone(payout.status)),
          ]),
          if (payout.status == 'on_hold' && (payout.holdReason ?? '').isNotEmpty) ...[
            const SizedBox(height: HmSpace.md),
            HmNote(text: text.payoutsOnHold(payout.holdReason!), tone: HmNoteTone.warning),
          ],
          if (payout.status == 'failed' && (payout.failureReason ?? '').isNotEmpty) ...[
            const SizedBox(height: HmSpace.md),
            HmNote(text: payout.failureReason!, tone: HmNoteTone.warning),
          ],
          if (payout.status == 'paid' && (payout.providerReference ?? '').isNotEmpty) ...[
            const SizedBox(height: HmSpace.sm),
            Text(text.payoutsReceipt(payout.providerReference!), style: HmText.caption),
          ],
        ],
      ),
    );
  }
}
