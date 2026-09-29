import 'package:flutter_test/flutter_test.dart';
import 'package:homemate_mobile/core/i18n/app_locale.dart';
import 'package:homemate_mobile/core/i18n/app_text.dart';
import 'package:homemate_mobile/features/rental/presentation/rental_remaining.dart';
import 'package:homemate_mobile/features/shared/journey_models.dart';

/// The chip on a rental: months while there is time, days once it is close.
void main() {
  const en = AppText(AppLocale.english);
  const sw = AppText(AppLocale.swahili);
  Rental rental({int? days, int? months}) =>
      Rental(id: 'r1', reference: 'HM-R-1', status: 'active', monthlyRent: 500000, daysRemaining: days, monthsRemaining: months);

  test('months while the end is more than three months away', () {
    expect(rentalRemaining(en, rental(days: 200, months: 6)), '6 months');
    expect(rentalRemaining(en, rental(days: 120, months: 1)), '1 month');
    expect(rentalRemaining(en, rental(months: 4)), '4 months');
  });

  test('days once it is three months or less, singular for the last day', () {
    expect(rentalRemaining(en, rental(days: 90, months: 3)), '90 days');
    expect(rentalRemaining(en, rental(days: 1, months: 0)), '1 day');
  });

  test('a lease with no end is simply active', () {
    expect(rentalRemaining(en, rental()), 'Active Lease');
    expect(rentalRemaining(en, rental(days: 200)), 'Active Lease');
  });

  test('Kiswahili reads its own words', () {
    expect(rentalRemaining(sw, rental(days: 30, months: 1)), 'Siku 30');
    expect(rentalRemaining(sw, rental(months: 6, days: 180)), 'Miezi 6');
    expect(rentalRemaining(sw, rental()), isNot('Active Lease'));
  });
}
