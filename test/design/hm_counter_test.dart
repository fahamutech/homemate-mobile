import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homemate_mobile/design/widgets/hm_counter.dart';

import 'widget_harness.dart';

void main() {
  testWidgets('steps up and down within its bounds', (tester) async {
    var value = 1;
    await tester.pumpWidget(themed(StatefulBuilder(
      builder: (context, setState) => HmCounter(
        label: 'Bedrooms',
        value: value,
        min: 0,
        max: 2,
        onChanged: (next) => setState(() => value = next),
      ),
    )));
    expect(find.text('Bedrooms'), findsOneWidget);
    await tester.tap(find.byTooltip('Increase Bedrooms'));
    await tester.pump();
    expect(value, 2);
    await tester.tap(find.byTooltip('Increase Bedrooms'));
    await tester.pump();
    expect(value, 2, reason: 'max');
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byTooltip('Decrease Bedrooms'));
      await tester.pump();
    }
    expect(value, 0, reason: 'min');
    expect(find.text('0'), findsOneWidget);
  });
}
