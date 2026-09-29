import 'package:flutter_test/flutter_test.dart';
import 'package:homemate_mobile/core/contact/contact_launcher.dart';

void main() {
  test('a call dials the number as written, less spaces', () {
    expect(callUri('+255 712 345 678').toString(), 'tel:+255712345678');
  });

  test('WhatsApp opens wa.me with digits only, and an optional message', () {
    expect(whatsAppUri('+255 712 345 678').toString(), 'https://wa.me/255712345678');
    expect(whatsAppUri('+255712345678', message: 'Hi Amina').toString(), 'https://wa.me/255712345678?text=Hi+Amina');
  });
}
