import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_text.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/hm_button.dart';
import '../../../design/widgets/hm_list_tile.dart';
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

/// The landlord's Home tab (LND-010), behind the same intro and
/// verification gate as the broker's.
class LandlordHomeScreen extends StatelessWidget {
  const LandlordHomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const PartnerHomeGate(role: AppRole.landlord, verified: _VerifiedHome());
}

/// LND-010: homes, homes let, rent paid this month; what needs the landlord
/// (confirmations, move-ins, enquiries, payments) and their homes.
class _VerifiedHome extends ConsumerWidget {
  const _VerifiedHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = context.text;
    final summary = ref.watch(partnerSummaryProvider).valueOrNull;
    final homes = ref.watch(partnerListingsProvider(null)).valueOrNull ?? const [];

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(partnerSummaryProvider);
        ref.invalidate(partnerListingsProvider(null));
      },
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const PartnerRoleHeader(role: AppRole.landlord),
          Padding(
            padding: const EdgeInsets.all(HmSpace.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Expanded(child: HmStatCard(label: text.landlordHomeHomes, value: '${summary?.count('homes').round() ?? 0}')),
                  const SizedBox(width: HmSpace.md),
                  Expanded(child: HmStatCard(label: text.landlordHomeLet, value: '${summary?.count('let').round() ?? 0}')),
                  const SizedBox(width: HmSpace.md),
                  Expanded(
                    child: HmStatCard(
                      label: text.landlordHomePaidThisMonth,
                      value: compactMoney(summary?.count('paidThisMonth') ?? 0),
                      sub: 'TZS',
                      onTap: () => context.go(Routes.landlordMoney),
                    ),
                  ),
                ]),
                const SizedBox(height: HmSpace.huge),
                NeedsYouSection(role: AppRole.landlord, items: summary?.needsYou ?? const []),
                const SizedBox(height: HmSpace.xxl),
                HmButton(
                  label: text.partnerHomeAddHome,
                  icon: Icons.add_home_outlined,
                  onPressed: () => context.push(Routes.partnerListingNew(AppRole.landlord)),
                ),
                const SizedBox(height: HmSpace.md),
                HmListTile(
                  icon: Icons.forum_outlined,
                  title: text.navEnquiries,
                  boxed: true,
                  onTap: () => context.push(Routes.landlordEnquiries),
                ),
                const SizedBox(height: HmSpace.huge),
                HmSectionHeader(
                  title: text.landlordHomeYourHomes,
                  action: text.seeAll,
                  onAction: () => context.go(Routes.landlordHomes),
                ),
                for (final home in homes.take(3)) ...[
                  PartnerListingTile(role: AppRole.landlord, listing: home),
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
