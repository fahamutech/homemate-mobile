import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../design/tokens.dart';
import '../../../design/widgets/hm_async.dart';
import '../../../design/widgets/hm_money.dart';
import '../../../design/widgets/hm_status_chip.dart';
import '../../../routing/app_router.dart';
import '../../shared/models.dart';
import '../../shared/property_image.dart';
import '../data/booking_providers.dart';

/// CUS-012a / CUS-016. The Activity tab: bookings, and the way through to
/// enquiries and viewings.
class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(bookingsProvider(null));

    return Scaffold(
      appBar: AppBar(title: const Text('My activity')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(bookingsProvider(null)),
        child: ListView(
          padding: const EdgeInsets.all(HmSpace.xxl),
          children: [
            Row(
              children: [
                Expanded(
                  child: _Shortcut(
                    icon: Icons.question_answer_outlined,
                    label: 'Enquiries',
                    onTap: () => context.push(Routes.inquiries),
                  ),
                ),
                const SizedBox(width: HmSpace.xl),
                Expanded(
                  child: _Shortcut(
                    icon: Icons.event_available_outlined,
                    label: 'Viewings',
                    onTap: () => context.push(Routes.viewings),
                  ),
                ),
              ],
            ),
            const SizedBox(height: HmSpace.huge),
            const Text('Bookings & rentals', style: HmText.heading),
            const SizedBox(height: HmSpace.xl),

            HmAsync(
              value: bookings,
              onRetry: () => ref.invalidate(bookingsProvider(null)),
              emptyWhen: (page) => page.isEmpty,
              loading: const Padding(
                padding: EdgeInsets.symmetric(vertical: HmSpace.section),
                child: HmLoading(),
              ),
              empty: HmEmpty(
                title: 'No bookings yet',
                message: 'Once you book a home, it and its payments live here.',
                icon: Icons.receipt_long_outlined,
                action: OutlinedButton(
                  onPressed: () => context.go(Routes.search),
                  child: const Text('Find a home'),
                ),
              ),
              data: (page) => Column(
                children: [
                  for (final booking in page.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: HmSpace.xl),
                      child: BookingTile(booking: booking),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
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
          child: Row(
            children: [
              Icon(icon, size: 20, color: HmColors.brandPrimary),
              const SizedBox(width: HmSpace.xl),
              Expanded(child: Text(label, style: HmText.label)),
            ],
          ),
        ),
      );
}

class BookingTile extends StatelessWidget {
  const BookingTile({super.key, required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: HmRadius.card,
          onTap: () => context.push(Routes.booking(booking.id)),
          child: Padding(
            padding: const EdgeInsets.all(HmSpace.xxl),
            child: Column(
              children: [
                Row(
                  children: [
                    PropertyImage(mediaId: booking.coverMediaId, height: 56, width: 56),
                    const SizedBox(width: HmSpace.xxl),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.propertyTitle ?? 'Property',
                            style: HmText.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: HmSpace.xs),
                          Text(booking.reference, style: HmText.caption),
                          const SizedBox(height: HmSpace.md),
                          HmStatusChip(booking.status, dense: true),
                        ],
                      ),
                    ),
                  ],
                ),
                // Only when something is actually owed — a paid-up rental does
                // not need a row telling it so.
                if (booking.amountOutstanding > 0) ...[
                  const SizedBox(height: HmSpace.xxl),
                  const Divider(height: 1),
                  const SizedBox(height: HmSpace.xl),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          booking.amountAwaitingVerification > 0
                              ? 'Being checked'
                              : 'To pay',
                          style: HmText.caption,
                        ),
                      ),
                      Text(
                        HmMoney.format(booking.amountOutstanding, currency: booking.currency),
                        style: HmText.label.copyWith(
                          color: booking.amountAwaitingVerification > 0
                              ? HmColors.info
                              : HmColors.warning,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}
