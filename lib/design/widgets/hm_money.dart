import 'package:intl/intl.dart';

import '../../core/i18n/app_text.dart';

/// Money, formatted once.
///
/// Amounts arrive from Postgres as strings ("2400000.00") because a numeric
/// does not survive a double intact. Parsing and formatting them in one place
/// keeps "TZS 2,400,000" identical on every screen — and stops a screen from
/// doing arithmetic on a string.
class HmMoney {
  const HmMoney._();

  static final NumberFormat _whole = NumberFormat('#,##0');

  static double parse(Object? value) => switch (value) {
        null => 0,
        num n => n.toDouble(),
        String s => double.tryParse(s) ?? 0,
        _ => 0,
      };

  static String format(Object? value, {String currency = 'TZS'}) =>
      '$currency ${_whole.format(parse(value))}';

  /// "TZS 800,000/month" where there is room to say it in full; with
  /// [short], "TZS 800,000/mo" on a card, where the full word pushes the price
  /// onto a second line. Kiswahili says "/mwezi" either way.
  static String perMonth(AppText text, Object? value, {String currency = 'TZS', bool short = false}) {
    final amount = format(value, currency: currency);
    return short ? text.listingPerMonth(amount) : text.tenantsPerMonth(amount);
  }
}
