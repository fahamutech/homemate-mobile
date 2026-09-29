import 'package:flutter/material.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../design/tokens.dart';
import '../../../../design/widgets/hm_key_value.dart';
import '../../../../design/widgets/hm_money.dart';
import '../../../../design/widgets/hm_section.dart';
import '../../data/partner_application.dart';

/// BRK-002c "How you earn — an example", every number from the server.
class FeeExampleCard extends StatelessWidget {
  const FeeExampleCard({super.key, required this.example});

  final FeeExample example;

  static String _percent(double value) => value == value.roundToDouble() ? '${value.round()}' : '$value';

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    return HmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(text.partnerExampleTitle, style: HmText.label.copyWith(color: HmColors.textSecondary)),
          const SizedBox(height: HmSpace.md),
          HmKeyValue(label: text.partnerExampleRent, value: HmMoney.format(example.rent)),
          HmKeyValue(label: text.partnerExampleFee(_percent(example.tenantFeePercentage)), value: HmMoney.format(example.tenantFee)),
          HmKeyValue(
            label: text.partnerExampleShare(_percent(example.platformPercentage)),
            value: '− ${HmMoney.format(example.platformAmount)}',
          ),
          const Divider(),
          HmKeyValue(
            label: text.partnerExampleReceive,
            value: HmMoney.format(example.youReceive),
            emphasis: HmKeyValueEmphasis.brand,
          ),
          const SizedBox(height: HmSpace.xs),
          Text(text.partnerExampleNote, style: HmText.caption),
        ],
      ),
    );
  }
}
