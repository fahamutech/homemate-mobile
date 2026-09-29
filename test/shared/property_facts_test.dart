import 'package:flutter_test/flutter_test.dart';
import 'package:homemate_mobile/core/i18n/app_locale.dart';
import 'package:homemate_mobile/core/i18n/app_text.dart';
import 'package:homemate_mobile/features/shared/models.dart';
import 'package:homemate_mobile/features/shared/property_facts.dart';

/// The one-line "3 Bed · 2 Bath · 95 m²" under a home, in the reader's words.
void main() {
  const en = AppText(AppLocale.english);
  const sw = AppText(AppLocale.swahili);
  const home = PropertySummary(id: 'p1', referenceCode: 'HM-1', title: 'Flat', bedrooms: 3, bathrooms: 2, sizeSqm: 94.6);

  test('bedrooms, bathrooms and the rounded area, in order', () {
    expect(propertyFacts(en, home), ['3 Bed', '2 Bath', '95 m²']);
    expect(propertyFacts(en, home, areaUnit: 'sqm'), ['3 Bed', '2 Bath', '95 sqm']);
  });

  test('a fact the listing does not have is left out, not shown as null', () {
    const bare = PropertySummary(id: 'p2', referenceCode: 'HM-2', title: 'Plot', bathrooms: 1);
    expect(propertyFacts(en, bare), ['1 Bath']);
    expect(propertyFacts(en, const PropertySummary(id: 'p3', referenceCode: 'HM-3', title: 'Land')), isEmpty);
  });

  test('Kiswahili reads its own words', () {
    final facts = propertyFacts(sw, home);
    expect(facts.first, isNot('3 Bed'));
    expect(facts.first, contains('3'));
    expect(facts.last, '95 m²');
  });
}
