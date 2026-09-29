import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../design/tokens.dart';
import '../../../../design/widgets/hm_badge.dart';
import '../../../../design/widgets/hm_button.dart';
import '../../../../design/widgets/hm_list_tile.dart';
import '../../../../design/widgets/hm_section.dart';
import '../../../../design/widgets/hm_top_bar.dart';
import '../../../../routing/routes.dart';
import '../../../roles/data/app_role.dart';
import '../../data/partner_providers.dart';
import 'listing_status.dart';

/// BRK-031: the listing went to HomeMate for review.
class ListingSentScreen extends ConsumerWidget {
  const ListingSentScreen({super.key, required this.role, required this.listingId});

  final AppRole role;
  final String listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = context.text;
    final listing = ref.watch(partnerListingProvider(listingId)).valueOrNull;
    return Scaffold(
      backgroundColor: HmColors.bgPrimary,
      appBar: HmTopBar(
        title: text.wizardTitle,
        onBack: () => context.go(Routes.partnerListings(role)),
        backTooltip: text.close,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(HmSpace.xxl),
          child: Column(
            children: [
              const SizedBox(height: HmSpace.huge),
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(color: HmColors.greenBg, shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_outline_rounded, size: 44, color: HmColors.success),
              ),
              const SizedBox(height: HmSpace.xxl),
              Text(text.wizardSentTitle, style: HmText.title),
              const SizedBox(height: HmSpace.md),
              Text(text.wizardSentBody, textAlign: TextAlign.center, style: HmText.body),
              const SizedBox(height: HmSpace.huge),
              if (listing != null)
                HmCard(
                  padding: EdgeInsets.zero,
                  child: HmListTile(
                    icon: Icons.home_outlined,
                    boxed: true,
                    title: listing.title,
                    subtitle: listing.referenceCode,
                    trailingIcon: null,
                    badge: HmBadge(label: listingStatusLabel(text, listing.status), tone: listingStatusTone(listing.status)),
                  ),
                ),
              const Spacer(),
              HmButton(
                label: text.wizardSentAnother,
                icon: Icons.add_home_outlined,
                onPressed: () => context.go(Routes.partnerListingNew(role)),
              ),
              const SizedBox(height: HmSpace.md),
              HmButton(
                label: text.wizardSentListings,
                style: HmButtonStyle.outline,
                onPressed: () => context.go(Routes.partnerListings(role)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
