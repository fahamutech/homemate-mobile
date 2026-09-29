import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../design/tokens.dart';
import '../../../../design/widgets/hm_async.dart';
import '../../../../design/widgets/hm_key_value.dart';
import '../../../../design/widgets/hm_money.dart';
import '../../../../design/widgets/hm_note.dart';
import '../../../../design/widgets/hm_section.dart';
import '../../../../design/widgets/hm_timeline_step.dart';
import '../../data/partner_enquiry.dart';
import '../../data/partner_providers.dart';
import 'enquiry_copy.dart';

/// BRK-042: once accepted, the tracker, what the customer pays (as the
/// server worked it out) and what the partner earns when it is verified.
class EnquiryJourneySection extends ConsumerWidget {
  const EnquiryJourneySection({super.key, required this.enquiryId});

  final String enquiryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = context.text;
    return HmAsync<EnquiryJourney>(
      value: ref.watch(enquiryJourneyProvider(enquiryId)),
      onRetry: () => ref.invalidate(enquiryJourneyProvider(enquiryId)),
      data: (journey) {
        final name = firstName(journey.enquiry.customerName);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HmSectionHeader(title: text.journeyTitle),
            HmCard(
              child: Column(children: [
                for (final (index, step) in journey.steps.indexed)
                  HmTimelineStep(
                    title: journeyStepTitle(text, step, journey.enquiry),
                    state: HmStepState.fromServer(step.state),
                    date: step.at == null ? null : DateFormat('d MMM, HH:mm').format(step.at!.toLocal()),
                    isLast: index == journey.steps.length - 1,
                  ),
              ]),
            ),
            const SizedBox(height: HmSpace.xl),
            HmCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(text.journeyCustomerPays(name), style: HmText.label.copyWith(color: HmColors.textSecondary)),
                  const SizedBox(height: HmSpace.md),
                  HmKeyValue(
                    label: journey.advance > 0 ? text.journeyAdvance : text.journeyFirstRent,
                    value: HmMoney.format(journey.advance > 0 ? journey.advance : journey.firstRent),
                  ),
                  HmKeyValue(label: text.journeyDeposit, value: HmMoney.format(journey.deposit)),
                  HmKeyValue(label: text.journeyFee(percentLabel(journey.tenantFeePercentage)), value: HmMoney.format(journey.tenantFee)),
                  const Divider(),
                  HmKeyValue(label: text.journeyTotal, value: HmMoney.format(journey.total), emphasis: HmKeyValueEmphasis.total),
                  if (journey.yourShare > 0) ...[
                    const SizedBox(height: HmSpace.md),
                    HmKeyValue(label: text.journeyYourEarning, value: HmMoney.format(journey.yourShare), emphasis: HmKeyValueEmphasis.brand),
                  ],
                ],
              ),
            ),
            const SizedBox(height: HmSpace.xl),
            HmNote(text: text.journeyHold(name), tone: HmNoteTone.info),
          ],
        );
      },
    );
  }
}
