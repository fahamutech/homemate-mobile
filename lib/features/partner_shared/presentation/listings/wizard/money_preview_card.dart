import 'package:flutter/material.dart';

import '../../../../../core/i18n/app_text.dart';
import '../../../../../design/tokens.dart';
import '../../../../../design/widgets/hm_key_value.dart';
import '../../../../../design/widgets/hm_money.dart';
import '../../../../../design/widgets/hm_section.dart';
import '../../../data/partner_listing.dart';

/// BRK-030c "What the tenant pays to move in" and "You earn", exactly as the
/// server worked them out for this listing.
class MoneyPreviewCard extends StatelessWidget {
  const MoneyPreviewCard({super.key, required this.preview});

  final MoneyPreview preview;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final percent = preview.tenantFeePercentage == preview.tenantFeePercentage.roundToDouble()
        ? '${preview.tenantFeePercentage.round()}'
        : '${preview.tenantFeePercentage}';
    return HmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(text.wizardMoveInTitle, style: HmText.label.copyWith(color: HmColors.textSecondary)),
          const SizedBox(height: HmSpace.md),
          HmKeyValue(
            label: preview.advance > 0 ? text.wizardMoveInAdvance : text.wizardMoveInFirstRent,
            value: HmMoney.format(preview.firstRent),
          ),
          HmKeyValue(label: text.wizardMoveInDeposit, value: HmMoney.format(preview.deposit)),
          HmKeyValue(label: text.wizardMoveInFee(percent), value: HmMoney.format(preview.tenantFee)),
          const Divider(),
          HmKeyValue(label: text.wizardMoveInTotal, value: HmMoney.format(preview.total), emphasis: HmKeyValueEmphasis.total),
          if (preview.youEarn > 0) ...[
            const SizedBox(height: HmSpace.md),
            Container(
              padding: const EdgeInsets.all(HmSpace.lg),
              decoration: BoxDecoration(color: HmColors.greenBg, borderRadius: BorderRadius.circular(HmRadius.sm)),
              child: Row(
                children: [
                  const Icon(Icons.payments_outlined, size: 18, color: HmColors.greenText),
                  const SizedBox(width: HmSpace.md),
                  Expanded(
                    child: Text(
                      text.wizardYouEarn(HmMoney.format(preview.youEarn)),
                      style: HmText.label.copyWith(color: HmColors.greenText),
                    ),
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
