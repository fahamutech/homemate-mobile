import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homemate_mobile/design/font_licence.dart';
import 'package:homemate_mobile/design/theme.dart';
import 'package:homemate_mobile/design/tokens.dart';

/// The app ships its own font. On the web, Flutter otherwise downloads Roboto
/// from Google's CDN when the page loads, and where that fails (a slow or
/// filtered network) digits come out spaced apart and symbols as empty boxes.
void main() {
  test('every text token names the bundled family', () {
    for (final style in [HmText.display, HmText.title, HmText.heading, HmText.body, HmText.label, HmText.caption, HmText.price]) {
      expect(style.fontFamily, HmFonts.family);
    }
  });

  test('the theme hands the bundled family to Material text, the app bar and pickers', () {
    final theme = buildHomeMateTheme();
    for (final style in [
      theme.textTheme.bodyMedium,
      theme.textTheme.labelLarge,
      theme.textTheme.headlineSmall,
      theme.primaryTextTheme.bodyMedium,
      theme.appBarTheme.titleTextStyle,
    ]) {
      expect(style?.fontFamily, HmFonts.family);
    }
  });

  test('the font files are in the bundle: regular, medium and bold', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final manifest = jsonDecode(await rootBundle.loadString('FontManifest.json')) as List;
    final family = manifest.cast<Map<String, dynamic>>().firstWhere((f) => f['family'] == HmFonts.family);
    final fonts = (family['fonts'] as List).cast<Map<String, dynamic>>();
    expect({for (final f in fonts) f['weight'] ?? 400}, {400, 500, 700});
    for (final font in fonts) {
      final data = await rootBundle.load(font['asset'] as String);
      expect(data.lengthInBytes, greaterThan(100000), reason: '${font['asset']}');
    }
  });

  testWidgets('a plain Text inside the app is drawn in the bundled family', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: buildHomeMateTheme(), home: const Scaffold(body: Text('TZS 1,200,000'))));
    final paragraph = tester.renderObject<RenderParagraph>(find.text('TZS 1,200,000'));
    expect(paragraph.text.style?.fontFamily, HmFonts.family);
  });

  test('the licence of the font is on the licences page', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFontLicences();
    final entries = await LicenseRegistry.licenses.toList();
    final roboto = entries.where((e) => e.packages.contains('Roboto'));
    expect(roboto, isNotEmpty);
    expect(roboto.first.paragraphs.map((p) => p.text).join(' '), contains('Apache License'));
  });
}
