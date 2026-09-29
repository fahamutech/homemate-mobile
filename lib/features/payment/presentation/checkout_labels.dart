import '../../../core/i18n/app_text.dart';

/// The sentence above the pay button. It says *why* the customer may pay,
/// which is the difference between a button someone trusts and one they do
/// not.
String checkoutReason(AppText text, String route) => switch (route) {
      'inquiry_accepted' => text.checkoutReasonAccepted,
      'booking' => text.checkoutReasonBooking,
      'blocked' => text.checkoutReasonBlocked,
      'inquiry_pending' => text.checkoutReasonPending,
      _ => text.checkoutReasonEnquireFirst,
    };

/// "Mobile Money", "Visa, Mastercard": the second line under a method's name.
String paymentKindLabel(AppText text, String kind) => switch (kind) {
      'mobile_money' => text.paymentKindMobileMoney,
      'card' => text.paymentKindCard,
      'bank_transfer' => text.paymentKindBank,
      'cash' => text.paymentKindCash,
      _ => kind.replaceAll('_', ' '),
    };
