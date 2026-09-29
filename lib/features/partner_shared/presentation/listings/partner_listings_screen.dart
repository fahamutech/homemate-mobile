import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../design/tokens.dart';
import '../../../../design/widgets/hm_async.dart';
import '../../../../design/widgets/hm_choice.dart';
import '../../../../design/widgets/hm_top_bar.dart';
import '../../../../routing/routes.dart';
import '../../../roles/data/app_role.dart';
import '../../data/partner_listing.dart';
import '../../data/partner_providers.dart';
import 'listing_status.dart';
import 'partner_listing_tile.dart';

/// BRK-020 "My listings" (the landlord's "Homes" in T10): every listing with
/// its status, filtered by status, and + to add one.
class PartnerListingsScreen extends ConsumerStatefulWidget {
  const PartnerListingsScreen({super.key, required this.role, this.title});

  final AppRole role;

  /// "My listings" unless the role names the tab differently.
  final String? title;

  @override
  ConsumerState<PartnerListingsScreen> createState() => _PartnerListingsScreenState();
}

class _PartnerListingsScreenState extends ConsumerState<PartnerListingsScreen> {
  String? _status;

  static const _filters = ['approved', 'pending_review', 'changes_requested', 'draft', 'rented', 'archived'];

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final listings = ref.watch(partnerListingsProvider(null));

    return Scaffold(
      appBar: HmTopBar(
        title: widget.title ?? text.listingsTitle,
        actions: [
          IconButton(
            tooltip: text.listingsAdd,
            onPressed: () => context.push(Routes.partnerListingNew(widget.role)),
            icon: const Icon(Icons.add_rounded, color: HmColors.textPrimary),
          ),
        ],
      ),
      body: HmAsync<List<PartnerListingSummary>>(
        value: listings,
        onRetry: () => ref.invalidate(partnerListingsProvider(null)),
        data: (all) {
          int count(String? status) => status == null ? all.length : all.where((l) => l.status == status).length;
          final shown = _status == null ? all : [for (final l in all) if (l.status == _status) l];
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(partnerListingsProvider(null)),
            child: ListView(
              padding: const EdgeInsets.all(HmSpace.xxl),
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final status in [null, ..._filters.where((s) => count(s) > 0)]) ...[
                        HmChoicePill(
                          key: ValueKey('filter-${status ?? 'all'}'),
                          label: status == null ? text.listingsAll : listingStatusLabel(text, status),
                          count: count(status),
                          dense: true,
                          selected: _status == status,
                          onTap: () => setState(() => _status = status),
                        ),
                        const SizedBox(width: HmSpace.md),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: HmSpace.xxl),
                if (shown.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: HmSpace.section),
                    child: Text(
                      all.isEmpty ? text.listingsEmptyAll : text.listingsEmpty,
                      textAlign: TextAlign.center,
                      style: HmText.body,
                    ),
                  ),
                for (final listing in shown) ...[
                  PartnerListingTile(role: widget.role, listing: listing),
                  const SizedBox(height: HmSpace.xl),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
