import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../design/tokens.dart';
import '../../../../design/widgets/hm_async.dart';
import '../../../../design/widgets/hm_badge.dart';
import '../../../../design/widgets/hm_money.dart';
import '../../../../design/widgets/hm_money_row.dart';
import '../../../../design/widgets/hm_note.dart';
import '../../../../design/widgets/hm_section.dart';
import '../../../../design/widgets/hm_stat_card.dart';
import '../../../../design/widgets/hm_top_bar.dart';
import '../../../../routing/routes.dart';
import '../../../roles/data/app_role.dart';
import '../../data/partner_money.dart';
import '../../data/partner_providers.dart';
import '../partner_photo.dart';
import 'earning_state.dart';

/// BRK-050 / LND-040: what is ready for payout, what is being checked, what
/// was paid this year, and every earning with where it stands.
class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key, required this.role});

  final AppRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = context.text;
    return Scaffold(
      appBar: HmTopBar(title: role == AppRole.landlord ? text.navMoney : text.earningsTitle),
      body: HmAsync<EarningsOverview>(
        value: ref.watch(earningsProvider),
        onRetry: () => ref.invalidate(earningsProvider),
        data: (overview) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(earningsProvider),
          child: ListView(
            padding: const EdgeInsets.all(HmSpace.xxl),
            children: [
              _ReadyHero(amount: overview.total('ready')),
              const SizedBox(height: HmSpace.xl),
              Row(children: [
                Expanded(child: HmStatCard(label: text.earningsBeingChecked, value: HmMoney.format(overview.total('being_checked')))),
                const SizedBox(width: HmSpace.xl),
                Expanded(
                  child: HmStatCard(
                    label: text.earningsPaidThisYear(DateTime.now().year),
                    value: HmMoney.format(overview.paidThisYear),
                  ),
                ),
              ]),
              const SizedBox(height: HmSpace.xxl),
              HmSectionHeader(
                title: text.earningsRecent,
                action: text.earningsPayouts,
                onAction: () => context.push(Routes.partnerPayouts(role)),
              ),
              if (overview.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: HmSpace.xxl),
                  child: Text(role == AppRole.landlord ? text.earningsEmptyLandlord : text.earningsEmpty, textAlign: TextAlign.center, style: HmText.body),
                )
              else
                HmCard(
                  padding: EdgeInsets.zero,
                  child: Column(children: [
                    for (final (index, earning) in overview.items.indexed) ...[
                      if (index > 0) const Divider(height: 1),
                      HmMoneyRow(
                        title: earning.propertyTitle ?? earning.paymentReference ?? '',
                        detail: _detail(earning),
                        amount: signedMoney(earning.amount, currency: earning.currency),
                        leading: earning.coverPhotoUrl == null ? null : PartnerPhoto(url: earning.coverPhotoUrl, radius: 0),
                        status: HmBadge(label: earningStateLabel(text, earning.state), tone: earningStateTone(earning.state)),
                        onTap: () => context.push(Routes.partnerEarning(role, earning.id)),
                      ),
                    ],
                  ]),
                ),
              const SizedBox(height: HmSpace.xl),
              HmNote(text: role == AppRole.landlord ? text.earningsNoteLandlord : text.earningsNote),
            ],
          ),
        ),
      ),
    );
  }

  static String _detail(Earning earning) => [
        if ((earning.tenantName ?? '').isNotEmpty) earning.tenantName!,
        if (earning.paymentConfirmedAt != null) DateFormat('d MMM').format(earning.paymentConfirmedAt!.toLocal()),
      ].join(' · ');
}

class _ReadyHero extends StatelessWidget {
  const _ReadyHero({required this.amount});

  final double amount;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(HmSpace.xxl),
        decoration: BoxDecoration(color: HmColors.brandPrimary, borderRadius: BorderRadius.circular(HmRadius.lg)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.text.earningsReady, style: HmText.label.copyWith(color: Colors.white70)),
            const SizedBox(height: HmSpace.sm),
            Text(HmMoney.format(amount), style: HmText.heading.copyWith(color: Colors.white, fontSize: 28)),
          ],
        ),
      );
}
