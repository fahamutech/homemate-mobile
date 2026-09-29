import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Kiswahili-first: every word a person reads comes from the translations
/// (lib/core/i18n). A literal in a Text or in a label, title, hint, tooltip or
/// message is English that a Kiswahili reader would see.
void main() {
  // Names that read the same in both languages.
  const allowed = {'HomeMate', 'HomeMate Africa', 'AFRICA', 'M-Pesa', 'TZS', '© OpenStreetMap', 'you@example.com'};
  final interpolation = RegExp(r'\$\{[^}]*\}?|\$\w+');
  final words = RegExp(r'[A-Za-z]{2,}');
  final literal = RegExp(
    r'''(?:\bText\(\s*|\b(?:label|labelText|title|subtitle|message|hintText|hint|placeholder|tooltip|semanticLabel|semanticsLabel|helperText|errorText|actionLabel|confirmLabel|cancelLabel|emptyTitle|emptyBody|body|detail|value)\s*:\s*)(['"])((?:(?!\1).)*[A-Za-z]{2,}(?:(?!\1).)*)\1''',
  );

  test('no user-facing English is written into the widgets', () {
    final offenders = <String>[];
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>()) {
      final path = file.path.replaceAll(r'\', '/');
      if (!path.endsWith('.dart') || path.contains('/core/i18n/') || path.contains('/dev/')) continue;
      // Its sentences are the English fallback for logs; screens show
      // errorText(), which is translated.
      if (path.endsWith('/core/network/api_exception.dart')) continue;
      // The whole file at once: a `Text(` and its literal are often on
      // different lines.
      final source = file.readAsStringSync();
      for (final m in literal.allMatches(source)) {
        final lineStart = source.lastIndexOf('\n', m.start) + 1;
        if (source.substring(lineStart, m.start).trim().startsWith('//')) continue;
        final text = m.group(2)!;
        if (allowed.contains(text)) continue;
        // Letters that only come from interpolated values are not English.
        if (!words.hasMatch(text.replaceAll(interpolation, ''))) continue;
        final line = '\n'.allMatches(source.substring(0, m.start)).length + 1;
        offenders.add('$path:$line: $text');
      }
    }
    expect(offenders, isEmpty, reason: '${offenders.length} literals:\n${offenders.join('\n')}');
  });

  test('no emoji anywhere in the app: the bundled font has none, so each would draw as a box', () {
    final emoji = RegExp(r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}]', unicode: true);
    final offenders = <String>[];
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (emoji.hasMatch(lines[i])) offenders.add('${file.path}:${i + 1}: ${lines[i].trim()}');
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
