import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../design/tokens.dart';
import '../../../design/widgets/hm_async.dart';
import '../../../design/widgets/hm_scaffold.dart';
import '../../../routing/app_router.dart';
import '../../shared/journey_models.dart';
import '../../shared/journey_providers.dart';
import '../../shared/property_image.dart';

/// CUS-012a. Every lease the customer is currently living under.
///
/// Reached from the Active Rents section of the Favourites tab, which is where
/// the design puts the door to all rental management.
class RentalsScreen extends ConsumerWidget {
  const RentalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rentals = ref.watch(rentalsProvider);

    return HmScaffold(
      title: 'My Rentals',
      padded: false,
      backgroundColor: HmColors.bgSecondary,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(rentalsProvider),
        child: HmAsync(
          value: rentals,
          onRetry: () => ref.invalidate(rentalsProvider),
          emptyWhen: (page) => page.isEmpty,
          empty: HmEmpty(
            title: 'No active rentals',
            message: 'Once you have paid for a home and the lease begins, it will '
                'be managed from here.',
            icon: Icons.vpn_key_outlined,
            action: OutlinedButton(
              onPressed: () => context.go(Routes.search),
              child: const Text('Find a home'),
            ),
          ),
          data: (page) => ListView.separated(
            padding: const EdgeInsets.all(HmSpace.xxl),
            itemCount: page.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: HmSpace.xl),
            itemBuilder: (_, index) => RentalCard(rental: page.items[index]),
          ),
        ),
      ),
    );
  }
}

/// A tenancy at a glance: the photo, where it is, what it costs, the term, and
/// how much of that term is left.
class RentalCard extends StatelessWidget {
  const RentalCard({super.key, required this.rental});

  final Rental rental;

  /// "Jan 2026 - Dec 2026" — the term, in the shorthand the design uses.
  String get _termLabel {
    final start = rental.leaseStartDate;
    final end = rental.leaseEndDate;
    if (start == null && end == null) return '';
    final format = DateFormat('MMM yyyy');
    if (end == null) return 'From ${format.format(start!)}';
    if (start == null) return 'Until ${format.format(end)}';
    return '${format.format(start)} - ${format.format(end)}';
  }

  @override
  Widget build(BuildContext context) {
    final endingSoon = rental.isEndingSoon;

    return Material(
      color: HmColors.bgPrimary,
      borderRadius: HmRadius.card,
      child: InkWell(
        onTap: () => context.push(Routes.rental(rental.id)),
        borderRadius: HmRadius.card,
        child: Container(
          padding: const EdgeInsets.all(HmSpace.xl),
          decoration: BoxDecoration(
            borderRadius: HmRadius.card,
            border: Border.all(color: HmColors.borderDefault),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              PropertyImage(
                mediaId: rental.coverMediaId,
                height: 72,
                width: 72,
                borderRadius: BorderRadius.circular(HmRadius.sm),
              ),
              const SizedBox(width: HmSpace.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      rental.propertyTitle ?? 'Your home',
                      style: HmText.label.copyWith(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (rental.propertyAddress != null) ...[
                      const SizedBox(height: HmSpace.sm),
                      Row(
                        children: [
                          const Icon(Icons.place_outlined, size: 13, color: HmColors.textSecondary),
                          const SizedBox(width: HmSpace.xs),
                          Expanded(
                            child: Text(
                              rental.propertyAddress!,
                              style: HmText.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: HmSpace.sm),
                    Text(
                      rental.rentLabel,
                      style: HmText.label.copyWith(fontSize: 13, color: HmColors.brandPrimary),
                    ),
                    if (_termLabel.isNotEmpty) ...[
                      const SizedBox(height: HmSpace.xs),
                      Text(
                        _termLabel,
                        style: HmText.caption.copyWith(fontSize: 12, color: HmColors.textDisabled),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: HmSpace.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: HmSpace.lg,
                  vertical: HmSpace.xs,
                ),
                decoration: BoxDecoration(
                  color: (endingSoon ? HmColors.warning : HmColors.brandPrimary)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(HmRadius.pill),
                ),
                child: Text(
                  rental.remainingLabel,
                  // Read aloud as what it means, since "0 days" on its own is
                  // not obviously "the lease ends today".
                  semanticsLabel: '${rental.remainingLabel} of lease remaining',
                  style: HmText.caption.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: endingSoon ? HmColors.warning : HmColors.brandPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
