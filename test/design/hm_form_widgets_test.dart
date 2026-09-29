import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homemate_mobile/design/tokens.dart';
import 'package:homemate_mobile/design/widgets/hm_radio_card.dart';
import 'package:homemate_mobile/design/widgets/hm_segmented.dart';
import 'package:homemate_mobile/design/widgets/hm_step_progress.dart';
import 'package:homemate_mobile/design/widgets/hm_text_field.dart';

import 'widget_harness.dart';

void main() {
  group('HmTextField', () {
    testWidgets('labels the field and marks it optional when it is', (tester) async {
      await tester.pumpWidget(themed(const HmTextField(label: 'TIN', optionalLabel: 'Optional')));
      expect(find.text('TIN'), findsOneWidget);
      expect(find.text('Optional'), findsOneWidget);
    });

    testWidgets('no optional tag on a required field', (tester) async {
      await tester.pumpWidget(themed(const HmTextField(label: 'Full name')));
      expect(find.text('Optional'), findsNothing);
    });

    testWidgets('prefix, leading and trailing icons are shown when asked for', (tester) async {
      await tester.pumpWidget(themed(const HmTextField(
        label: 'Rent',
        prefixText: 'TZS',
        leadingIcon: Icons.search_rounded,
        trailingIcon: Icons.expand_more_rounded,
      )));
      expect(find.text('TZS'), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.byIcon(Icons.expand_more_rounded), findsOneWidget);
    });

    testWidgets('an error replaces the hint and turns the border red', (tester) async {
      await tester.pumpWidget(themed(const HmTextField(
        label: 'NIDA',
        hint: '20 digits',
        errorText: 'That NIDA number is too short',
      )));
      expect(find.text('That NIDA number is too short'), findsOneWidget);
      expect(find.text('20 digits'), findsNothing);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.decoration!.errorText, isNotNull);
    });

    testWidgets('types into the controller; multi-line grows', (tester) async {
      final controller = TextEditingController();
      String? changed;
      await tester.pumpWidget(themed(HmTextField(
        label: 'Address',
        controller: controller,
        maxLines: 4,
        onChanged: (value) => changed = value,
      )));
      await tester.enterText(find.byType(TextField), 'Mikocheni B');
      expect(controller.text, 'Mikocheni B');
      expect(changed, 'Mikocheni B');
      expect(tester.widget<TextField>(find.byType(TextField)).maxLines, 4);
    });
  });

  group('HmStepProgress', () {
    for (final (current, total) in [(1, 3), (3, 3), (4, 6)]) {
      testWidgets('step $current of $total fills $current bars', (tester) async {
        await tester.pumpWidget(themed(HmStepProgress(current: current, total: total, label: 'STEP $current OF $total')));
        expect(find.byKey(const ValueKey('step-done')), findsNWidgets(current));
        expect(find.byKey(const ValueKey('step-todo')), findsNWidgets(total - current));
        expect(find.text('STEP $current OF $total'), findsOneWidget);
      });
    }

    testWidgets('the label is optional', (tester) async {
      await tester.pumpWidget(themed(const HmStepProgress(current: 1, total: 2)));
      expect(find.byType(Text), findsNothing);
    });
  });

  group('HmSegmented', () {
    testWidgets('the chosen option sits on white; tapping another picks it', (tester) async {
      String? picked;
      await tester.pumpWidget(themed(HmSegmented<String>(
        label: 'Payout method',
        options: const [('mobile_money', 'Mobile money'), ('bank', 'Bank')],
        value: 'mobile_money',
        onChanged: (value) => picked = value,
      )));
      expect(find.text('Payout method'), findsOneWidget);
      final selected = decorationOf(tester, find.byKey(const ValueKey('segment-mobile_money')));
      expect(selected.color, HmColors.bgPrimary);
      await tester.tap(find.text('Bank'));
      expect(picked, 'bank');
    });

    testWidgets('shows a hint under the track when given one', (tester) async {
      await tester.pumpWidget(themed(HmSegmented<int>(
        options: const [(1, 'One'), (2, 'Two'), (3, 'Three')],
        value: 3,
        hint: 'Pick one',
        onChanged: (_) {},
      )));
      expect(find.text('Pick one'), findsOneWidget);
    });
  });

  group('HmRadioCard', () {
    testWidgets('selected and unselected differ in fill and mark', (tester) async {
      await tester.pumpWidget(themed(Column(children: [
        HmRadioCard(icon: Icons.real_estate_agent_rounded, title: 'Broker', subtitle: 'List homes', selected: true, onTap: () {}),
        HmRadioCard(icon: Icons.key_rounded, title: 'Landlord', subtitle: 'Rent out', selected: false, onTap: () {}),
      ])));
      expect(find.byIcon(Icons.radio_button_checked_rounded), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked_rounded), findsOneWidget);
      expect(decorationOf(tester, find.byKey(const ValueKey('radio-card-Broker'))).color, HmColors.brandSubtle);
      expect(decorationOf(tester, find.byKey(const ValueKey('radio-card-Landlord'))).color, HmColors.bgPrimary);
    });

    testWidgets('can list what the option gives you, each point ticked', (tester) async {
      await tester.pumpWidget(themed(HmRadioCard(
        icon: Icons.key_rounded,
        title: 'Landlord',
        subtitle: 'You own homes',
        selected: true,
        details: const ['Rent comes to you', 'Every lease in one place'],
        onTap: () {},
      )));
      expect(find.text('Rent comes to you'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsNWidgets(2));
    });

    testWidgets('tapping picks it, and it can carry a badge', (tester) async {
      var tapped = false;
      await tester.pumpWidget(themed(HmRadioCard(
        icon: Icons.key_rounded,
        title: 'Landlord',
        subtitle: 'Rent out',
        selected: false,
        badge: const Text('Active'),
        onTap: () => tapped = true,
      )));
      await tester.tap(find.text('Landlord'));
      expect(tapped, isTrue);
      expect(find.text('Active'), findsOneWidget);
    });
  });
}
