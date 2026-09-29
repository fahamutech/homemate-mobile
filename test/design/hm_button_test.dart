import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homemate_mobile/design/tokens.dart';
import 'package:homemate_mobile/design/widgets/hm_button.dart';

import 'widget_harness.dart';

void main() {
  group('HmButton colours', () {
    test('every style has its own fill, border and label colour', () {
      final primary = HmButtonColours.of(HmButtonStyle.primary, enabled: true);
      expect(primary.fill, HmColors.brandPrimary);
      expect(primary.label, HmColors.textOnBrand);
      expect(primary.border, isNull);

      final outline = HmButtonColours.of(HmButtonStyle.outline, enabled: true);
      expect(outline.fill, HmColors.bgPrimary);
      expect(outline.border, HmColors.brandPrimary);
      expect(outline.label, HmColors.brandPrimary);

      final neutral = HmButtonColours.of(HmButtonStyle.neutral, enabled: true);
      expect(neutral.border, HmColors.borderDefault);
      expect(neutral.label, HmColors.textPrimary);

      expect(HmButtonColours.of(HmButtonStyle.soft, enabled: true).fill, HmColors.brandSubtle);
      expect(HmButtonColours.of(HmButtonStyle.ghost, enabled: true).fill, Colors.transparent);
      expect(HmButtonColours.of(HmButtonStyle.danger, enabled: true).fill, HmColors.error);

      final dangerOutline = HmButtonColours.of(HmButtonStyle.dangerOutline, enabled: true);
      expect(dangerOutline.border, HmColors.error);
      expect(dangerOutline.label, HmColors.error);
    });

    test('a disabled button reads as disabled whatever its style', () {
      for (final style in HmButtonStyle.values) {
        final colours = HmButtonColours.of(style, enabled: false);
        expect(colours.label, anyOf(HmColors.textDisabled, HmColors.bgPrimary), reason: '$style');
      }
      expect(HmButtonColours.of(HmButtonStyle.primary, enabled: false).fill, HmColors.borderStrong);
    });
  });

  test('sizes are 52, 44 and 40 points tall', () {
    expect(HmButtonSize.large.height, 52);
    expect(HmButtonSize.medium.height, 44);
    expect(HmButtonSize.small.height, 40);
  });

  testWidgets('tapping calls back; a null callback cannot be tapped', (tester) async {
    var taps = 0;
    await tester.pumpWidget(themed(Column(children: [
      HmButton(label: 'Save', onPressed: () => taps++),
      const HmButton(label: 'Locked', onPressed: null),
    ])));

    await tester.tap(find.text('Save'));
    await tester.tap(find.text('Locked'));
    expect(taps, 1);
    expect(tester.getSize(find.byKey(const ValueKey('hm-button-Save'))).height, 52);
  });

  testWidgets('a leading icon sits before the label', (tester) async {
    await tester.pumpWidget(themed(HmButton(
      label: 'Add a home',
      icon: Icons.add_rounded,
      size: HmButtonSize.medium,
      style: HmButtonStyle.outline,
      onPressed: () {},
    )));
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    expect(tester.getTopLeft(find.byIcon(Icons.add_rounded)).dx,
        lessThan(tester.getTopLeft(find.text('Add a home')).dx));
    expect(tester.getSize(find.byKey(const ValueKey('hm-button-Add a home'))).height, 44);
  });

  testWidgets('an icon-only button hides its label but still says it', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(themed(HmButton(
      label: 'Share',
      icon: Icons.share_rounded,
      iconOnly: true,
      onPressed: () {},
    )));
    expect(find.text('Share'), findsNothing);
    expect(find.bySemanticsLabel('Share'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('while busy it shows progress and ignores taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(themed(HmButton(label: 'Send', busy: true, onPressed: () => taps++)));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('hm-button-Send')));
    expect(taps, 0);
  });

  testWidgets('a screen reader meets a button of its own, next to the text around it, and can press it', (tester) async {
    final semantics = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(themed(Column(children: [
      const Text('Neema Mushi'),
      HmButton(label: 'Confirm move-in', onPressed: () => taps++),
      const HmButton(label: 'Locked', onPressed: null),
    ])));

    final button = tester.getSemantics(find.byKey(const ValueKey('hm-button-Confirm move-in')));
    expect(button.label, 'Confirm move-in', reason: 'the button is its own node, not merged into its surroundings');
    expect(tester.getSemantics(find.text('Neema Mushi')).label, 'Neema Mushi');
    expect(button, matchesSemantics(label: 'Confirm move-in', isButton: true, hasEnabledState: true, isEnabled: true, hasTapAction: true));

    tester.semantics.tap(find.semantics.byLabel('Confirm move-in'));
    expect(taps, 1);

    expect(
      tester.getSemantics(find.byKey(const ValueKey('hm-button-Locked'))),
      matchesSemantics(label: 'Locked', isButton: true, hasEnabledState: true, isEnabled: false),
    );
    semantics.dispose();
  });
}
