import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homemate_mobile/core/i18n/app_locale.dart';
import 'package:homemate_mobile/design/font_licence.dart';
import 'package:homemate_mobile/features/auth/presentation/onboarding_screen.dart';
import 'package:homemate_mobile/features/inquiry/presentation/inquiry_form_screen.dart';
import 'package:homemate_mobile/features/payment/presentation/checkout_screen.dart';
import 'package:homemate_mobile/features/property/presentation/property_screen.dart';
import 'package:homemate_mobile/design/theme.dart';
import 'package:homemate_mobile/design/tokens.dart';

import '../support/fakes.dart';

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

  // A button's textStyle replaces the inherited style rather than merging
  // with it, so a theme button style without a family asks the web engine for
  // its default "Roboto" from Google's CDN, and where that is unreachable the
  // label is not drawn at all (seen live on the wasm build).
  testWidgets('every button kind labels itself in the bundled family', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildHomeMateTheme(),
      home: Scaffold(
        body: Column(children: [
          ElevatedButton(onPressed: () {}, child: const Text('Elevated')),
          FilledButton(onPressed: () {}, child: const Text('Filled')),
          OutlinedButton(onPressed: () {}, child: const Text('Outlined')),
          TextButton(onPressed: () {}, child: const Text('Text')),
          ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.add), label: const Text('Icon')),
          const Chip(label: Text('Chip')),
          const TextField(decoration: InputDecoration(labelText: 'Field', hintText: 'Hint')),
        ]),
      ),
    ));
    for (final label in ['Elevated', 'Filled', 'Outlined', 'Text', 'Icon', 'Chip', 'Field', 'Hint']) {
      final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
      expect(_family(paragraph), HmFonts.family, reason: label);
    }
  });

  for (final (name, screen) in <(String, Widget)>[
    ('onboarding', const OnboardingScreen()),
    ('a property', const PropertyScreen(propertyId: 'prop-1')),
    ('checkout', const CheckoutScreen(propertyId: 'prop-1')),
    ('an enquiry form', const InquiryFormScreen(propertyId: 'prop-1')),
  ]) {
    testWidgets('no text on $name falls back to a downloaded font', (tester) async {
      final harness = TestHarness();
      await tester.pumpWidget(harness.wrap(screen, locale: AppLocale.swahili));
      await tester.pumpAndSettle();
      final paragraphs = tester.renderObjectList<RenderParagraph>(find.byType(RichText));
      expect(paragraphs, isNotEmpty);
      for (final paragraph in paragraphs.where((p) => !(_family(p) ?? '').startsWith('MaterialIcons'))) {
        expect(_family(paragraph), HmFonts.family, reason: paragraph.text.toPlainText());
      }
    });
  }

  test('the licence of the font is on the licences page', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFontLicences();
    final entries = await LicenseRegistry.licenses.toList();
    final roboto = entries.where((e) => e.packages.contains('Roboto'));
    expect(roboto, isNotEmpty);
    expect(roboto.first.paragraphs.map((p) => p.text).join(' '), contains('Apache License'));
  });
}

/// The family a paragraph is drawn in: its own style, else the first span
/// that names one. (Icons are drawn in their icon font and are not text.)
String? _family(RenderParagraph paragraph) {
  String? found = paragraph.text.style?.fontFamily;
  paragraph.text.visitChildren((span) {
    found ??= span.style?.fontFamily;
    return found == null;
  });
  return found;
}
