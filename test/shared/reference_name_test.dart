import 'package:flutter_test/flutter_test.dart';
import 'package:homemate_mobile/core/i18n/app_locale.dart';
import 'package:homemate_mobile/core/i18n/app_text.dart';
import 'package:homemate_mobile/features/shared/reference_name.dart';

/// Property types and amenities come from the server's reference data, named
/// in English. The app names the ones it knows in the reader's language.
void main() {
  const en = AppText(AppLocale.english);
  const sw = AppText(AppLocale.swahili);

  test('a known code reads in Kiswahili, and as the server named it in English', () {
    expect(referenceName(sw, code: 'apartment', name: 'Apartment'), 'Fleti');
    expect(referenceName(sw, code: 'swimming_pool', name: 'Swimming Pool'), 'Bwawa la Kuogelea');
    expect(referenceName(en, code: 'apartment', name: 'Apartment'), 'Apartment');
  });

  test('without a code, the seeded English name is recognised', () {
    // A property summary carries only `property_type_name`.
    expect(referenceName(sw, name: 'Office Space'), 'Ofisi');
    expect(referenceName(sw, name: '24/7 Security'), 'Ulinzi saa 24');
  });

  test('an item added later on the server keeps its own name', () {
    expect(referenceName(sw, code: 'rooftop', name: 'Rooftop terrace'), 'Rooftop terrace');
    expect(referenceName(sw, name: 'Rooftop terrace'), 'Rooftop terrace');
  });

  test('every seeded type and amenity has Kiswahili', () {
    const seeds = {
      'apartment': 'Apartment', 'house': 'House', 'villa': 'Villa', 'room': 'Single Room', 'studio': 'Studio',
      'office': 'Office Space', 'shop': 'Shop / Retail', 'warehouse': 'Warehouse', 'land': 'Land / Plot',
      'parking': 'Parking', 'security': '24/7 Security', 'water_tank': 'Water Tank', 'generator': 'Backup Generator',
      'furnished': 'Furnished', 'air_conditioning': 'Air Conditioning', 'balcony': 'Balcony', 'garden': 'Garden',
      'swimming_pool': 'Swimming Pool', 'elevator': 'Elevator',
    };
    for (final MapEntry(key: code, value: name) in seeds.entries) {
      expect(referenceName(en, code: code, name: name), name, reason: code);
      expect(sw.reference(code), isNotNull, reason: '$code has no Kiswahili');
    }
  });
}
