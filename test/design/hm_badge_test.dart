import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homemate_mobile/design/tokens.dart';
import 'package:homemate_mobile/design/widgets/hm_badge.dart';

import 'widget_harness.dart';

void main() {
  test('each tone has the Figma fill and text colour', () {
    expect(HmBadgeTone.success.fill, HmColors.greenBg);
    expect(HmBadgeTone.success.text, HmColors.greenText);
    expect(HmBadgeTone.warning.fill, HmColors.amberBg);
    expect(HmBadgeTone.error.fill, HmColors.redBg);
    expect(HmBadgeTone.info.fill, HmColors.infoBg);
    expect(HmBadgeTone.neutral.fill, HmColors.surfaceInput);
    expect(HmBadgeTone.primary.text, HmColors.brandPrimaryDark);
  });

  test('a server status picks the same tone everywhere', () {
    expect(badgeToneForStatus('active'), HmBadgeTone.success);
    expect(badgeToneForStatus('approved'), HmBadgeTone.success);
    expect(badgeToneForStatus('pending_review'), HmBadgeTone.warning);
    expect(badgeToneForStatus('action_needed'), HmBadgeTone.warning);
    expect(badgeToneForStatus('changes_requested'), HmBadgeTone.warning);
    expect(badgeToneForStatus('rejected'), HmBadgeTone.error);
    expect(badgeToneForStatus('disputed'), HmBadgeTone.error);
    expect(badgeToneForStatus('in_review'), HmBadgeTone.info);
    expect(badgeToneForStatus('draft'), HmBadgeTone.neutral);
    expect(badgeToneForStatus('anything_else'), HmBadgeTone.neutral);
  });

  testWidgets('shows its label, with an icon only when given one', (tester) async {
    await tester.pumpWidget(themed(const Column(children: [
      HmBadge(label: 'Live', tone: HmBadgeTone.success),
      HmBadge(label: 'Verified', tone: HmBadgeTone.primary, icon: Icons.verified_rounded),
    ])));
    expect(find.text('Live'), findsOneWidget);
    expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
    expect(find.byType(Icon), findsOneWidget);
  });
}
