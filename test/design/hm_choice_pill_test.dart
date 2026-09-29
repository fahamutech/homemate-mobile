import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homemate_mobile/design/widgets/hm_choice.dart';

import 'widget_harness.dart';

/// HM/Form/Chip is the existing pill, extended with a check mark and a count.
void main() {
  testWidgets('a selected chip can show a check and a count', (tester) async {
    await tester.pumpWidget(themed(Row(children: [
      HmChoicePill(label: 'Pending', selected: true, showCheck: true, count: 3, dense: true, onTap: () {}),
      HmChoicePill(label: 'Live', selected: false, dense: true, onTap: () {}),
    ])));
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('no check or count unless asked for', (tester) async {
    await tester.pumpWidget(themed(HmChoicePill(label: 'All', selected: true, onTap: () {})));
    expect(find.byIcon(Icons.check_rounded), findsNothing);
  });

  testWidgets('tapping selects', (tester) async {
    var tapped = false;
    await tester.pumpWidget(themed(HmChoicePill(label: 'All', selected: false, onTap: () => tapped = true)));
    await tester.tap(find.text('All'));
    expect(tapped, isTrue);
  });
}
