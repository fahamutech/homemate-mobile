import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/hm_async.dart';
import '../../../design/widgets/hm_feedback.dart';
import '../../../design/widgets/hm_money.dart';
import '../../../design/widgets/hm_prompt.dart';
import '../../../design/widgets/hm_scaffold.dart';
import '../../../design/widgets/hm_status_chip.dart';
import '../../../routing/app_router.dart';
import '../../shared/models.dart';
import '../../shared/property_image.dart';
import '../data/booking_providers.dart';

/// CUS-011 / CUS-012b. One booking: the terms agreed, what is owed, and every
/// payment against it.
class BookingDetailScreen extends ConsumerWidget {
  const BookingDetailScreen({super.key, required this.bookingId});

  final String bookingId;

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final reason = await HmPrompt.show(
      context,
      title: 'Cancel this booking?',
      message: 'The property goes back on the market. Anything already paid is '
          'handled by our team — contact support if you need a refund.',
      cancelLabel: 'Keep it',
      confirmLabel: 'Cancel booking',
      destructive: true,
    );
    if (reason == null || reason.isEmpty) return;

    try {
      await ref.read(activityRepositoryProvider).cancelBooking(bookingId, reason);
      ref.invalidate(bookingProvider(bookingId));
      ref.invalidate(bookingsProvider(null));
      ref.invalidate(activitySummaryProvider);
      if (context.mounted) HmFeedback.success(context, 'Booking cancelled');
    } catch (error) {
      if (context.mounted) HmFeedback.failure(context, error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booking = ref.watch(bookingProvider(bookingId));

    return HmScaffold(
      title: 'Booking',
      body: HmAsync(
        value: booking,
        onRetry: () => ref.invalidate(bookingProvider(bookingId)),
        data: (data) => ListView(
          children: [
            Row(
              children: [
                Expanded(child: HmStatusChip(data.status)),
                Text(data.reference, style: HmText.caption),
              ],
            ),
            const SizedBox(height: HmSpace.huge),

            if (data.propertyId != null)
              Card(
                child: InkWell(
                  borderRadius: HmRadius.card,
                  onTap: () => context.push(Routes.property(data.propertyId!)),
                  child: Padding(
                    padding: const EdgeInsets.all(HmSpace.xxl),
                    child: Row(
                      children: [
                        PropertyImage(mediaId: data.coverMediaId, height: 56, width: 56),
                        const SizedBox(width: HmSpace.xxl),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data.propertyTitle ?? 'Property', style: HmText.label),
                              if (data.propertyAddress != null)
                                Text(data.propertyAddress!, style: HmText.caption),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: HmColors.textDisabled),
                      ],
                    ),
                  ),
                ),
              ),

            if (data.propertyId != null) ...[
              const SizedBox(height: HmSpace.xl),
              // CUS-013b, reached from My Activity. The booking is only one
              // step of a longer story — the enquiry, the viewing, the
              // payments and the lease are the rest of it, and "where am I
              // with that house" is what someone opening this screen is
              // really asking.
              OutlinedButton.icon(
                onPressed: () => context.push(Routes.propertyActivity(data.propertyId!)),
                icon: const Icon(Icons.timeline_outlined, size: 18),
                label: const Text('View the full journey'),
              ),
            ],

            const SizedBox(height: HmSpace.huge),
            _MoneySummary(booking: data),

            const SizedBox(height: HmSpace.huge),
            const Text('What was agreed', style: HmText.heading),
            const SizedBox(height: HmSpace.md),
            _Row(label: 'Monthly rent', value: HmMoney.format(data.monthlyRent, currency: data.currency)),
            if (data.depositAmount > 0)
              _Row(label: 'Deposit', value: HmMoney.format(data.depositAmount, currency: data.currency)),
            if (data.leaseMonths != null)
              _Row(label: 'Lease length', value: '${data.leaseMonths} months'),
            if (data.moveInDate != null)
              _Row(
                label: 'Move in',
                value: '${data.moveInDate!.day}/${data.moveInDate!.month}/${data.moveInDate!.year}',
              ),
            if (data.landlordName != null)
              _Row(
                label: 'Landlord',
                // The number only appears once the booking is confirmed — up
                // to then the platform is still the one in the middle.
                value: data.status == 'confirmed' || data.status == 'active'
                    ? '${data.landlordName}${data.landlordPhone == null ? '' : ' · ${data.landlordPhone}'}'
                    : data.landlordName!,
              ),

            if (data.cancellationReason != null) ...[
              const SizedBox(height: HmSpace.huge),
              Container(
                padding: const EdgeInsets.all(HmSpace.xxl),
                decoration: BoxDecoration(
                  color: HmColors.error.withValues(alpha: 0.08),
                  borderRadius: HmRadius.card,
                ),
                child: Text('Cancelled: ${data.cancellationReason}', style: HmText.body),
              ),
            ],

            if (data.payments.isNotEmpty) ...[
              const SizedBox(height: HmSpace.huge),
              const Text('Payments', style: HmText.heading),
              const SizedBox(height: HmSpace.xl),
              for (final payment in data.payments)
                Padding(
                  padding: const EdgeInsets.only(bottom: HmSpace.xl),
                  child: _PaymentTile(payment: payment),
                ),
            ],

            const SizedBox(height: HmSpace.section),
            if (data.canCancel)
              OutlinedButton(
                onPressed: () => _cancel(context, ref),
                style: OutlinedButton.styleFrom(foregroundColor: HmColors.error),
                child: const Text('Cancel booking'),
              ),
            const SizedBox(height: HmSpace.xxl),
          ],
        ),
      ),
    );
  }
}

/// The headline number: what is left to pay, or that nothing is.
class _MoneySummary extends StatelessWidget {
  const _MoneySummary({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final settled = booking.isSettled;
    final checking = booking.amountAwaitingVerification > 0;
    final accent = settled
        ? HmColors.success
        : checking
            ? HmColors.info
            : HmColors.warning;

    return Container(
      padding: const EdgeInsets.all(HmSpace.huge),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: HmRadius.card,
      ),
      child: Column(
        children: [
          Text(
            settled
                ? 'Fully paid'
                : checking
                    ? 'We are checking your payment'
                    : 'Left to pay',
            style: HmText.caption,
          ),
          const SizedBox(height: HmSpace.xs),
          Text(
            HmMoney.format(
              settled ? booking.totalDue : booking.amountOutstanding,
              currency: booking.currency,
            ),
            style: HmText.display.copyWith(color: accent),
          ),
          if (!settled) ...[
            const SizedBox(height: HmSpace.md),
            Text(
              'of ${HmMoney.format(booking.totalDue, currency: booking.currency)} total',
              style: HmText.caption,
            ),
            const SizedBox(height: HmSpace.xl),
            ClipRRect(
              borderRadius: BorderRadius.circular(HmRadius.pill),
              child: LinearProgressIndicator(
                value: booking.totalDue == 0 ? 0 : booking.amountPaid / booking.totalDue,
                minHeight: 6,
                backgroundColor: HmColors.borderDefault,
                valueColor: AlwaysStoppedAnimation(accent),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment});

  final CustomerPayment payment;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: HmRadius.card,
          onTap: () => context.push(Routes.payment(payment.id)),
          child: Padding(
            padding: const EdgeInsets.all(HmSpace.xxl),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(HmStatusChip.humanise(payment.purpose), style: HmText.label),
                      const SizedBox(height: HmSpace.xs),
                      Text(payment.reference, style: HmText.caption),
                      const SizedBox(height: HmSpace.md),
                      HmStatusChip(payment.customerState, dense: true),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(payment.amountLabel, style: HmText.label),
                    const SizedBox(height: HmSpace.xs),
                    if (payment.canDeclare)
                      const Text('Tap to pay', style: TextStyle(fontSize: 12, color: HmColors.brandPrimary)),
                  ],
                ),
                const Icon(Icons.chevron_right, color: HmColors.textDisabled),
              ],
            ),
          ),
        ),
      );
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: HmSpace.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(label, style: HmText.caption)),
            const SizedBox(width: HmSpace.xxl),
            Expanded(child: Text(value, style: HmText.label, textAlign: TextAlign.right)),
          ],
        ),
      );
}
