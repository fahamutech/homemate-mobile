import 'package:intl/intl.dart';

import '../../../../core/i18n/app_text.dart';
import '../../../../design/widgets/hm_badge.dart';
import '../../../../design/widgets/hm_money.dart';
import '../../data/partner_enquiry.dart';

/// Words for an enquiry, shared by the list and the enquiry screen.

String contactChannel(AppText text, String? preference) => switch (preference) {
      'whatsapp' => text.enquiriesChannelWhatsapp,
      'call' || 'phone' => text.enquiriesChannelCall,
      'sms' => text.enquiriesChannelSms,
      _ => '',
    };

/// "10:14" today, "28 Sep" before.
String whenLabel(DateTime? at, {DateTime? now}) {
  if (at == null) return '';
  final local = at.toLocal();
  final today = now ?? DateTime.now();
  final sameDay = local.year == today.year && local.month == today.month && local.day == today.day;
  return sameDay ? DateFormat('HH:mm').format(local) : DateFormat('d MMM').format(local);
}

/// The short facts under an enquiry: move-in, people, budget.
List<String> enquiryFacts(AppText text, PartnerEnquiry enquiry) => [
      if (enquiry.moveInDate != null) text.enquiriesMoveIn(DateFormat('d MMM').format(enquiry.moveInDate!)),
      if (enquiry.occupants != null) text.enquiriesPeople(enquiry.occupants!),
      if (enquiry.budgetAmount != null) text.enquiriesBudget(HmMoney.format(enquiry.budgetAmount)),
    ];

String enquiryStatusLabel(AppText text, String status) => switch (status) {
      'pending' => text.enquiriesTabNew,
      'responded' => text.enquiriesTabReplied,
      'accepted' => text.enquiriesTabAccepted,
      _ => text.enquiriesTabClosed,
    };

HmBadgeTone enquiryStatusTone(String status) => switch (status) {
      'pending' => HmBadgeTone.info,
      'responded' => HmBadgeTone.warning,
      'accepted' => HmBadgeTone.success,
      _ => HmBadgeTone.neutral,
    };

/// "Amina" from "Amina Juma".
String firstName(String name) => name.trim().split(RegExp(r'\s+')).first;

/// The tracker's words for a step; the server's own title when the app has none.
String journeyStepTitle(AppText text, EnquiryStep step, PartnerEnquiry enquiry) => switch (step.key) {
      'enquiry_received' => text.journeyStepEnquiryReceived(firstName(enquiry.customerName)),
      'decision' => enquiry.isOpen ? text.journeyStepDecision : enquiryStatusLabel(text, enquiry.status),
      'awaiting_payment' => text.journeyStepAwaitingPayment(firstName(enquiry.customerName)),
      'payment_verified' => text.journeyStepPaymentVerified,
      'moved_in' => text.journeyStepMovedIn,
      'ended' => text.journeyStepEnded,
      _ => step.title,
    };

/// "50" for 50.0, "12.5" otherwise.
String percentLabel(double value) => value == value.roundToDouble() ? '${value.round()}' : '$value';
