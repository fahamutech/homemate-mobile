import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homemate_mobile/core/i18n/app_locale.dart';
import 'package:homemate_mobile/core/i18n/app_text.dart';
import 'package:homemate_mobile/design/widgets/hm_attention_row.dart';
import 'package:homemate_mobile/features/partner_shared/presentation/home/needs_you.dart';
import 'package:homemate_mobile/features/partner_shared/presentation/money_format.dart';
import 'package:homemate_mobile/features/roles/data/app_role.dart';

void main() {
  const en = AppText(AppLocale.english);
  const sw = AppText(AppLocale.swahili);

  test('each "Needs you" kind has its tone, icon, words and destination', () {
    final enquiry = needsYouStyle('enquiry');
    expect(enquiry.tone, HmAttentionTone.orange);
    expect(enquiry.icon, Icons.forum_outlined);
    expect(needsYouTitle(en, 'enquiry'), 'New enquiry');
    expect(needsYouTitle(sw, 'enquiry'), 'Ulizo jipya');
    expect(needsYouTarget(AppRole.broker, 'enquiry', 'i1'), '/broker/enquiries/i1');

    expect(needsYouStyle('listing_changes').tone, HmAttentionTone.red);
    expect(needsYouTarget(AppRole.broker, 'listing_changes', 'p1'), '/broker/listings/p1');
    expect(needsYouStyle('payment_checking').tone, HmAttentionTone.blue);
    expect(needsYouStyle('payment_verified').tone, HmAttentionTone.green);
    expect(needsYouTarget(AppRole.broker, 'payment_verified', 'e1'), '/broker/earnings/e1');
    expect(needsYouTarget(AppRole.landlord, 'confirm_listing', 'p9'), '/landlord/confirm/p9');
    expect(needsYouTarget(AppRole.landlord, 'move_in', 't1'), '/landlord/tenants/t1');
  });

  test('an unknown kind still shows, as the server wrote it', () {
    expect(needsYouTitle(en, 'something_new', fallback: 'Something new'), 'Something new');
    expect(needsYouTarget(AppRole.broker, 'something_new', 'x'), isNull);
  });

  test('money on a tile is short; in a sentence it is whole', () {
    expect(compactMoney(1080000), '1.08M');
    expect(compactMoney(360000), '360K');
    expect(compactMoney(950), '950');
    expect(compactMoney(0), '0');
    expect(compactMoney(2500000), '2.5M');
  });
}
