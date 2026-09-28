import 'package:flutter/material.dart';

import '../../design/tokens.dart';
import '../../design/widgets/hm_money.dart';
import 'models.dart';

/// The HomeMate fee, drawn out and highlighted: what it is, what the usual
/// agent would have charged, and what the customer keeps.
///
/// An agent in this market customarily takes a full month's rent for finding a
/// tenant. HomeMate charges a share of that month instead, once, in the first
/// payment — and the whole point of showing it is the saving, so the saving is
/// the loudest thing on the card.
class ServiceFeeCard extends StatelessWidget {
  const ServiceFeeCard({
    super.key,
    required this.fee,
    this.currency = 'TZS',
    this.inFirstPayment = false,
  });

  final ServiceFee fee;
  final String currency;

  /// At checkout the fee is already part of the total being paid; on a
  /// listing it is what the first payment will include.
  final bool inFirstPayment;

  @override
  Widget build(BuildContext context) {
    String money(double value) => HmMoney.format(value, currency: currency);

    return Container(
      key: const Key('service-fee-card'),
      width: double.infinity,
      padding: const EdgeInsets.all(HmSpace.xxl),
      decoration: BoxDecoration(
        color: HmColors.brandPrimarySoft,
        borderRadius: HmRadius.card,
        border: Border.all(color: HmColors.brandPrimary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.savings_outlined, size: 20, color: HmColors.brandPrimary),
              const SizedBox(width: HmSpace.md),
              Expanded(
                child: Text(
                  'HomeMate fee: ${money(fee.amount)}',
                  style: HmText.heading.copyWith(fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: HmSpace.xs),
          Text(
            inFirstPayment
                ? '${fee.percentageLabel} of one month’s rent, included once in this payment.'
                : '${fee.percentageLabel} of one month’s rent, charged once in your first payment.',
            style: HmText.caption,
          ),
          const SizedBox(height: HmSpace.xl),
          Row(
            children: [
              Expanded(child: Text(fee.benchmarkLabel, style: HmText.caption)),
              Text(
                money(fee.benchmarkAmount),
                style: HmText.caption.copyWith(decoration: TextDecoration.lineThrough),
              ),
            ],
          ),
          if (fee.savesSomething) ...[
            const SizedBox(height: HmSpace.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: HmSpace.xl, vertical: HmSpace.md),
              decoration: BoxDecoration(
                color: HmColors.bgPrimary,
                borderRadius: BorderRadius.circular(HmRadius.sm),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 16, color: HmColors.success),
                  const SizedBox(width: HmSpace.md),
                  const Expanded(child: Text('You save', style: HmText.label)),
                  Text(
                    money(fee.saving),
                    key: const Key('service-fee-saving'),
                    style: HmText.price.copyWith(fontSize: 17),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
