import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homemate_mobile/design/tokens.dart';
import 'package:homemate_mobile/design/widgets/hm_attention_row.dart';
import 'package:homemate_mobile/design/widgets/hm_badge.dart';
import 'package:homemate_mobile/design/widgets/hm_document_card.dart';
import 'package:homemate_mobile/design/widgets/hm_listing_card.dart';
import 'package:homemate_mobile/design/widgets/hm_money_row.dart';
import 'package:homemate_mobile/design/widgets/hm_role_header.dart';
import 'package:homemate_mobile/design/widgets/hm_stat_card.dart';

import 'widget_harness.dart';

void main() {
  group('HmAttentionRow', () {
    test('tones are orange, red, blue and green', () {
      expect(HmAttentionTone.orange.fill, HmColors.orangeBg);
      expect(HmAttentionTone.red.icon, HmColors.redText);
      expect(HmAttentionTone.blue.icon, HmColors.blueText);
      expect(HmAttentionTone.green.fill, HmColors.greenBg);
    });

    testWidgets('shows what needs doing and opens it', (tester) async {
      var opened = false;
      await tester.pumpWidget(themed(HmAttentionRow(
        icon: Icons.forum_rounded,
        title: 'New enquiry',
        subtitle: 'Masaki 3BR — Juma',
        tone: HmAttentionTone.orange,
        onTap: () => opened = true,
      )));
      expect(find.text('Masaki 3BR — Juma'), findsOneWidget);
      expect(decorationOf(tester, find.byKey(const ValueKey('attention-icon'))).color, HmColors.orangeBg);
      await tester.tap(find.text('New enquiry'));
      expect(opened, isTrue);
    });
  });

  group('HmRoleHeader', () {
    testWidgets('greets, shows the role chip that opens the switcher, and the bell', (tester) async {
      var switched = 0;
      var bell = 0;
      await tester.pumpWidget(themed(HmRoleHeader(
        greeting: 'Hi, Baraka',
        initials: 'BM',
        roleLabel: 'Broker',
        roleIcon: Icons.real_estate_agent_rounded,
        onSwitchRole: () => switched++,
        onNotifications: () => bell++,
        notificationsTooltip: 'Notifications',
        unreadCount: 2,
      )));
      expect(find.text('BM'), findsOneWidget);
      await tester.tap(find.text('Broker'));
      await tester.tap(find.byTooltip('Notifications'));
      expect((switched, bell), (1, 1));
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('a photo replaces the initials; no chip action means no chevron', (tester) async {
      await tester.pumpWidget(themed(const HmRoleHeader(
        greeting: 'Hi',
        initials: 'BM',
        roleLabel: 'Landlord',
        roleIcon: Icons.key_rounded,
        avatar: Icon(Icons.face_rounded),
      )));
      expect(find.text('BM'), findsNothing);
      expect(find.byIcon(Icons.face_rounded), findsOneWidget);
      expect(find.byIcon(Icons.expand_more_rounded), findsNothing);
      expect(find.byIcon(Icons.notifications_outlined), findsNothing);
    });
  });

  group('HmListingCard', () {
    testWidgets('title, area, price, status and meta; listed-by only when given', (tester) async {
      var opened = false;
      await tester.pumpWidget(themed(Column(children: [
        HmListingCard(
          photo: const ColoredBox(color: HmColors.surfaceInput),
          title: 'Masaki 3BR',
          area: 'Masaki, Dar es Salaam',
          price: 'TZS 800,000/mo',
          status: const HmBadge(label: 'Live', tone: HmBadgeTone.success),
          meta: '3 enquiries',
          onTap: () => opened = true,
        ),
        const HmListingCard(
          title: 'Mbezi 2BR',
          area: 'Mbezi',
          price: 'TZS 500,000/mo',
          listedBy: 'Listed by Neema (broker)',
          listedByIcon: Icons.real_estate_agent_rounded,
        ),
      ])));
      expect(find.text('Live'), findsOneWidget);
      expect(find.text('3 enquiries'), findsOneWidget);
      expect(find.text('Listed by Neema (broker)'), findsOneWidget);
      expect(find.byIcon(Icons.real_estate_agent_rounded), findsOneWidget);
      await tester.tap(find.text('Masaki 3BR'));
      expect(opened, isTrue);
    });
  });

  testWidgets('HmStatCard shows label, number and an optional line', (tester) async {
    await tester.pumpWidget(themed(const Row(children: [
      Expanded(child: HmStatCard(label: 'Live', value: '4')),
      Expanded(child: HmStatCard(label: 'Earned', value: 'TZS 360k', sub: 'This month')),
    ])));
    expect(find.text('4'), findsOneWidget);
    expect(find.text('This month'), findsOneWidget);
  });

  group('HmDocumentCard', () {
    testWidgets('with a status and an action', (tester) async {
      var uploads = 0;
      await tester.pumpWidget(themed(HmDocumentCard(
        icon: Icons.badge_rounded,
        title: 'NIDA card',
        description: 'Front and back',
        status: const HmBadge(label: 'Missing'),
        actionLabel: 'Upload',
        onAction: () => uploads++,
      )));
      await tester.tap(find.text('Upload'));
      expect(uploads, 1);
      expect(find.text('Missing'), findsOneWidget);
    });

    testWidgets('without an action once it is done', (tester) async {
      await tester.pumpWidget(themed(const HmDocumentCard(
        icon: Icons.badge_rounded,
        title: 'NIDA card',
        description: 'Checked',
        status: HmBadge(label: 'Verified', tone: HmBadgeTone.success),
      )));
      expect(find.byType(InkWell), findsNothing);
    });
  });

  testWidgets('HmMoneyRow: what, how much, where it stands', (tester) async {
    var opened = false;
    await tester.pumpWidget(themed(HmMoneyRow(
      title: 'Masaki 3BR',
      detail: 'Tenant fee share · 12 Sep',
      amount: '+TZS 360,000',
      status: const HmBadge(label: 'Paid', tone: HmBadgeTone.success),
      onTap: () => opened = true,
    )));
    expect(find.text('+TZS 360,000'), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);
    await tester.tap(find.text('Masaki 3BR'));
    expect(opened, isTrue);
  });
}
