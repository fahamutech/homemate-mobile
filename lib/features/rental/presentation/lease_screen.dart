import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../design/tokens.dart';
import '../../../design/widgets/hm_async.dart';
import '../../../design/widgets/hm_feedback.dart';
import '../../../design/widgets/hm_money.dart';
import '../../../design/widgets/hm_scaffold.dart';
import '../../../design/widgets/hm_section.dart';
import '../../shared/journey_models.dart';
import '../../shared/journey_providers.dart';

/// CUS-012c. The lease behind a tenancy.
///
/// The screen is deliberately honest about the two cases. When an agreement
/// has been drawn up it shows the parties, the term and the document. When one
/// has not, it still shows the terms that were agreed at booking — because
/// those are binding whether or not anybody has produced a PDF — and says
/// plainly that the document is not ready, rather than offering a download
/// that cannot work.
class LeaseScreen extends ConsumerWidget {
  const LeaseScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lease = ref.watch(leaseProvider(bookingId));

    return HmScaffold(
      title: 'Lease Contract',
      padded: false,
      backgroundColor: HmColors.bgSecondary,
      body: HmAsync(
        value: lease,
        onRetry: () => ref.invalidate(leaseProvider(bookingId)),
        data: (data) => _Loaded(lease: data),
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.lease});

  final LeaseAgreement lease;

  static final _dayFormat = DateFormat('d MMM yyyy');

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(HmSpace.xxl, HmSpace.xxl, HmSpace.xxl, HmSpace.section),
        children: [
          if (!lease.exists)
            const Padding(
              padding: EdgeInsets.only(bottom: HmSpace.huge),
              child: HmNotice(
                message: 'Your signed agreement is not ready yet. The terms below are '
                    'the ones recorded when you booked, and they apply from your lease '
                    'start date.',
                icon: Icons.schedule_outlined,
                colour: HmColors.info,
              ),
            ),

          HmCard(
            title: 'The Parties',
            child: Column(
              children: [
                HmDetailRow(label: 'Tenant', value: lease.tenantName ?? '—'),
                HmDetailRow(label: 'Landlord', value: lease.landlordName ?? '—'),
                HmDetailRow(label: 'Contact', value: lease.landlordPhone ?? '—'),
                HmDetailRow(label: 'Property', value: lease.propertyTitle ?? '—'),
                if (lease.propertyAddress != null)
                  HmDetailRow(label: 'Address', value: lease.propertyAddress!),
              ],
            ),
          ),
          const SizedBox(height: HmSpace.xl),

          HmCard(
            title: 'The Term',
            child: Column(
              children: [
                HmDetailRow(label: 'Lease Type', value: lease.leaseTypeLabel),
                HmDetailRow(
                  label: 'Starts',
                  value: lease.leaseStartDate == null
                      ? '—'
                      : _dayFormat.format(lease.leaseStartDate!),
                ),
                HmDetailRow(
                  label: 'Ends',
                  value:
                      lease.leaseEndDate == null ? '—' : _dayFormat.format(lease.leaseEndDate!),
                ),
                if (lease.leaseMonths != null)
                  HmDetailRow(label: 'Duration', value: '${lease.leaseMonths} months'),
                HmDetailRow(
                  label: 'Notice Period',
                  value: '${lease.noticePeriodDays ?? 90} days',
                ),
              ],
            ),
          ),
          const SizedBox(height: HmSpace.xl),

          HmCard(
            title: 'The Money',
            child: Column(
              children: [
                HmDetailRow(
                  label: 'Monthly Rent',
                  value: HmMoney.format(lease.monthlyRent, currency: lease.currency),
                ),
                HmDetailRow(
                  label: 'Security Deposit',
                  value: HmMoney.format(lease.depositAmount, currency: lease.currency),
                ),
                HmDetailRow(label: 'Booking Reference', value: lease.bookingReference),
                if (lease.reference != null)
                  HmDetailRow(label: 'Agreement Reference', value: lease.reference!),
              ],
            ),
          ),

          if ((lease.terms ?? '').isNotEmpty) ...[
            const SizedBox(height: HmSpace.xl),
            HmCard(
              title: 'Terms',
              child: Text(lease.terms!, style: HmText.body),
            ),
          ],

          if ((lease.houseRules ?? '').isNotEmpty) ...[
            const SizedBox(height: HmSpace.xl),
            HmCard(
              title: 'House Rules',
              child: Text(lease.houseRules!, style: HmText.body),
            ),
          ],

          const SizedBox(height: HmSpace.huge),

          if (lease.acceptedAt != null)
            HmNotice(
              message: 'Accepted electronically on ${_dayFormat.format(lease.acceptedAt!)}'
                  '${lease.version == null ? '' : ' (agreement ${lease.version})'}.',
              icon: Icons.verified_outlined,
              colour: HmColors.brandPrimary,
            ),

          const SizedBox(height: HmSpace.huge),
          FilledButton.icon(
            onPressed: lease.hasDocument
                ? () => _openDocument(context)
                // Disabled rather than hidden: the customer should be able to
                // see that a document is part of this and is simply not ready,
                // instead of wondering whether one exists at all.
                : null,
            icon: const Icon(Icons.download_outlined, size: 18),
            label: Text(lease.hasDocument ? 'Download contract PDF' : 'Contract PDF not ready'),
          ),
        ],
      );

  void _openDocument(BuildContext context) => HmFeedback.info(
        context,
        'Opening your contract. If it does not appear, check your downloads.',
      );
}
