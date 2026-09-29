import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homemate_mobile/design/theme.dart';

/// A widget on its own, themed as the app themes it, at phone width.
Widget themed(Widget child) => MaterialApp(
      theme: buildHomeMateTheme(),
      home: Scaffold(
        body: Center(
          child: SizedBox(width: 358, child: child),
        ),
      ),
    );

/// The decoration of the first [Container] under [finder] that has one.
BoxDecoration decorationOf(WidgetTester tester, Finder finder) {
  final containers = tester.widgetList<Container>(
    find.descendant(of: finder, matching: find.byType(Container), matchRoot: true),
  );
  for (final container in containers) {
    if (container.decoration is BoxDecoration) return container.decoration! as BoxDecoration;
  }
  throw StateError('No decorated container under $finder');
}
