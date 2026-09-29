import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homemate_mobile/core/i18n/app_locale.dart';
import 'package:homemate_mobile/core/i18n/app_text.dart';
import 'package:homemate_mobile/design/status_label.dart';
import 'package:homemate_mobile/design/widgets/hm_status_chip.dart';

import '../support/fakes.dart';

/// The backend speaks in `awaiting_payment`; a person reads words, in their
/// own language.
void main() {
  const en = AppText(AppLocale.english);
  const sw = AppText(AppLocale.swahili);

  // Every code the API sends to the customer or partner apps.
  const known = [
    'pending', 'responded', 'accepted', 'rejected', 'withdrawn', 'closed', 'awaiting_payment', 'booked',
    'confirmed', 'active', 'completed', 'cancelled', 'expired', 'successful', 'failed', 'reversed', 'refunded',
    'paid', 'awaiting_verification', 'awaiting_instructions', 'in_review', 'verified', 'not_started',
    'pending_review', 'approved', 'draft', 'suspended', 'scheduled', 'processing', 'on_hold', 'disputed',
    'monthly', 'quarterly', 'semi_annual', 'annual', 'custom', 'one_time', 'rent', 'deposit', 'advance_rent',
    'service_charge', 'other',
  ];

  test('every known code has its own words in both languages', () {
    for (final code in known) {
      expect(statusLabel(en, code), isNot(contains('_')), reason: code);
      expect(statusLabel(sw, code), isNot(statusLabel(en, code)), reason: '$code has no Kiswahili');
    }
  });

  test('English reads as it always did', () {
    expect(statusLabel(en, 'awaiting_payment'), 'Awaiting payment');
    expect(statusLabel(en, 'monthly'), 'Monthly');
    expect(statusLabel(en, 'advance_rent'), 'Advance rent');
  });

  test('a code the app does not know yet is still made readable, never shown raw', () {
    expect(statusLabel(sw, 'partially_settled'), 'Partially settled');
    expect(statusLabel(en, ''), '');
  });

  testWidgets('the chip speaks the reader\'s language', (tester) async {
    final harness = TestHarness();
    await tester.pumpWidget(harness.wrap(const Center(child: HmStatusChip('awaiting_payment')), locale: AppLocale.swahili));
    await tester.pumpAndSettle();
    expect(find.text(statusLabel(sw, 'awaiting_payment')), findsOneWidget);
    expect(find.text('Awaiting payment'), findsNothing);
  });
}
