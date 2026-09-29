import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homemate_mobile/design/tokens.dart';
import 'package:homemate_mobile/design/widgets/hm_key_value.dart';
import 'package:homemate_mobile/design/widgets/hm_list_tile.dart';
import 'package:homemate_mobile/design/widgets/hm_note.dart';
import 'package:homemate_mobile/design/widgets/hm_slide.dart';
import 'package:homemate_mobile/design/widgets/hm_timeline_step.dart';
import 'package:homemate_mobile/design/widgets/hm_top_bar.dart';

import 'widget_harness.dart';

void main() {
  group('HmNote', () {
    test('each tone has its own tint, edge and icon colour', () {
      expect(HmNoteTone.neutral.fill, HmColors.surfaceInput);
      expect(HmNoteTone.brand.fill, HmColors.brandSubtle);
      expect(HmNoteTone.brand.border, HmColors.brandBorder);
      expect(HmNoteTone.success.icon, HmColors.success);
      expect(HmNoteTone.warning.border, HmColors.orangeBorder);
      expect(HmNoteTone.info.icon, HmColors.info);
    });

    testWidgets('shows the text with the tone’s default icon, or the given one', (tester) async {
      await tester.pumpWidget(themed(const Column(children: [
        HmNote(text: 'We check every document', tone: HmNoteTone.brand),
        HmNote(text: 'Held', tone: HmNoteTone.warning, icon: Icons.pause_circle_rounded),
      ])));
      expect(find.text('We check every document'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.pause_circle_rounded), findsOneWidget);
    });
  });

  group('HmKeyValue', () {
    Color? valueColour(WidgetTester tester, String value) => tester.widget<Text>(find.text(value)).style?.color;

    testWidgets('default and strong: grey label, dark value', (tester) async {
      await tester.pumpWidget(themed(const Column(children: [
        HmKeyValue(label: 'Rent', value: 'TZS 800,000'),
        HmKeyValue(label: 'Deposit', value: 'TZS 1,600,000', emphasis: HmKeyValueEmphasis.strong),
      ])));
      expect(tester.widget<Text>(find.text('Rent')).style?.color, HmColors.textSecondary);
      expect(valueColour(tester, 'TZS 800,000'), HmColors.textPrimary);
      expect(tester.widget<Text>(find.text('TZS 1,600,000')).style?.fontWeight, FontWeight.w600);
    });

    testWidgets('total darkens the label; brand colours the value', (tester) async {
      await tester.pumpWidget(themed(const Column(children: [
        HmKeyValue(label: 'Total', value: 'TZS 2,800,000', emphasis: HmKeyValueEmphasis.total),
        HmKeyValue(label: 'You get', value: 'TZS 360,000', emphasis: HmKeyValueEmphasis.brand),
      ])));
      expect(tester.widget<Text>(find.text('Total')).style?.color, HmColors.textPrimary);
      expect(valueColour(tester, 'TZS 360,000'), HmColors.brandPrimary);
    });
  });

  group('HmListTile', () {
    testWidgets('plain: icon, title and a chevron; taps through', (tester) async {
      var tapped = false;
      await tester.pumpWidget(themed(HmListTile(icon: Icons.person_rounded, title: 'Profile', onTap: () => tapped = true)));
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
      expect(find.byKey(const ValueKey('list-tile-box')), findsNothing);
      await tester.tap(find.text('Profile'));
      expect(tapped, isTrue);
    });

    testWidgets('boxed with subtitle, badge and value; trailing can be hidden', (tester) async {
      await tester.pumpWidget(themed(const HmListTile(
        icon: Icons.account_balance_rounded,
        title: 'Payout',
        subtitle: 'M-Pesa ••• 678',
        boxed: true,
        badge: Text('Verified'),
        value: 'Change',
        trailingIcon: null,
      )));
      expect(find.byKey(const ValueKey('list-tile-box')), findsOneWidget);
      expect(find.text('M-Pesa ••• 678'), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);
      expect(find.text('Change'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    });
  });

  group('HmTimelineStep', () {
    for (final (state, icon) in [
      (HmStepState.done, Icons.check_rounded),
      (HmStepState.current, Icons.schedule_rounded),
      (HmStepState.blocked, Icons.close_rounded),
    ]) {
      testWidgets('$state shows its mark', (tester) async {
        await tester.pumpWidget(themed(HmTimelineStep(title: 'Step', state: state)));
        expect(find.byIcon(icon), findsOneWidget);
      });
    }

    testWidgets('upcoming has a hollow dot; the last step has no line', (tester) async {
      await tester.pumpWidget(themed(const Column(children: [
        HmTimelineStep(title: 'Paid', state: HmStepState.upcoming, date: '12 Sep', description: 'When the customer pays'),
        HmTimelineStep(title: 'Moved in', state: HmStepState.upcoming, isLast: true),
      ])));
      expect(find.byIcon(Icons.check_rounded), findsNothing);
      expect(find.byKey(const ValueKey('timeline-line')), findsOneWidget);
      expect(find.text('12 Sep'), findsOneWidget);
      expect(find.text('When the customer pays'), findsOneWidget);
    });

    test('state comes from the server’s words', () {
      expect(HmStepState.fromServer('done'), HmStepState.done);
      expect(HmStepState.fromServer('current'), HmStepState.current);
      expect(HmStepState.fromServer('blocked'), HmStepState.blocked);
      expect(HmStepState.fromServer('upcoming'), HmStepState.upcoming);
      expect(HmStepState.fromServer('???'), HmStepState.upcoming);
    });
  });

  group('HmTopBar', () {
    testWidgets('title, back that calls back, and actions', (tester) async {
      var back = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          appBar: HmTopBar(
            title: 'Add a home',
            backTooltip: 'Back',
            onBack: () => back++,
            actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert_rounded))],
          ),
        ),
      ));
      expect(find.text('Add a home'), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      expect(back, 1);
      expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);
      expect(tester.getSize(find.byType(HmTopBar)).height, 57);
    });

    testWidgets('no back button when there is nowhere to go', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(appBar: HmTopBar(title: 'Home'))));
      expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
    });
  });

  group('HmSlide and HmPageDots', () {
    testWidgets('a slide shows its art, title and body', (tester) async {
      await tester.pumpWidget(themed(const HmSlide(icon: Icons.search_rounded, title: 'Find', body: 'Homes near you')));
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.text('Find'), findsOneWidget);
      expect(find.text('Homes near you'), findsOneWidget);
    });

    testWidgets('the current dot is the long one', (tester) async {
      await tester.pumpWidget(themed(const HmPageDots(count: 3, index: 1)));
      await tester.pumpAndSettle();
      final widths = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .map((c) => c.constraints?.maxWidth)
          .toList();
      expect(widths, [8, 22, 8]);
    });
  });
}
