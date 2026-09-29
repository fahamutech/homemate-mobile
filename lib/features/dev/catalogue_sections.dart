import 'package:flutter/material.dart';

import '../../core/i18n/app_text.dart';
import '../../design/tokens.dart';
import '../../design/widgets/hm_attention_row.dart';
import '../../design/widgets/hm_badge.dart';
import '../../design/widgets/hm_bottom_nav.dart';
import '../../design/widgets/hm_button.dart';
import '../../design/widgets/hm_choice.dart';
import '../../design/widgets/hm_document_card.dart';
import '../../design/widgets/hm_key_value.dart';
import '../../design/widgets/hm_list_tile.dart';
import '../../design/widgets/hm_listing_card.dart';
import '../../design/widgets/hm_money_row.dart';
import '../../design/widgets/hm_note.dart';
import '../../design/widgets/hm_radio_card.dart';
import '../../design/widgets/hm_role_header.dart';
import '../../design/widgets/hm_section.dart';
import '../../design/widgets/hm_segmented.dart';
import '../../design/widgets/hm_slide.dart';
import '../../design/widgets/hm_stat_card.dart';
import '../../design/widgets/hm_step_progress.dart';
import '../../design/widgets/hm_text_field.dart';
import '../../design/widgets/hm_timeline_step.dart';
import '../../design/widgets/hm_top_bar.dart';
import '../../routing/nav_tabs.dart';

/// The catalogue's sections, one per group of Figma components. Every widget
/// is shown in each of its states; the copy is the app's own, so switching
/// language shows the Kiswahili build as well.

const _gap = SizedBox(height: HmSpace.xl);

List<Widget> buttonSamples(AppText text) => [
      for (final style in HmButtonStyle.values) ...[
        Row(children: [
          Expanded(child: HmButton(label: text.save, style: style, size: HmButtonSize.medium, onPressed: () {})),
          const SizedBox(width: HmSpace.md),
          Expanded(child: HmButton(label: text.save, style: style, size: HmButtonSize.medium, onPressed: null)),
        ]),
        _gap,
      ],
      for (final size in HmButtonSize.values) ...[
        HmButton(label: text.next, size: size, icon: Icons.arrow_forward_rounded, onPressed: () {}),
        _gap,
      ],
      Row(children: [
        HmButton(label: text.search, icon: Icons.search_rounded, iconOnly: true, style: HmButtonStyle.soft, onPressed: () {}),
        const SizedBox(width: HmSpace.md),
        Expanded(child: HmButton(label: text.save, busy: true, onPressed: () {})),
      ]),
    ];

List<Widget> badgeSamples(AppText text) => [
      Wrap(spacing: HmSpace.md, runSpacing: HmSpace.md, children: [
        HmBadge(label: text.devSampleLive, tone: HmBadgeTone.success),
        HmBadge(label: text.devSamplePending, tone: HmBadgeTone.warning),
        HmBadge(label: text.devSampleRejected, tone: HmBadgeTone.error),
        HmBadge(label: text.devSampleEnquiry, tone: HmBadgeTone.info),
        HmBadge(label: text.optional, tone: HmBadgeTone.neutral),
        HmBadge(label: text.devSamplePaid, tone: HmBadgeTone.primary, icon: Icons.verified_rounded),
      ]),
    ];

List<Widget> noteSamples(AppText text) => [
      for (final tone in HmNoteTone.values) ...[HmNote(text: text.devSampleNote, tone: tone), _gap],
    ];

List<Widget> dataSamples(AppText text) => [
      HmSectionHeader(title: text.devWidgetsData, action: text.seeAll, onAction: () {}),
      for (final emphasis in HmKeyValueEmphasis.values)
        HmKeyValue(label: text.devSampleFieldLabel, value: 'TZS 800,000', emphasis: emphasis),
      _gap,
      HmListTile(icon: Icons.person_outline_rounded, title: text.navProfile, onTap: () {}),
      HmListTile(
        icon: Icons.account_balance_wallet_rounded,
        title: text.navEarnings,
        subtitle: text.devSampleFieldHint,
        boxed: true,
        badge: HmBadge(label: text.devSampleLive, tone: HmBadgeTone.success),
        onTap: () {},
      ),
      HmListTile(icon: Icons.language_rounded, title: text.language, value: text.currentLanguage, trailingIcon: null),
    ];

List<Widget> partnerSamples(AppText text) => [
      HmRoleHeader(
        greeting: text.greeting('Baraka'),
        initials: 'BM',
        roleLabel: text.navListings,
        roleIcon: Icons.real_estate_agent_rounded,
        onSwitchRole: () {},
        onNotifications: () {},
        unreadCount: 2,
      ),
      _gap,
      for (final (tone, icon) in [
        (HmAttentionTone.orange, Icons.forum_rounded),
        (HmAttentionTone.red, Icons.edit_note_rounded),
        (HmAttentionTone.blue, Icons.fact_check_rounded),
        (HmAttentionTone.green, Icons.payments_rounded),
      ])
        HmAttentionRow(icon: icon, title: text.devSampleEnquiry, subtitle: text.devSampleHome, tone: tone, onTap: () {}),
      _gap,
      HmListingCard(
        title: text.devSampleHome,
        area: 'Masaki, Dar es Salaam',
        price: 'TZS 800,000/mo',
        status: HmBadge(label: text.devSampleLive, tone: HmBadgeTone.success),
        meta: text.devSampleEnquiry,
        onTap: () {},
      ),
      _gap,
      HmListingCard(
        title: text.devSampleHome,
        area: 'Mbezi, Dar es Salaam',
        price: 'TZS 500,000/mo',
        status: HmBadge(label: text.devSamplePending, tone: HmBadgeTone.warning),
        listedBy: 'Neema',
      ),
      _gap,
      Row(children: [
        Expanded(child: HmStatCard(label: text.devSampleLive, value: '4')),
        const SizedBox(width: HmSpace.md),
        Expanded(child: HmStatCard(label: text.navEnquiries, value: '12')),
        const SizedBox(width: HmSpace.md),
        Expanded(child: HmStatCard(label: text.navEarnings, value: '360k', sub: 'TZS')),
      ]),
      _gap,
      HmDocumentCard(
        icon: Icons.badge_rounded,
        title: 'NIDA',
        description: text.devSampleFieldHint,
        status: HmBadge(label: text.devSamplePending, tone: HmBadgeTone.warning),
        actionLabel: text.change,
        onAction: () {},
      ),
      _gap,
      HmDocumentCard(
        icon: Icons.home_work_rounded,
        title: text.devSampleHome,
        description: text.devSampleFieldHint,
        status: HmBadge(label: text.devSampleLive, tone: HmBadgeTone.success),
      ),
      _gap,
      HmMoneyRow(
        title: text.devSampleHome,
        detail: text.navEarnings,
        amount: '+TZS 360,000',
        status: HmBadge(label: text.devSamplePaid, tone: HmBadgeTone.success),
        onTap: () {},
      ),
    ];

List<Widget> timelineSamples(AppText text) => [
      for (final (index, state) in HmStepState.values.indexed)
        HmTimelineStep(
          title: text.devSampleEnquiry,
          state: state,
          date: '12 Sep',
          description: text.devSampleNote,
          isLast: index == HmStepState.values.length - 1,
        ),
    ];

List<Widget> navigationSamples(AppText text) => [
      HmTopBar(title: text.devWidgetsTitle, onBack: () {}, backTooltip: text.back),
      _gap,
      for (final tabs in [customerTabs(text, savedCount: 2, activityCount: 1), brokerTabs(text, enquiryCount: 3), landlordTabs(text)]) ...[
        HmBottomNav(tabs: tabs, currentIndex: 0, onSelected: (_) {}),
        _gap,
      ],
    ];

List<Widget> onboardingSamples(AppText text) => [
      SizedBox(
        height: 360,
        child: HmSlide(icon: Icons.search_rounded, title: text.onboardingFindTitle, body: text.onboardingFindBody),
      ),
      const HmPageDots(count: 3, index: 0),
    ];

/// Forms hold a little state so each control can be tried, not just seen.
class FormSamples extends StatefulWidget {
  const FormSamples({super.key});

  @override
  State<FormSamples> createState() => _FormSamplesState();
}

class _FormSamplesState extends State<FormSamples> {
  String _method = 'mobile_money';
  int _count = 2;
  bool _chip = true;
  String _role = 'broker';

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HmTextField(label: text.devSampleFieldLabel, hint: text.devSampleFieldHint),
        _gap,
        HmTextField(label: 'TIN', optionalLabel: text.optional, placeholder: '123-456-789'),
        _gap,
        HmTextField(label: text.devSampleFieldLabel, errorText: text.devSampleFieldError),
        _gap,
        const HmTextField(label: 'TZS', prefixText: 'TZS', trailingIcon: Icons.expand_more_rounded, leadingIcon: Icons.payments_rounded),
        _gap,
        HmTextField(label: text.devSampleNote, maxLines: 4),
        _gap,
        for (final (current, total) in [(1, 3), (3, 3), (4, 6)]) ...[
          HmStepProgress(current: current, total: total, label: text.stepOf(current, total).toUpperCase()),
          _gap,
        ],
        HmSegmented<String>(
          label: text.navEarnings,
          options: const [('mobile_money', 'M-Pesa'), ('bank', 'Bank')],
          value: _method,
          onChanged: (value) => setState(() => _method = value),
        ),
        _gap,
        HmSegmented<int>(
          options: const [(1, '1'), (2, '2'), (3, '3')],
          value: _count,
          hint: text.devSampleFieldHint,
          onChanged: (value) => setState(() => _count = value),
        ),
        _gap,
        Wrap(spacing: HmSpace.md, children: [
          HmChoicePill(label: text.devSamplePending, selected: _chip, showCheck: true, count: 3, dense: true, onTap: () => setState(() => _chip = !_chip)),
          HmChoicePill(label: text.devSampleLive, selected: !_chip, dense: true, onTap: () => setState(() => _chip = !_chip)),
        ]),
        _gap,
        HmRadioCard(
          icon: Icons.real_estate_agent_rounded,
          title: text.navListings,
          subtitle: text.devSampleNote,
          selected: _role == 'broker',
          onTap: () => setState(() => _role = 'broker'),
        ),
        _gap,
        HmRadioCard(
          icon: Icons.key_rounded,
          title: text.navHomes,
          subtitle: text.devSampleNote,
          selected: _role == 'landlord',
          badge: HmBadge(label: text.devSampleLive, tone: HmBadgeTone.success),
          onTap: () => setState(() => _role = 'landlord'),
        ),
      ],
    );
  }
}

/// A titled group in the catalogue.
class CatalogueSection extends StatelessWidget {
  const CatalogueSection({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: HmSpace.section),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: HmText.title.copyWith(fontSize: 19)),
            const SizedBox(height: HmSpace.xl),
            ...children,
          ],
        ),
      );
}
