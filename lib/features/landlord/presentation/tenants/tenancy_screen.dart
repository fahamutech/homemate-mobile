import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../design/tokens.dart';
import '../../../../design/widgets/hm_async.dart';
import '../../../../design/widgets/hm_badge.dart';
import '../../../../design/widgets/hm_button.dart';
import '../../../../design/widgets/hm_key_value.dart';
import '../../../../design/widgets/hm_list_tile.dart';
import '../../../../design/widgets/hm_money.dart';
import '../../../../design/widgets/hm_note.dart';
import '../../../../design/widgets/hm_section.dart';
import '../../../../design/widgets/hm_top_bar.dart';
import '../../../../routing/routes.dart';
import '../../../partner_shared/presentation/contact_buttons.dart';
import '../../../partner_shared/presentation/enquiries/customer_avatar_initials.dart';
import '../../../partner_shared/presentation/enquiries/enquiry_copy.dart' show firstName;
import '../../../shared/models.dart' show CustomerPayment;
import '../../data/landlord_providers.dart';
import '../../data/tenancy.dart';
import 'tenancy_actions.dart';
import 'tenancy_copy.dart';

/// LND-031 moving in / LND-033 living here / a past tenancy: the tenant, the
/// lease, the money and the payments — with the move-in only while moving
/// in, and "End tenancy" only while someone lives there.
class TenancyScreen extends ConsumerWidget {
  const TenancyScreen({super.key, required this.tenancyId});

  final String tenancyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = context.text;
    return Scaffold(
      appBar: HmTopBar(title: text.tenancyTitle),
      body: HmAsync<Tenancy>(
        value: ref.watch(tenancyProvider(tenancyId)),
        onRetry: () => ref.invalidate(tenancyProvider(tenancyId)),
        data: (tenancy) {
          final day = DateFormat('d MMM yyyy');
          String? date(DateTime? value) => value == null ? null : day.format(value);
          final when = tenancyWhen(text, tenancy);
          return Column(children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(HmSpace.xxl),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  HmCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Row(children: [
                        InitialsAvatar(name: tenancy.tenantName, radius: 24),
                        const SizedBox(width: HmSpace.xl),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(tenancy.tenantName, style: HmText.label.copyWith(fontSize: 17)),
                            const SizedBox(height: HmSpace.xs),
                            HmBadge(label: tenancyStageLabel(text, tenancy.stage), tone: tenancyStageTone(tenancy.stage)),
                          ]),
                        ),
                        if (tenancy.tenantPhone != null && tenancy.stage != TenancyStage.past) ContactButtons(phone: tenancy.tenantPhone!),
                      ]),
                      const SizedBox(height: HmSpace.xl),
                      Text(tenancy.propertyTitle, style: HmText.label),
                      if ((tenancy.propertyAddress ?? '').isNotEmpty) Text(tenancy.propertyAddress!, style: HmText.caption),
                      if (when != null) ...[
                        const SizedBox(height: HmSpace.sm),
                        Text(when, style: HmText.caption),
                      ],
                    ]),
                  ),
                  const SizedBox(height: HmSpace.xl),
                  if (tenancy.canConfirmMoveIn) ...[
                    HmNote(text: text.tenancyMovingInNote(firstName(tenancy.tenantName)), tone: HmNoteTone.info),
                    const SizedBox(height: HmSpace.xl),
                  ],
                  HmCard(
                    title: text.tenancyLease,
                    child: Column(children: [
                      HmKeyValue(label: text.tenancyRent, value: HmMoney.format(tenancy.monthlyRent, currency: tenancy.currency)),
                      HmKeyValue(label: text.tenancyDeposit, value: HmMoney.format(tenancy.depositAmount, currency: tenancy.currency)),
                      if (tenancy.leaseStartDate != null)
                        HmKeyValue(
                          label: text.tenancyLease,
                          value: [
                            date(tenancy.leaseStartDate),
                            if (tenancy.leaseEndDate != null) date(tenancy.leaseEndDate),
                          ].join(' – '),
                        ),
                      if (tenancy.leaseMonths != null) HmKeyValue(label: '', value: text.tenancyLeaseMonths(tenancy.leaseMonths!)),
                      if (tenancy.moveInDate != null) HmKeyValue(label: text.tenancyMoveIn, value: date(tenancy.moveInDate)!),
                      if (tenancy.stage == TenancyStage.current && tenancy.monthsRemaining != null)
                        HmKeyValue(label: text.tenancyMonthsLeft, value: '${tenancy.monthsRemaining}'),
                      if ((tenancy.endReason ?? '').isNotEmpty) HmKeyValue(label: text.tenancyEndReason, value: tenancy.endReason!),
                      if ((tenancy.agreementReference ?? '').isNotEmpty)
                        HmKeyValue(label: text.tenancyAgreement, value: tenancy.agreementReference!),
                    ]),
                  ),
                  const SizedBox(height: HmSpace.md),
                  HmListTile(
                    icon: Icons.description_outlined,
                    title: text.leaseTitle,
                    boxed: true,
                    onTap: () => context.push(Routes.landlordTenancyLease(tenancy.id)),
                  ),
                  const SizedBox(height: HmSpace.xl),
                  HmCard(
                    title: text.tenancyPayments,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      HmKeyValue(label: text.tenancyPaid, value: HmMoney.format(tenancy.amountPaid, currency: tenancy.currency)),
                      if (tenancy.amountOutstanding > 0)
                        HmKeyValue(label: text.tenancyOutstanding, value: HmMoney.format(tenancy.amountOutstanding, currency: tenancy.currency)),
                      const Divider(),
                      if (tenancy.payments.isEmpty) Text(text.tenancyNoPayments, style: HmText.caption),
                      for (final payment in tenancy.payments) _PaymentRow(payment: payment),
                    ]),
                  ),
                ]),
              ),
            ),
            if (tenancy.canConfirmMoveIn || tenancy.canEnd)
              Container(
                padding: const EdgeInsets.all(HmSpace.xxl),
                decoration: const BoxDecoration(color: HmColors.bgPrimary, border: Border(top: BorderSide(color: HmColors.borderDefault))),
                child: SafeArea(
                  top: false,
                  child: tenancy.canConfirmMoveIn
                      ? HmButton(label: text.tenancyConfirmMoveIn, icon: Icons.key_outlined, onPressed: () => confirmMoveIn(context, ref, tenancy))
                      : HmButton(label: text.tenancyEnd, style: HmButtonStyle.dangerOutline, onPressed: () => endTenancy(context, ref, tenancy)),
                ),
              ),
          ]);
        },
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.payment});

  final CustomerPayment payment;

  @override
  Widget build(BuildContext context) {
    final at = payment.confirmedAt ?? payment.declaredAt ?? payment.createdAt;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: HmSpace.sm),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(payment.reference, style: HmText.label),
            if (at != null) Text(DateFormat('d MMM yyyy').format(at.toLocal()), style: HmText.caption),
          ]),
        ),
        Text(payment.amountLabel, style: HmText.label),
        const SizedBox(width: HmSpace.md),
        Icon(
          payment.isPaid ? Icons.check_circle_outline_rounded : Icons.hourglass_top_rounded,
          size: 18,
          color: payment.isPaid ? HmColors.success : HmColors.textSecondary,
        ),
      ]),
    );
  }
}
