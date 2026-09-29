import 'package:flutter_test/flutter_test.dart';
import 'package:homemate_mobile/core/i18n/app_locale.dart';
import 'package:homemate_mobile/core/i18n/app_text.dart';
import 'package:homemate_mobile/design/widgets/hm_badge.dart';
import 'package:homemate_mobile/features/partner_shared/data/partner_enquiry.dart';
import 'package:homemate_mobile/features/partner_shared/presentation/enquiries/customer_avatar_initials.dart';
import 'package:homemate_mobile/features/partner_shared/presentation/enquiries/decline_sheet.dart';
import 'package:homemate_mobile/features/partner_shared/presentation/enquiries/enquiry_copy.dart';
import 'package:homemate_mobile/features/partner_shared/presentation/money/earning_state.dart';
import 'package:homemate_mobile/features/partner_shared/presentation/payout_labels.dart';

void main() {
  const en = AppText(AppLocale.english);
  const sw = AppText(AppLocale.swahili);

  group('enquiry words', () {
    test('how the customer wants to be reached', () {
      expect(contactChannel(en, 'whatsapp'), 'WhatsApp');
      expect(contactChannel(en, 'call'), contactChannel(en, 'phone'));
      expect(contactChannel(en, 'sms'), isNotEmpty);
      expect(contactChannel(en, null), '');
    });

    test('time today, day before', () {
      final now = DateTime(2026, 9, 29, 15);
      expect(whenLabel(DateTime(2026, 9, 29, 10, 14), now: now), '10:14');
      expect(whenLabel(DateTime(2026, 9, 28, 10, 14), now: now), '28 Sep');
      expect(whenLabel(null), '');
    });

    test('facts only for what the customer said', () {
      expect(enquiryFacts(en, const PartnerEnquiry(id: 'i', status: 'pending')), isEmpty);
      expect(enquiryFacts(en, const PartnerEnquiry(id: 'i', status: 'pending', occupants: 3)), ['3 people']);
    });

    test('every status has a label and a tone', () {
      for (final status in ['pending', 'responded', 'accepted', 'rejected', 'withdrawn', 'closed']) {
        expect(enquiryStatusLabel(en, status), isNotEmpty);
        expect(enquiryStatusLabel(sw, status), isNotEmpty);
      }
      expect(enquiryStatusTone('pending'), HmBadgeTone.info);
      expect(enquiryStatusTone('responded'), HmBadgeTone.warning);
      expect(enquiryStatusTone('accepted'), HmBadgeTone.success);
      expect(enquiryStatusTone('rejected'), HmBadgeTone.neutral);
    });

    test('names and initials', () {
      expect(firstName('  Amina Juma '), 'Amina');
      expect(InitialsAvatar.initials('amina juma mollel'), 'AM');
      expect(InitialsAvatar.initials('Neema'), 'N');
      expect(InitialsAvatar.initials('  '), '#');
    });

    test('the journey speaks of the customer by first name; the decision follows the enquiry', () {
      const open = PartnerEnquiry(id: 'i', status: 'pending', customerName: 'Amina Juma');
      const accepted = PartnerEnquiry(id: 'i', status: 'accepted', customerName: 'Amina Juma');
      EnquiryStep step(String key) => EnquiryStep(key: key, title: 'Server $key', state: 'done');
      expect(journeyStepTitle(en, step('enquiry_received'), open), 'Amina enquired');
      expect(journeyStepTitle(en, step('awaiting_payment'), open), 'Amina pays in the app');
      expect(journeyStepTitle(en, step('decision'), open), 'Your answer');
      expect(journeyStepTitle(en, step('decision'), accepted), 'Accepted');
      expect(journeyStepTitle(en, step('payment_verified'), open), isNot('Server payment_verified'));
      expect(journeyStepTitle(en, step('moved_in'), open), 'Moved in');
      expect(journeyStepTitle(en, step('ended'), open), 'Tenancy ended');
      expect(journeyStepTitle(en, step('something_new'), open), 'Server something_new');
    });

    test('percentages drop a needless .0', () {
      expect(percentLabel(50), '50');
      expect(percentLabel(12.5), '12.5');
    });

    test('four quick decline reasons, in both languages', () {
      expect(quickDeclineReasons(en), hasLength(4));
      expect(quickDeclineReasons(sw).toSet(), hasLength(4));
    });
  });

  group('money words', () {
    test('every payout status has a label and a tone', () {
      for (final status in ['scheduled', 'processing', 'paid', 'on_hold', 'failed', 'cancelled']) {
        expect(payoutStatusLabel(en, status), isNotEmpty);
      }
      expect(payoutStatusTone('processing'), HmBadgeTone.info);
      expect(payoutStatusTone('paid'), HmBadgeTone.success);
      expect(payoutStatusTone('failed'), HmBadgeTone.error);
      expect(payoutStatusTone('cancelled'), HmBadgeTone.neutral);
      expect(earningStateTone('failed'), HmBadgeTone.error);
      for (final state in ['being_checked', 'ready', 'in_payout', 'paid', 'on_hold', 'reversed', 'failed']) {
        expect(earningStateLabel(sw, state), isNotEmpty);
      }
    });

    test('money in and out carries its sign', () {
      expect(signedMoney(810000), '+TZS 810,000');
      expect(signedMoney(-315000), '−TZS 315,000');
    });

    test('an account line from an already-masked number', () {
      expect(maskedAccountLine(method: 'mobile_money', provider: 'mpesa', masked: '•••• 5678'), 'M-Pesa •••• 5678');
      expect(maskedAccountLine(method: 'bank', provider: 'crdb', masked: '•••• 1234', bankName: (_) => 'CRDB Bank'), 'CRDB Bank •••• 1234');
      expect(maskedAccountLine(method: 'bank', provider: 'nmb', masked: '•••• 1'), 'nmb •••• 1');
    });
  });
}
