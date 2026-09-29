import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../core/providers.dart';
import '../../../../design/tokens.dart';
import '../../../../design/widgets/hm_async.dart';
import '../../../../design/widgets/hm_badge.dart';
import '../../../../design/widgets/hm_button.dart';
import '../../../../design/widgets/hm_feedback.dart';
import '../../../../design/widgets/hm_key_value.dart';
import '../../../../design/widgets/hm_money.dart';
import '../../../../design/widgets/hm_note.dart';
import '../../../../design/widgets/hm_radio_card.dart';
import '../../../../design/widgets/hm_section.dart';
import '../../../../design/widgets/hm_text_field.dart';
import '../../../../design/widgets/hm_top_bar.dart';
import '../../../roles/data/app_role.dart';
import '../../data/partner_enquiry.dart';
import '../../data/partner_providers.dart';
import '../partner_photo.dart';
import 'customer_avatar_initials.dart';
import 'decline_sheet.dart';
import 'enquiry_contact_buttons.dart';
import 'enquiry_copy.dart';
import 'enquiry_journey_section.dart';

/// BRK-041: one enquiry — who asked and what — and the four ways to answer.
/// Accepted enquiries show the BRK-042 journey; a partner who may only read
/// (a landlord whose home a broker listed) sees neither answers nor contacts.
class PartnerEnquiryScreen extends ConsumerWidget {
  const PartnerEnquiryScreen({super.key, required this.role, required this.enquiryId});

  final AppRole role;
  final String enquiryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: HmTopBar(title: context.text.enquiryTitle),
        body: HmAsync<PartnerEnquiry>(
          value: ref.watch(partnerEnquiryProvider(enquiryId)),
          onRetry: () => ref.invalidate(partnerEnquiryProvider(enquiryId)),
          data: (enquiry) => _EnquiryBody(enquiry: enquiry),
        ),
      );
}

class _EnquiryBody extends ConsumerStatefulWidget {
  const _EnquiryBody({required this.enquiry});

  final PartnerEnquiry enquiry;

  @override
  ConsumerState<_EnquiryBody> createState() => _EnquiryBodyState();
}

class _EnquiryBodyState extends ConsumerState<_EnquiryBody> {
  final _reply = TextEditingController();
  EnquiryOutcome _outcome = EnquiryOutcome.reply;
  String? _error;
  bool _sending = false;

  PartnerEnquiry get enquiry => widget.enquiry;

  bool get _answering => enquiry.canAnswer && enquiry.isOpen;

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  /// A reply and an acceptance need words; a decline needs a reason.
  Future<void> _send() async {
    final text = context.text;
    final reply = _reply.text.trim();
    String? reason;
    if ((_outcome == EnquiryOutcome.reply || _outcome == EnquiryOutcome.accept) && reply.isEmpty) {
      setState(() => _error = text.enquiryReplyRequired);
      return;
    }
    if (_outcome == EnquiryOutcome.decline) {
      reason = await showDeclineSheet(context, customerName: firstName(enquiry.customerName));
      if (reason == null || !mounted) return;
    }
    setState(() => _sending = true);
    try {
      await ref.read(enquiriesRepositoryProvider).respond(
            enquiry.id,
            outcome: _outcome,
            response: reply.isEmpty ? null : reply,
            rejectionReason: reason,
          );
      ref.invalidate(partnerEnquiryProvider(enquiry.id));
      ref.invalidate(partnerEnquiriesProvider);
      ref.invalidate(partnerSummaryProvider);
      if (mounted) HmFeedback.success(context, text.enquirySent);
    } catch (error) {
      if (mounted) HmFeedback.failure(context, error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _sendLabel(AppText text) => switch (_outcome) {
        EnquiryOutcome.reply => text.enquirySendReply,
        EnquiryOutcome.accept => text.enquirySendAccept,
        EnquiryOutcome.decline => text.enquirySendDecline,
        EnquiryOutcome.close => text.enquirySendClose,
      };

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final name = firstName(enquiry.customerName);
    final answered = (enquiry.response ?? enquiry.rejectionReason ?? '').isNotEmpty;

    return Column(children: [
      Expanded(
        // Not lazy: the outcomes and the reply field must exist to be scrolled to.
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(HmSpace.xxl),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _CustomerCard(enquiry: enquiry),
            const SizedBox(height: HmSpace.xl),
            if (!enquiry.canAnswer) ...[
              HmNote(text: text.enquiryReadOnly, tone: HmNoteTone.info),
              const SizedBox(height: HmSpace.xl),
            ],
            if (!enquiry.isOpen && answered) ...[
              HmCard(
                title: text.enquiryAnswered,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if ((enquiry.response ?? '').isNotEmpty) Text(enquiry.response!, style: HmText.body),
                  if ((enquiry.rejectionReason ?? '').isNotEmpty) Text(enquiry.rejectionReason!, style: HmText.body),
                ]),
              ),
              const SizedBox(height: HmSpace.xl),
            ],
            if (enquiry.status == 'accepted') EnquiryJourneySection(enquiryId: enquiry.id),
            if (_answering) ...[
              HmSectionHeader(title: text.enquiryNext),
              for (final (outcome, icon, title, subtitle) in [
                (EnquiryOutcome.reply, Icons.chat_bubble_outline, text.enquiryOutcomeReply, text.enquiryOutcomeReplyBody),
                (EnquiryOutcome.accept, Icons.check_circle_outline, text.enquiryOutcomeAccept, text.enquiryOutcomeAcceptBody(name)),
                (EnquiryOutcome.decline, Icons.cancel_outlined, text.enquiryOutcomeDecline, text.enquiryOutcomeDeclineBody(name)),
                (EnquiryOutcome.close, Icons.archive_outlined, text.enquiryOutcomeClose, ''),
              ]) ...[
                HmRadioCard(
                  key: ValueKey('outcome-${outcome.name}'),
                  icon: icon,
                  title: title,
                  subtitle: subtitle,
                  selected: _outcome == outcome,
                  onTap: () => setState(() {
                    _outcome = outcome;
                    _error = null;
                  }),
                ),
                const SizedBox(height: HmSpace.md),
              ],
              const SizedBox(height: HmSpace.md),
              HmTextField(
                fieldKey: const ValueKey('enquiry-reply'),
                label: text.enquiryYourReply,
                controller: _reply,
                maxLines: 4,
                errorText: _error,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
              ),
            ],
          ]),
        ),
      ),
      if (_answering)
        Container(
          padding: const EdgeInsets.all(HmSpace.xxl),
          decoration: const BoxDecoration(color: HmColors.bgPrimary, border: Border(top: BorderSide(color: HmColors.borderDefault))),
          child: SafeArea(
            top: false,
            child: HmButton(
              label: _sendLabel(text),
              style: _outcome == EnquiryOutcome.decline ? HmButtonStyle.danger : HmButtonStyle.primary,
              busy: _sending,
              onPressed: _send,
            ),
          ),
        ),
    ]);
  }
}

/// Who asked, about which home, and what they said.
class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.enquiry});

  final PartnerEnquiry enquiry;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final phone = enquiry.canAnswer ? enquiry.customerPhone : null;
    return HmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            InitialsAvatar(name: enquiry.customerName, radius: 24),
            const SizedBox(width: HmSpace.xl),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(enquiry.customerName, style: HmText.label.copyWith(fontSize: 17)),
                if (enquiry.customerIdVerified) ...[
                  const SizedBox(height: HmSpace.xs),
                  HmBadge(label: text.enquiryIdVerified, tone: HmBadgeTone.success, icon: Icons.verified_outlined),
                ],
              ]),
            ),
            if (phone != null) EnquiryContactButtons(phone: phone),
          ]),
          const SizedBox(height: HmSpace.xl),
          Row(children: [
            SizedBox(width: 40, height: 40, child: PartnerPhoto(url: enquiry.propertyCoverUrl, radius: 8)),
            const SizedBox(width: HmSpace.md),
            Expanded(child: Text(enquiry.propertyTitle, style: HmText.label)),
            HmBadge(label: enquiryStatusLabel(text, enquiry.status), tone: enquiryStatusTone(enquiry.status)),
          ]),
          if ((enquiry.message ?? '').isNotEmpty) ...[
            const SizedBox(height: HmSpace.xl),
            Text('“${enquiry.message}”', style: HmText.body),
          ],
          const SizedBox(height: HmSpace.md),
          if (enquiry.moveInDate != null)
            HmKeyValue(label: text.enquiryMoveIn, value: DateFormat('d MMM yyyy').format(enquiry.moveInDate!)),
          if (enquiry.occupants != null) HmKeyValue(label: text.enquiryPeople, value: '${enquiry.occupants}'),
          if (enquiry.budgetAmount != null) HmKeyValue(label: text.enquiryBudget, value: HmMoney.format(enquiry.budgetAmount)),
          if ((enquiry.preferredContactTime ?? '').isNotEmpty)
            HmKeyValue(label: text.enquiryBestTime, value: enquiry.preferredContactTime!),
        ],
      ),
    );
  }
}
