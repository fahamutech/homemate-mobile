import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/providers.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/hm_async.dart';
import '../../../design/widgets/hm_section.dart';
import '../../../design/widgets/hm_status_chip.dart';
import '../../../routing/app_router.dart';
import '../../shared/journey_models.dart';
import '../../shared/journey_providers.dart';
import '../../shared/property_card.dart';
import '../../shared/property_image.dart';
import '../../discovery/data/search_providers.dart';

/// CUS-013a. Favourites — and everything else the customer has going on.
///
/// The screen is named for the tab it sits behind, but it is deliberately not
/// just a list of saved listings. The design puts four things here in this
/// order, and the order is the argument:
///
///   1. **Active Rents** — a tenancy with rent falling due beats anything you
///      once tapped a heart on. This is also the only way into the lease and
///      its paperwork (CUS-012a/b/c).
///   2. **Saved Favorites** — what the tab is called, scrolling sideways so it
///      costs one screen rather than five.
///   3. **Recent Inquiries** — what you asked and what came back, including the
///      ones now waiting for money.
///   4. **Upcoming Bookings** — viewings you have arranged.
///
/// All four arrive in one call, because a returning customer opening this
/// screen should not be looking at four spinners.
class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(savedOverviewProvider);

    return Scaffold(
      backgroundColor: HmColors.bgSecondary,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Favourite', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            SizedBox(height: HmSpace.xxs),
            Text(
              'Your favourites & activity',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: HmColors.textBody),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(savedOverviewProvider);
          ref.invalidate(activitySummaryProvider);
        },
        child: HmAsync(
          value: overview,
          onRetry: () => ref.invalidate(savedOverviewProvider),
          emptyWhen: (data) => data.isEmpty,
          empty: HmEmpty(
            title: 'Nothing here yet',
            message: 'Tap the heart on a listing to keep it here, and anything you '
                'enquire about or book will show up too.',
            icon: Icons.favorite_outline,
            action: OutlinedButton(
              onPressed: () => context.go(Routes.search),
              child: const Text('Browse homes'),
            ),
          ),
          data: (data) => _Sections(overview: data),
        ),
      ),
    );
  }
}

class _Sections extends ConsumerWidget {
  const _Sections({required this.overview});

  final SavedOverview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(HmSpace.xxl, HmSpace.xxxl, HmSpace.xxl, HmSpace.section),
      children: [
        if (overview.activeRentals.isNotEmpty) ...[
          HmSectionHeader(
            title: 'Active Rents',
            action: overview.activeRentalCount > overview.activeRentals.length ? 'See All' : null,
            onAction: overview.activeRentalCount > overview.activeRentals.length
                ? () => context.push(Routes.rentals)
                : null,
            trailingText: overview.activeRentalCount <= overview.activeRentals.length
                ? _items(overview.activeRentalCount)
                : null,
          ),
          for (final rental in overview.activeRentals)
            Padding(
              padding: const EdgeInsets.only(bottom: HmSpace.xl),
              child: _ActiveRentRow(rental: rental),
            ),
          const SizedBox(height: HmSpace.xxl),
        ],

        HmSectionHeader(
          title: 'Saved Favorites',
          trailingText: _items(overview.favoriteCount),
        ),
        if (overview.favorites.isEmpty)
          const _EmptySection(
            icon: Icons.favorite_outline,
            message: 'Tap the heart on a listing to keep it here for later.',
          )
        else
          // Sideways, as the design has it: two cards visible at a time is
          // what keeps the sections below it above the fold.
          SizedBox(
            height: 116,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: overview.favorites.length,
              separatorBuilder: (_, __) => const SizedBox(width: HmSpace.xl),
              itemBuilder: (_, index) => SizedBox(
                width: 280,
                child: PropertyCard(
                  property: overview.favorites[index],
                  layout: PropertyCardLayout.horizontal,
                  onSavedChanged: (_) {
                    ref.invalidate(savedOverviewProvider);
                    ref.invalidate(savedPropertiesProvider);
                    ref.invalidate(activitySummaryProvider);
                  },
                ),
              ),
            ),
          ),
        const SizedBox(height: HmSpace.section),

        HmSectionHeader(
          title: 'Recent Inquiries',
          action: overview.recentInquiries.isEmpty ? null : 'See All',
          onAction: overview.recentInquiries.isEmpty
              ? null
              : () => context.go(Routes.inquiries),
        ),
        if (overview.recentInquiries.isEmpty)
          const _EmptySection(
            icon: Icons.question_answer_outlined,
            message: 'Ask a landlord about a home and the conversation appears here.',
          )
        else
          for (final inquiry in overview.recentInquiries)
            Padding(
              padding: const EdgeInsets.only(bottom: HmSpace.xl),
              child: _InquiryRow(inquiry: inquiry),
            ),
        const SizedBox(height: HmSpace.xxl),

        HmSectionHeader(
          title: 'Upcoming Bookings',
          action: overview.upcomingBookings.isEmpty ? null : 'See All',
          onAction: overview.upcomingBookings.isEmpty
              ? null
              : () => context.go(Routes.viewings),
        ),
        if (overview.upcomingBookings.isEmpty)
          const _EmptySection(
            icon: Icons.event_available_outlined,
            message: 'Arrange a viewing and it will be listed here.',
          )
        else
          for (final viewing in overview.upcomingBookings)
            Padding(
              padding: const EdgeInsets.only(bottom: HmSpace.xl),
              child: _ViewingRow(viewing: viewing),
            ),
      ],
    );
  }

  static String _items(int count) => count == 1 ? '1 Item' : '$count Items';
}

/// An active tenancy. Tapping it is how a customer reaches their lease, their
/// payment history and the rest of CUS-012 — which is the whole reason this
/// section sits at the top.
class _ActiveRentRow extends StatelessWidget {
  const _ActiveRentRow({required this.rental});

  final Rental rental;

  @override
  Widget build(BuildContext context) => HmListRow(
        onTap: () => context.push(Routes.rental(rental.id)),
        leading: PropertyImage(
          mediaId: rental.coverMediaId,
          height: 48,
          width: 48,
          borderRadius: BorderRadius.circular(HmRadius.sm),
        ),
        title: rental.propertyTitle ?? 'Your home',
        subtitle: rental.propertyAddress,
        highlight: rental.rentLabel,
        footnote: rental.nextPaymentDate == null
            ? null
            : 'Next payment: ${DateFormat('d MMM yyyy').format(rental.nextPaymentDate!)}',
        trailing: _Pill(
          label: rental.remainingLabel,
          // A lease inside its last two months is a decision the tenant has to
          // make, so it stops being reassuring green.
          colour: rental.isEndingSoon ? HmColors.warning : HmColors.brandPrimary,
        ),
      );
}

class _InquiryRow extends StatelessWidget {
  const _InquiryRow({required this.inquiry});

  final InquirySummary inquiry;

  @override
  Widget build(BuildContext context) => HmListRow(
        onTap: () => context.push(Routes.inquiry(inquiry.id)),
        leading: PropertyImage(
          mediaId: inquiry.coverMediaId,
          height: 48,
          width: 48,
          borderRadius: BorderRadius.circular(HmRadius.sm),
        ),
        title: inquiry.propertyTitle ?? 'Property',
        subtitle: 'Inquired on ${DateFormat('d MMM yyyy').format(inquiry.createdAt)}',
        // `display_status` is the server's, so an accepted enquiry reads as
        // "Awaiting payment" here without the app inventing that mapping.
        trailing: HmStatusChip(inquiry.displayStatus, dense: true),
      );
}

class _ViewingRow extends StatelessWidget {
  const _ViewingRow({required this.viewing});

  final ViewingSummary viewing;

  @override
  Widget build(BuildContext context) => HmListRow(
        onTap: () => context.push(Routes.viewing(viewing.id)),
        leading: PropertyImage(
          mediaId: viewing.coverMediaId,
          height: 48,
          width: 48,
          borderRadius: BorderRadius.circular(HmRadius.sm),
        ),
        title: viewing.propertyTitle ?? 'Property',
        subtitle: DateFormat('d MMM yyyy • h:mm a').format(viewing.scheduledFor),
        trailing: HmStatusChip(viewing.status, dense: true),
      );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.colour});

  final String label;
  final Color colour;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: HmSpace.lg, vertical: HmSpace.xs),
        decoration: BoxDecoration(
          color: colour.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(HmRadius.pill),
        ),
        child: Text(
          label,
          style: HmText.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: colour),
        ),
      );
}

/// A section with nothing in it yet still says what would put something there.
/// The alternative — hiding the heading — makes the screen's shape change
/// between visits, which is disorienting.
class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: HmSpace.huge, horizontal: HmSpace.xxl),
        decoration: BoxDecoration(
          color: HmColors.bgPrimary,
          borderRadius: HmRadius.card,
          border: Border.all(color: HmColors.borderDefault),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: HmColors.textDisabled),
            const SizedBox(width: HmSpace.xl),
            Expanded(child: Text(message, style: HmText.caption)),
          ],
        ),
      );
}
