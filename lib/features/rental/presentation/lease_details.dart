import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/env.dart';
import '../../../core/i18n/app_text.dart';
import '../../../core/links/link_opener.dart';
import '../../../core/providers.dart';
import '../../../design/tokens.dart';
import '../../../design/widgets/hm_feedback.dart';
import '../../../design/widgets/hm_money.dart';
import '../../../design/widgets/hm_section.dart';
import '../../shared/journey_models.dart';

/// The lease behind a tenancy, as the tenant (CUS-012c) and the landlord
/// (LND-033) both read it.
///
/// Honest about the two cases: when an agreement has been drawn up it shows
/// the parties, the term and the document; when one has not, it still shows
/// the terms agreed at booking — binding whether or not anybody has produced
/// a PDF — and says plainly that the document is not ready.
class LeaseDetails extends ConsumerWidget {
  const LeaseDetails({super.key, required this.lease});

  final LeaseAgreement lease;

  static final _dayFormat = DateFormat('d MMM yyyy');

  static String typeLabel(AppText text, String? type) => switch (type) {
        'periodic' => text.leaseTypePeriodic,
        'month_to_month' => text.leaseTypeMonthly,
        _ => text.leaseTypeFixed,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = context.text;
    final document = documentUri(lease.documentUrl, apiBaseUrl: Env.apiBaseUrl);
    String day(DateTime? value) => value == null ? '—' : _dayFormat.format(value);
    return ListView(
      padding: const EdgeInsets.fromLTRB(HmSpace.xxl, HmSpace.xxl, HmSpace.xxl, HmSpace.section),
      children: [
        if (!lease.exists)
          Padding(
            padding: const EdgeInsets.only(bottom: HmSpace.huge),
            child: HmNotice(message: text.leaseNotReady, icon: Icons.schedule_outlined, colour: HmColors.info),
          ),
        HmCard(
          title: text.leaseParties,
          child: Column(children: [
            HmDetailRow(label: text.leaseTenant, value: lease.tenantName ?? '—'),
            HmDetailRow(label: text.leaseLandlord, value: lease.landlordName ?? '—'),
            if (lease.landlordPhone != null) HmDetailRow(label: text.leaseContact, value: lease.landlordPhone!),
            HmDetailRow(label: text.leaseProperty, value: lease.propertyTitle ?? '—'),
            if (lease.propertyAddress != null) HmDetailRow(label: text.leaseAddress, value: lease.propertyAddress!),
          ]),
        ),
        const SizedBox(height: HmSpace.xl),
        HmCard(
          title: text.leaseTerm,
          child: Column(children: [
            HmDetailRow(label: text.leaseType, value: typeLabel(text, lease.leaseType)),
            HmDetailRow(label: text.leaseStarts, value: day(lease.leaseStartDate)),
            HmDetailRow(label: text.leaseEnds, value: day(lease.leaseEndDate)),
            if (lease.leaseMonths != null) HmDetailRow(label: text.leaseDuration, value: text.tenancyLeaseMonths(lease.leaseMonths!)),
            HmDetailRow(label: text.leaseNotice, value: text.leaseNoticeDays(lease.noticePeriodDays ?? 90)),
          ]),
        ),
        const SizedBox(height: HmSpace.xl),
        HmCard(
          title: text.leaseMoney,
          child: Column(children: [
            HmDetailRow(label: text.leaseRent, value: HmMoney.format(lease.monthlyRent, currency: lease.currency)),
            HmDetailRow(label: text.leaseDeposit, value: HmMoney.format(lease.depositAmount, currency: lease.currency)),
            HmDetailRow(label: text.leaseBookingRef, value: lease.bookingReference),
            if (lease.reference != null) HmDetailRow(label: text.leaseAgreementRef, value: lease.reference!),
          ]),
        ),
        if ((lease.terms ?? '').isNotEmpty) ...[
          const SizedBox(height: HmSpace.xl),
          HmCard(title: text.leaseTerms, child: Text(lease.terms!, style: HmText.body)),
        ],
        if ((lease.houseRules ?? '').isNotEmpty) ...[
          const SizedBox(height: HmSpace.xl),
          HmCard(title: text.leaseHouseRules, child: Text(lease.houseRules!, style: HmText.body)),
        ],
        const SizedBox(height: HmSpace.huge),
        if (lease.acceptedAt != null)
          HmNotice(
            message: lease.version == null
                ? text.leaseAcceptedOn(_dayFormat.format(lease.acceptedAt!))
                : text.leaseAcceptedOnVersion(_dayFormat.format(lease.acceptedAt!), lease.version!),
            icon: Icons.verified_outlined,
            colour: HmColors.brandPrimary,
          ),
        const SizedBox(height: HmSpace.huge),
        FilledButton.icon(
          // Disabled rather than hidden: a document is part of this and is
          // simply not ready yet (or its link is not one we will open).
          onPressed: document == null ? null : () => _open(context, ref, document),
          icon: const Icon(Icons.download_outlined, size: 18),
          label: Text(document != null ? text.leaseDownload : text.leasePdfNotReady),
        ),
      ],
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref, Uri document) async {
    final text = context.text;
    final opened = await ref.read(linkOpenerProvider).open(document).catchError((_) => false);
    if (!opened && context.mounted) HmFeedback.info(context, text.leaseOpenFailed);
  }
}
