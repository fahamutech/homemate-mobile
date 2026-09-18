import 'package:intl/intl.dart';

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

  /// "TZS 800,000/month" — the phrasing the listing cards use.
  static String perMonth(Object? value, {String currency = 'TZS'}) =>
      '${format(value, currency: currency)}/month';
}
