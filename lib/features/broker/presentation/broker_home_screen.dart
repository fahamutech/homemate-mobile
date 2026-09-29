import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_text.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/hm_button.dart';
import '../../../design/widgets/hm_section.dart';
import '../../../design/widgets/hm_stat_card.dart';
import '../../../routing/routes.dart';
import '../../partner_shared/data/partner_providers.dart';
import '../../partner_shared/presentation/home/needs_you_section.dart';
import '../../partner_shared/presentation/home/partner_home_gate.dart';
import '../../partner_shared/presentation/listings/partner_listing_tile.dart';
import '../../partner_shared/presentation/money_format.dart';
import '../../partner_shared/presentation/partner_role_header.dart';
import '../../roles/data/app_role.dart';

/// The broker's Home tab: the intro for someone who has not started, the
/// "before verification" home while the account is checked (BRK-010b), and
/// the working home once it is active (BRK-010).
class BrokerHomeScreen extends StatelessWidget {
  const BrokerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const PartnerHomeGate(role: AppRole.broker, verified: _VerifiedHome());
}

/// BRK-010: the counts, what needs the broker, and their listings.
class _VerifiedHome extends ConsumerWidget {
  const _VerifiedHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = context.text;
    final summary = ref.watch(partnerSummaryProvider).valueOrNull;
    final listings = ref.watch(partnerListingsProvider(null)).valueOrNull ?? const [];

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(partnerSummaryProvider);
        ref.invalidate(partnerListingsProvider(null));
      },
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const PartnerRoleHeader(role: AppRole.broker),
          Padding(
            padding: const EdgeInsets.all(HmSpace.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                IntrinsicHeight(
                  child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Expanded(child: HmStatCard(label: text.brokerHomeLive, value: '${summary?.count('liveListings').round() ?? 0}')),
                  const SizedBox(width: HmSpace.md),
                  Expanded(child: HmStatCard(label: text.brokerHomeOpen, value: '${summary?.count('openEnquiries').round() ?? 0}')),
                  const SizedBox(width: HmSpace.md),
                  Expanded(
                    child: HmStatCard(
                      label: text.partnerHomeEarnedThisMonth,
                      value: compactMoney(summary?.count('earnedThisMonth') ?? 0),
                      sub: 'TZS',
                    ),
                  ),
                  ]),
                ),
                const SizedBox(height: HmSpace.huge),
                NeedsYouSection(role: AppRole.broker, items: summary?.needsYou ?? const []),
                const SizedBox(height: HmSpace.xxl),
                HmButton(
                  label: text.partnerHomeAddHome,
                  icon: Icons.add_home_outlined,
                  onPressed: () => context.push(Routes.partnerListingNew(AppRole.broker)),
                ),
                const SizedBox(height: HmSpace.huge),
                HmSectionHeader(
                  title: text.partnerHomeYourListings,
                  action: text.seeAll,
                  onAction: () => context.go(Routes.brokerListings),
                ),
                for (final listing in listings.take(3)) ...[
                  PartnerListingTile(role: AppRole.broker, listing: listing),
                  const SizedBox(height: HmSpace.xl),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
