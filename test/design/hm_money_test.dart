import 'package:flutter_test/flutter_test.dart';
import 'package:homemate_mobile/core/i18n/app_locale.dart';
import 'package:homemate_mobile/core/i18n/app_text.dart';
import 'package:homemate_mobile/design/widgets/hm_money.dart';

/// Money, the same on every screen, with "a month" in the reader's words.
void main() {
  const en = AppText(AppLocale.english);
  const sw = AppText(AppLocale.swahili);

  test('amounts arrive as strings and are formatted with the currency', () {
    expect(HmMoney.format('2400000.00'), 'TZS 2,400,000');
    expect(HmMoney.format(null), 'TZS 0');
    expect(HmMoney.format(1500, currency: 'USD'), 'USD 1,500');
  });

  test('a monthly price says "a month" in full where there is room, briefly on a card', () {
    expect(HmMoney.perMonth(en, '800000'), 'TZS 800,000/month');
    expect(HmMoney.perMonth(en, 800000, short: true), 'TZS 800,000/mo');
    expect(HmMoney.perMonth(en, 800000, currency: 'USD'), 'USD 800,000/month');
  });

  test('in Kiswahili a month is a mwezi, long or short', () {
    expect(HmMoney.perMonth(sw, 800000), 'TZS 800,000/mwezi');
    expect(HmMoney.perMonth(sw, 800000, short: true), 'TZS 800,000/mwezi');
  });
}
