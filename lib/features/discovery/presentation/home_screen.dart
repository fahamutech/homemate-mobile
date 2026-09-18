import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/hm_async.dart';
import '../../../design/widgets/hm_money.dart';
import '../../../routing/app_router.dart';
import '../../shared/models.dart';
import '../../shared/property_card.dart';
import '../data/search_providers.dart';

/// CUS-001. What is waiting for you, then what is available.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customer = ref.watch(currentCustomerProvider);
    final summary = ref.watch(activitySummaryProvider);
    final featured = ref.watch(featuredPropertiesProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(activitySummaryProvider);
            ref.invalidate(featuredPropertiesProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(HmSpace.xxl),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Karibu', style: HmText.caption),
                        Text(
                          customer?.fullName?.split(' ').first ?? 'there',
                          style: HmText.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _NotificationBell(
                    unread: summary.valueOrNull?.unreadNotifications ?? 0,
                  ),
                ],
              ),
              const SizedBox(height: HmSpace.huge),

              _SearchPrompt(onTap: () => context.go(Routes.search)),
              const SizedBox(height: HmSpace.huge),

              // Only shown when there is genuinely something to attend to —
              // a row of zeroes is noise on the screen people open most.
              summary.maybeWhen(
                data: (data) => _AttentionRow(summary: data),
                orElse: () => const SizedBox.shrink(),
              ),

              Row(
                children: [
                  Expanded(child: Text('Available now', style: HmText.heading)),
                  TextButton(
                    onPressed: () => context.go(Routes.search),
                    child: const Text('See all'),
                  ),
                ],
              ),
              const SizedBox(height: HmSpace.xl),

              HmAsync(
                value: featured,
                onRetry: () => ref.invalidate(featuredPropertiesProvider),
                emptyWhen: (page) => page.isEmpty,
                loading: const Padding(
                  padding: EdgeInsets.symmetric(vertical: HmSpace.section),
                  child: HmLoading(),
                ),
                empty: const HmEmpty(
                  title: 'No listings yet',
                  message: 'New homes are added every day — check back shortly.',
                  icon: Icons.home_work_outlined,
                ),
                data: (page) => Column(
                  children: [
                    for (final property in page.items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: HmSpace.xxl),
                        child: PropertyCard(
                          property: property,
                          onSavedChanged: (_) => ref.invalidate(featuredPropertiesProvider),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.unread});

  final int unread;

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: () => context.go('${Routes.home}/notifications'),
        tooltip: unread > 0 ? '$unread unread notifications' : 'Notifications',
        icon: unread > 0
            ? Badge(
                backgroundColor: HmColors.error,
                label: Text('$unread'),
                child: const Icon(Icons.notifications_outlined),
              )
            : const Icon(Icons.notifications_outlined),
      );
}

class _SearchPrompt extends StatelessWidget {
  const _SearchPrompt({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: HmRadius.card,
        child: Container(
          padding: const EdgeInsets.all(HmSpace.xxl),
          decoration: BoxDecoration(
            color: HmColors.surfaceInput,
            borderRadius: HmRadius.card,
          ),
          child: const Row(
            children: [
              Icon(Icons.search, color: HmColors.textSecondary),
              SizedBox(width: HmSpace.xl),
              Text('Search by area, price or type', style: HmText.body),
            ],
          ),
        ),
      );
}

/// The short list of things that need the customer, with the money first.
class _AttentionRow extends StatelessWidget {
  const _AttentionRow({required this.summary});

  final ActivitySummary summary;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      if (summary.amountOutstanding > 0)
        _AttentionTile(
          icon: Icons.account_balance_wallet_outlined,
          label: 'To pay',
          value: HmMoney.format(summary.amountOutstanding),
          accent: HmColors.warning,
          onTap: () => context.go(Routes.bookings),
        ),
      if (summary.paymentsAwaitingVerification > 0)
        _AttentionTile(
          icon: Icons.hourglass_top_outlined,
          label: 'Being checked',
          value: '${summary.paymentsAwaitingVerification}',
          accent: HmColors.info,
          onTap: () => context.go(Routes.bookings),
        ),
      if (summary.upcomingViewings > 0)
        _AttentionTile(
          icon: Icons.event_available_outlined,
          label: 'Viewings',
          value: '${summary.upcomingViewings}',
          accent: HmColors.brandPrimary,
          onTap: () => context.go(Routes.viewings),
        ),
      if (summary.openInquiries > 0)
        _AttentionTile(
          icon: Icons.question_answer_outlined,
          label: 'Enquiries',
          value: '${summary.openInquiries}',
          accent: HmColors.brandPrimary,
          onTap: () => context.go(Routes.inquiries),
        ),
    ];

    if (tiles.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: HmSpace.huge),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final tile in tiles)
              Padding(padding: const EdgeInsets.only(right: HmSpace.xl), child: tile),
          ],
        ),
      ),
    );
  }
}

class _AttentionTile extends StatelessWidget {
  const _AttentionTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: HmRadius.card,
        child: Container(
          width: 150,
          padding: const EdgeInsets.all(HmSpace.xxl),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.08),
            borderRadius: HmRadius.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: accent, size: 20),
              const SizedBox(height: HmSpace.md),
              Text(label, style: HmText.caption),
              const SizedBox(height: HmSpace.xxs),
              Text(
                value,
                style: HmText.heading,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
}
