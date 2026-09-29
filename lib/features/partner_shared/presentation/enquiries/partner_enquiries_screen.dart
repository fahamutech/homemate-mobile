import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../design/tokens.dart';
import '../../../../design/widgets/hm_async.dart';
import '../../../../design/widgets/hm_badge.dart';
import '../../../../design/widgets/hm_button.dart';
import '../../../../design/widgets/hm_choice.dart';
import '../../../../design/widgets/hm_section.dart';
import '../../../../design/widgets/hm_top_bar.dart';
import '../../../../routing/routes.dart';
import '../../../roles/data/app_role.dart';
import '../../data/partner_enquiry.dart';
import '../../data/partner_providers.dart';
import '../partner_photo.dart';
import 'customer_avatar_initials.dart';
import 'enquiry_contact_buttons.dart';
import 'enquiry_copy.dart';

/// BRK-040: enquiries on the partner's homes, by New / Replied / Accepted /
/// Closed, each with who asked, what, and a way to reach them.
class PartnerEnquiriesScreen extends ConsumerStatefulWidget {
  const PartnerEnquiriesScreen({super.key, required this.role});

  final AppRole role;

  @override
  ConsumerState<PartnerEnquiriesScreen> createState() => _PartnerEnquiriesScreenState();
}

class _PartnerEnquiriesScreenState extends ConsumerState<PartnerEnquiriesScreen> {
  String _tab = 'new';

  static const _tabs = ['new', 'replied', 'accepted', 'closed'];
  static const _statuses = {
    'new': {'pending'},
    'replied': {'responded'},
    'accepted': {'accepted'},
    'closed': {'rejected', 'withdrawn', 'closed'},
  };

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    String tabLabel(String tab) => switch (tab) {
          'new' => text.enquiriesTabNew,
          'replied' => text.enquiriesTabReplied,
          'accepted' => text.enquiriesTabAccepted,
          _ => text.enquiriesTabClosed,
        };

    return Scaffold(
      appBar: HmTopBar(title: text.enquiriesTitle),
      body: HmAsync<List<PartnerEnquiry>>(
        value: ref.watch(partnerEnquiriesProvider(null)),
        onRetry: () => ref.invalidate(partnerEnquiriesProvider(null)),
        data: (all) {
          int count(String tab) => all.where((e) => _statuses[tab]!.contains(e.status)).length;
          final shown = [for (final e in all) if (_statuses[_tab]!.contains(e.status)) e];
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(partnerEnquiriesProvider(null)),
            child: ListView(
              padding: const EdgeInsets.all(HmSpace.xxl),
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    for (final tab in _tabs) ...[
                      HmChoicePill(
                        key: ValueKey('enquiry-tab-$tab'),
                        label: tabLabel(tab),
                        count: count(tab),
                        dense: true,
                        selected: _tab == tab,
                        onTap: () => setState(() => _tab = tab),
                      ),
                      const SizedBox(width: HmSpace.md),
                    ],
                  ]),
                ),
                const SizedBox(height: HmSpace.xxl),
                if (shown.isEmpty) Text(text.enquiriesEmpty, textAlign: TextAlign.center, style: HmText.body),
                for (final enquiry in shown) ...[
                  _EnquiryCard(role: widget.role, enquiry: enquiry),
                  const SizedBox(height: HmSpace.xl),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EnquiryCard extends StatelessWidget {
  const _EnquiryCard({required this.role, required this.enquiry});

  final AppRole role;
  final PartnerEnquiry enquiry;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final channel = contactChannel(text, enquiry.contactPreference);
    final phone = enquiry.customerPhone;

    return HmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            InitialsAvatar(name: enquiry.customerName),
            const SizedBox(width: HmSpace.xl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(enquiry.customerName, style: HmText.label.copyWith(fontSize: 16)),
                  Text(
                    [whenLabel(enquiry.createdAt), if (channel.isNotEmpty) text.enquiriesPrefers(channel)].join(' · '),
                    style: HmText.caption,
                  ),
                ],
              ),
            ),
            HmBadge(label: enquiryStatusLabel(text, enquiry.status), tone: enquiryStatusTone(enquiry.status)),
          ]),
          const SizedBox(height: HmSpace.xl),
          Container(
            padding: const EdgeInsets.all(HmSpace.md),
            decoration: BoxDecoration(color: HmColors.bgSecondary, borderRadius: BorderRadius.circular(HmRadius.sm)),
            child: Row(children: [
              SizedBox(width: 32, height: 32, child: PartnerPhoto(url: enquiry.propertyCoverUrl, radius: 6)),
              const SizedBox(width: HmSpace.md),
              Expanded(child: Text(enquiry.propertyTitle, style: HmText.label.copyWith(fontSize: 14))),
            ]),
          ),
          if ((enquiry.message ?? '').isNotEmpty) ...[
            const SizedBox(height: HmSpace.xl),
            Text('“${enquiry.message}”', style: HmText.body),
          ],
          const SizedBox(height: HmSpace.xl),
          Wrap(
            spacing: HmSpace.sm,
            runSpacing: HmSpace.sm,
            children: [for (final fact in enquiryFacts(text, enquiry)) HmBadge(label: fact)],
          ),
          const SizedBox(height: HmSpace.xl),
          Row(children: [
            Expanded(
              child: HmButton(
                label: enquiry.isOpen && enquiry.canAnswer ? text.enquiriesReply : text.enquiriesOpen,
                size: HmButtonSize.medium,
                onPressed: () => context.push(Routes.partnerEnquiry(role, enquiry.id)),
              ),
            ),
            if (phone != null) ...[
              const SizedBox(width: HmSpace.md),
              EnquiryContactButtons(phone: phone),
            ],
          ]),
        ],
      ),
    );
  }
}
