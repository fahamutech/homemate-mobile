import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../design/tokens.dart';
import '../../../design/widgets/hm_async.dart';
import '../../../design/widgets/hm_feedback.dart';
import '../../../design/widgets/hm_money.dart';
import '../../../design/widgets/hm_scaffold.dart';
import '../../../design/widgets/hm_section.dart';
import '../../../design/widgets/hm_status_chip.dart';
import '../../../routing/app_router.dart';
import '../../shared/journey_models.dart';
import '../../shared/journey_providers.dart';
import '../../shared/models.dart';
import '../../shared/property_image.dart';
import '../../../core/i18n/app_text.dart';
import '../../../design/status_label.dart';
import '../../shared/reference_name.dart';

/// CUS-012b. One tenancy, managed.
///
/// Everything a tenant has to do about the place they live in is reachable
/// from here: what they pay and when it is next due, the lease itself, what
/// they have already paid, what the place comes with, and the two things that
/// end a tenancy — renewing it or giving notice.
class RentalDetailScreen extends ConsumerWidget {
  const RentalDetailScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rental = ref.watch(rentalProvider(bookingId));

    return HmScaffold(
      title: context.text.rentalTitle,
      padded: false,
      backgroundColor: HmColors.bgSecondary,
      body: HmAsync(
        value: rental,
        onRetry: () => ref.invalidate(rentalProvider(bookingId)),
        data: (detail) => _Loaded(detail: detail),
      ),
    );
  }
}

class _Loaded extends ConsumerWidget {
  const _Loaded({required this.detail});

  final RentalDetail detail;

  static DateFormat get _dayFormat => DateFormat('d MMM yyyy');
  static DateFormat get _monthFormat => DateFormat('MMMM yyyy');

  /// "1st of every month" — derived from when the lease began, because that is
  /// the day rent recurs on.
  String _dueDayLabel(AppText text, Rental rental) {
    final start = rental.leaseStartDate;
    if (start == null) return statusLabel(text, rental.paymentFrequency ?? 'monthly');
    final day = start.day;
    final suffix = switch (day) {
      1 || 21 || 31 => 'st',
      2 || 22 => 'nd',
      3 || 23 => 'rd',
      _ => 'th',
    };
    return text.rentalDueDay(day, suffix);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rental = detail.rental;

    return ListView(
      padding: const EdgeInsets.fromLTRB(HmSpace.xxl, HmSpace.xxl, HmSpace.xxl, HmSpace.section),
      children: [
        _QuickActions(rental: rental),
        const SizedBox(height: HmSpace.huge),

        PropertyImage(mediaId: rental.coverMediaId, height: 180),
        const SizedBox(height: HmSpace.xl),
        Text(rental.propertyTitle ?? context.text.rentalYourHome, style: HmText.title.copyWith(fontSize: 19)),
        if (rental.propertyAddress != null) ...[
          const SizedBox(height: HmSpace.sm),
          Row(
            children: [
              const Icon(Icons.place_outlined, size: 14, color: HmColors.textSecondary),
              const SizedBox(width: HmSpace.xs),
              Expanded(child: Text(rental.propertyAddress!, style: HmText.caption)),
            ],
          ),
        ],
        const SizedBox(height: HmSpace.huge),

        HmCard(
          title: context.text.rentalFinancial,
          child: Column(
            children: [
              HmDetailRow(
                label: context.text.rentalMonthlyRent,
                value: HmMoney.format(rental.monthlyRent, currency: rental.currency),
              ),
              HmDetailRow(
                label: context.text.rentalDeposit,
                value: HmMoney.format(rental.depositAmount, currency: rental.currency),
              ),
              HmDetailRow(label: context.text.rentalPaymentDue, value: _dueDayLabel(context.text, rental)),
              HmDetailRow(
                label: context.text.rentalNextPayment,
                value: rental.nextPaymentDate == null
                    ? '—'
                    : _dayFormat.format(rental.nextPaymentDate!),
                valueColor: HmColors.brandPrimary,
              ),
              if (rental.amountOutstanding > 0)
                HmDetailRow(
                  label: context.text.tenancyOutstanding,
                  value: HmMoney.format(rental.amountOutstanding, currency: rental.currency),
                  valueColor: HmColors.warning,
                ),
            ],
          ),
        ),
        const SizedBox(height: HmSpace.huge),

        HmSectionHeader(title: context.text.rentalLease),
        HmCard(
          child: Column(
            children: [
              HmDetailRow(
                label: context.text.rentalLeasePeriod,
                value: rental.leaseStartDate == null || rental.leaseEndDate == null
                    ? '—'
                    : '${DateFormat('MMM yyyy').format(rental.leaseStartDate!)} – '
                        '${DateFormat('MMM yyyy').format(rental.leaseEndDate!)}',
              ),
              HmDetailRow(
                label: context.text.rentalLeaseType,
                value: switch (rental.leaseType) {
                  'periodic' => context.text.leaseTypePeriodic,
                  'month_to_month' => context.text.rentalTypeMonthly,
                  _ => context.text.rentalTypeFixed,
                },
              ),
              HmDetailRow(label: context.text.roleLandlord, value: rental.landlordName ?? '—'),
              HmDetailRow(label: context.text.leaseContact, value: rental.landlordPhone ?? '—'),
              const SizedBox(height: HmSpace.xl),
              _ContractButton(rental: rental),
            ],
          ),
        ),
        const SizedBox(height: HmSpace.huge),

        HmSectionHeader(
          title: context.text.rentalHistory,
          action: detail.payments.isEmpty ? null : context.text.rentalViewAll,
          onAction: detail.payments.isEmpty ? null : () => context.go(Routes.activity),
        ),
        if (detail.payments.isEmpty)
          Text(context.text.rentalNoPayments, style: HmText.caption)
        else
          HmCard(
            padding: const EdgeInsets.symmetric(vertical: HmSpace.md, horizontal: HmSpace.xxl),
            child: Column(
              children: [
                for (final payment in detail.payments)
                  _PaymentRow(payment: payment, monthFormat: _monthFormat, dayFormat: _dayFormat),
              ],
            ),
          ),
        const SizedBox(height: HmSpace.huge),

        if (detail.amenities.isNotEmpty) ...[
          HmSectionHeader(title: context.text.rentalIncluded),
          _Amenities(amenities: detail.amenities),
          const SizedBox(height: HmSpace.huge),
        ],

        if (detail.timeline.isNotEmpty) ...[
          HmSectionHeader(
            title: context.text.rentalJourney,
            action: context.text.commonSeeAllTitle,
            onAction: () => context.push(Routes.propertyActivity(rental.propertyId ?? '')),
          ),
          HmCard(
            child: Column(
              children: [
                for (final event in detail.timeline.take(3))
                  Padding(
                    padding: const EdgeInsets.only(bottom: HmSpace.xl),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          event.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                          size: 16,
                          color: event.isDone ? HmColors.brandPrimary : HmColors.textDisabled,
                        ),
                        const SizedBox(width: HmSpace.xl),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(event.title, style: HmText.label.copyWith(fontSize: 13)),
                              if (event.at != null)
                                Text(_dayFormat.format(event.at!), style: HmText.caption),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: HmSpace.huge),
        ],

        if (rental.exitWindowOpensOn != null)
          HmNotice(
            message: context.text.rentalNoticeRequired(
              rental.noticePeriodDays ?? 90,
              _dayFormat.format(rental.exitWindowOpensOn!),
            ),
          ),
        const SizedBox(height: HmSpace.huge),

        FilledButton.icon(
          onPressed: () => _requestRenewal(context, rental),
          icon: const Icon(Icons.autorenew, size: 18),
          label: Text(context.text.rentalRequestRenewal),
        ),
      ],
    );
  }

  /// Renewal is a conversation with the landlord, not a button that changes a
  /// lease. Saying so is better than a control that appears to do more than it
  /// does — and the landlord's number is right here, so the honest version is
  /// also the useful one.
  void _requestRenewal(BuildContext context, Rental rental) {
    showModalBottomSheet<void>(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: HmRadius.sheet),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(HmSpace.huge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.text.rentalRenewalTitle, style: HmText.heading),
              const SizedBox(height: HmSpace.xl),
              Text(
                rental.leaseEndDate == null
                    ? context.text.rentalRenewalAsk
                    : context.text.rentalRenewalBody(_dayFormat.format(rental.leaseEndDate!)),
                style: HmText.body,
              ),
              const SizedBox(height: HmSpace.huge),
              if (rental.landlordPhone != null)
                HmCard(
                  child: Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 18, color: HmColors.brandPrimary),
                      const SizedBox(width: HmSpace.xl),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(rental.landlordName ?? context.text.roleLandlord, style: HmText.label),
                            Text(rental.landlordPhone!, style: HmText.caption),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: HmSpace.huge),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: Text(context.text.rentalGotIt),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Schedule, Report Issue, Request Exit — the three things the design puts
/// above everything else on this screen.
class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.rental});

  final Rental rental;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: _Action(
              icon: Icons.calendar_month_outlined,
              label: context.text.rentalSchedule,
              onTap: () => _notYet(context, context.text.rentalScheduling),
            ),
          ),
          const SizedBox(width: HmSpace.md),
          Expanded(
            child: _Action(
              icon: Icons.help_outline,
              label: context.text.rentalReport,
              onTap: () => _notYet(context, context.text.rentalReporting),
            ),
          ),
          const SizedBox(width: HmSpace.md),
          Expanded(
            child: _Action(
              icon: Icons.logout_outlined,
              label: context.text.rentalRequestExit,
              onTap: () => _exitNotice(context, rental),
            ),
          ),
        ],
      );

  /// Better than a control that silently does nothing: it says what it will be
  /// and how to do the same thing today.
  static void _notYet(BuildContext context, String what) =>
      HmFeedback.info(context, context.text.rentalComingSoon(what));

  static void _exitNotice(BuildContext context, Rental rental) {
    final opens = rental.exitWindowOpensOn;
    HmFeedback.info(
      context,
      opens == null
          ? context.text.rentalExitGive(rental.noticePeriodDays ?? 90)
          : context.text.rentalExitFrom(DateFormat('d MMM yyyy').format(opens), rental.noticePeriodDays ?? 90),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: HmColors.bgPrimary,
        borderRadius: HmRadius.card,
        child: InkWell(
          onTap: onTap,
          borderRadius: HmRadius.card,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: HmSpace.xl),
            decoration: BoxDecoration(
              borderRadius: HmRadius.card,
              border: Border.all(color: HmColors.borderDefault),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: HmColors.brandPrimary),
                const SizedBox(height: HmSpace.md),
                Text(
                  label,
                  style: HmText.caption.copyWith(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );
}

class _ContractButton extends StatelessWidget {
  const _ContractButton({required this.rental});

  final Rental rental;

  @override
  Widget build(BuildContext context) => Material(
        color: HmColors.surfaceInput,
        borderRadius: HmRadius.card,
        child: InkWell(
          onTap: () => context.push(Routes.lease(rental.id)),
          borderRadius: HmRadius.card,
          child: Padding(
            padding: const EdgeInsets.all(HmSpace.xl),
            child: Row(
              children: [
                const Icon(Icons.description_outlined, size: 20, color: HmColors.brandPrimary),
                const SizedBox(width: HmSpace.xl),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.text.rentalViewContract, style: HmText.label.copyWith(fontSize: 13)),
                      Text(
                        rental.hasAgreement
                            ? context.text.rentalAgreement(rental.agreementVersion ?? '').trim()
                            : context.text.rentalTerms,
                        style: HmText.caption,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: HmColors.textDisabled),
              ],
            ),
          ),
        ),
      );
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.payment,
    required this.monthFormat,
    required this.dayFormat,
  });

  final CustomerPayment payment;
  final DateFormat monthFormat;
  final DateFormat dayFormat;

  /// "September 2026" from the period the payment covers, falling back to when
  /// it was raised — a rent payment is always *for* a month.
  String get _period {
    final at = payment.confirmedAt ?? payment.declaredAt ?? payment.createdAt;
    return at == null ? payment.reference : monthFormat.format(at);
  }

  String _state(AppText text) {
    if (payment.isPaid) {
      final at = payment.confirmedAt;
      return at == null ? text.rentalStatePaid : text.rentalPaidOn(dayFormat.format(at));
    }
    if (payment.isAwaitingVerification) return text.rentalStateProcessing;
    if (payment.status == 'failed') return payment.failureReason ?? text.rentalStateFailed;
    return text.rentalStateDue;
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: HmSpace.xl),
        child: Row(
          children: [
            Icon(
              payment.isPaid ? Icons.credit_score_outlined : Icons.hourglass_empty,
              size: 18,
              color: payment.isPaid ? HmColors.brandPrimary : HmColors.warning,
            ),
            const SizedBox(width: HmSpace.xl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_period, style: HmText.label.copyWith(fontSize: 13)),
                  const SizedBox(height: HmSpace.xxs),
                  Text(_state(context.text), style: HmText.caption.copyWith(fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(payment.amountLabel, style: HmText.label.copyWith(fontSize: 13)),
                if (!payment.isPaid) ...[
                  const SizedBox(height: HmSpace.xs),
                  HmStatusChip(payment.customerState, dense: true),
                ],
              ],
            ),
          ],
        ),
      );
}

class _Amenities extends StatelessWidget {
  const _Amenities({required this.amenities});

  final List<NamedItem> amenities;

  /// The dictionary's codes mapped to something recognisable. Anything the map
  /// does not know still renders, with a neutral mark — a missing tile would
  /// silently drop a thing the tenant is paying for.
  static IconData _icon(String? code) => switch (code) {
        'wifi' || 'internet' => Icons.wifi,
        'parking' => Icons.local_parking_outlined,
        'security' || 'security_24h' => Icons.shield_outlined,
        'generator' || 'backup_power' => Icons.battery_charging_full_outlined,
        'water_tank' || 'water' => Icons.water_drop_outlined,
        'pool' || 'swimming_pool' => Icons.pool_outlined,
        'gym' => Icons.fitness_center_outlined,
        'air_conditioning' || 'ac' => Icons.ac_unit_outlined,
        'furnished' => Icons.chair_outlined,
        'garden' => Icons.local_florist_outlined,
        'lift' || 'elevator' => Icons.elevator_outlined,
        _ => Icons.check_circle_outline,
      };

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: HmSpace.md,
        runSpacing: HmSpace.xl,
        children: [
          for (final amenity in amenities)
            SizedBox(
              width: 80,
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: HmColors.brandPrimarySoft,
                      borderRadius: BorderRadius.circular(HmRadius.sm),
                    ),
                    child: Icon(_icon(amenity.code), size: 18, color: HmColors.brandPrimary),
                  ),
                  const SizedBox(height: HmSpace.md),
                  Text(
                    referenceName(context.text, code: amenity.code, name: amenity.name),
                    textAlign: TextAlign.center,
                    style: HmText.caption.copyWith(fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
        ],
      );
}
