import 'package:flutter_test/flutter_test.dart';
import 'package:homemate_mobile/core/i18n/app_locale.dart';
import 'package:homemate_mobile/core/i18n/app_text.dart';
import 'package:homemate_mobile/features/payment/presentation/checkout_labels.dart';

/// Why a customer may (or may not yet) pay, and what kind of method each
/// option is, in the reader's words.
void main() {
  const en = AppText(AppLocale.english);
  const sw = AppText(AppLocale.swahili);

  test('each route explains itself, and anything unknown asks for an enquiry first', () {
    expect(checkoutReason(en, 'inquiry_accepted'),
        'Your enquiry was accepted. Pay to secure this home — it is confirmed once we verify your payment.');
    expect(checkoutReason(en, 'booking'), 'You have started paying for this home. Finish paying to secure it.');
    expect(checkoutReason(en, 'blocked'), 'The landlord declined this application.');
    expect(checkoutReason(en, 'inquiry_pending'), 'Your enquiry is with the landlord. You can pay once they accept it.');
    expect(checkoutReason(en, 'no_inquiry'), 'Send an enquiry first. You can pay once the landlord accepts it.');
    expect(checkoutReason(en, 'something_new'), checkoutReason(en, 'no_inquiry'));
  });

  test('the routes read in Kiswahili too', () {
    for (final route in ['inquiry_accepted', 'booking', 'blocked', 'inquiry_pending', 'no_inquiry']) {
      expect(checkoutReason(sw, route), isNot(checkoutReason(en, route)), reason: route);
    }
  });

  test('a method kind is named, and an unknown one is made readable', () {
    expect(paymentKindLabel(en, 'mobile_money'), 'Mobile Money');
    expect(paymentKindLabel(en, 'card'), 'Visa, Mastercard');
    expect(paymentKindLabel(en, 'bank_transfer'), 'Direct Bank Deposit');
    expect(paymentKindLabel(en, 'cash'), 'Cash');
    expect(paymentKindLabel(en, 'crypto_wallet'), 'crypto wallet');
    expect(paymentKindLabel(sw, 'cash'), 'Pesa taslimu');
  });
}
