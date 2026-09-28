import '../../design/widgets/hm_money.dart';
import 'models.dart';

/// The shapes behind the second half of the journey: reserving a property
/// while you pay for it, paying, and the tenancy you end up with.
///
/// Kept apart from [models.dart] for the same reason the services are: these
/// are all about *time and exclusivity* — a countdown, a step you are on, a
/// lease that ends — and none of them is a listing.

DateTime? _date(Object? value) => value == null ? null : DateTime.tryParse('$value');

int _int(Object? value) => switch (value) {
      null => 0,
      num n => n.toInt(),
      String s => int.tryParse(s) ?? 0,
      _ => 0,
    };

int? _intOrNull(Object? value) => value == null ? null : _int(value);

/// A ten-minute claim on a property while its payment is being made.
///
/// [secondsRemaining] is the *server's* arithmetic, captured with [readAt] so
/// the countdown can tick locally without ever trusting the phone's clock to
/// agree with the backend about what time it is.
class PropertyHold {
  PropertyHold({
    required this.id,
    required this.reference,
    required this.propertyId,
    required this.secondsRemaining,
    required this.isLive,
    this.propertyTitle,
    this.bookingId,
    this.paymentId,
    DateTime? readAt,
  }) : readAt = readAt ?? DateTime.now();

  final String id;
  final String reference;
  final String propertyId;
  final int secondsRemaining;
  final bool isLive;
  final String? propertyTitle;
  final String? bookingId;
  final String? paymentId;

  /// When this snapshot was taken, locally. Only ever used as an *elapsed*
  /// measure, never compared against a server timestamp.
  final DateTime readAt;

  /// What the countdown should read now, given how long the screen has been
  /// open since the server answered.
  Duration get remaining {
    final elapsed = DateTime.now().difference(readAt).inSeconds;
    final left = secondsRemaining - elapsed;
    return Duration(seconds: left < 0 ? 0 : left);
  }

  bool get hasExpired => !isLive || remaining == Duration.zero;

  /// "9:58" — a countdown reads as minutes and seconds or it is not a
  /// countdown.
  String get countdownLabel {
    final left = remaining;
    final minutes = left.inMinutes;
    final seconds = left.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  factory PropertyHold.fromJson(Map<String, dynamic> json) => PropertyHold(
        id: json['id'] as String? ?? '',
        reference: json['reference'] as String? ?? '',
        propertyId: json['property_id'] as String? ?? '',
        secondsRemaining: _int(json['seconds_remaining']),
        isLive: json['is_live'] as bool? ?? false,
        propertyTitle: json['property_title'] as String?,
        bookingId: json['booking_id'] as String?,
        paymentId: json['payment_id'] as String?,
      );
}

/// "May this customer pay for this property, and why?" — asked before every
/// Pay button.
///
/// There is one road to paying: the landlord accepts the customer's enquiry.
/// The server decides all of it, and the app must not invent its own opinion
/// about who is allowed.
class CheckoutEligibility {
  const CheckoutEligibility({
    required this.propertyId,
    this.available = false,
    this.canPay = false,
    this.route = 'no_inquiry',
    this.inquiryId,
    this.inquiryStatus,
    this.bookingId,
    this.holdId,
    this.heldByMe = false,
    this.heldByOther = false,
    this.holdSecondsRemaining,
  });

  final String propertyId;
  final bool available;
  final bool canPay;

  /// `no_inquiry` | `inquiry_pending` | `inquiry_accepted` | `booking` |
  /// `blocked`.
  final String route;
  final String? inquiryId;
  final String? inquiryStatus;
  final String? bookingId;
  final String? holdId;
  final bool heldByMe;
  final bool heldByOther;
  final int? holdSecondsRemaining;

  /// Someone else is mid-payment, so starting now would only end in a refund.
  bool get isBlockedByHold => heldByOther;

  /// A checkout already underway, which the app should resume rather than
  /// restart.
  bool get hasStarted => bookingId != null;

  /// The sentence above the button. It says *why* the customer may pay, which
  /// is the difference between a button someone trusts and one they do not.
  String get reasonLabel => switch (route) {
        'inquiry_accepted' =>
          'Your enquiry was accepted. Pay to secure this home — it is confirmed once we verify your payment.',
        'booking' => 'You have started paying for this home. Finish paying to secure it.',
        'blocked' => 'The landlord declined this application.',
        'inquiry_pending' =>
          'Your enquiry is with the landlord. You can pay once they accept it.',
        _ => 'Send an enquiry first. You can pay once the landlord accepts it.',
      };

  factory CheckoutEligibility.fromJson(Map<String, dynamic> json) => CheckoutEligibility(
        propertyId: json['propertyId'] as String? ?? '',
        available: json['available'] as bool? ?? false,
        canPay: json['canPay'] as bool? ?? false,
        route: json['route'] as String? ?? 'no_inquiry',
        inquiryId: json['inquiryId'] as String?,
        inquiryStatus: json['inquiryStatus'] as String?,
        bookingId: json['bookingId'] as String?,
        holdId: json['holdId'] as String?,
        heldByMe: json['heldByMe'] as bool? ?? false,
        heldByOther: json['heldByOther'] as bool? ?? false,
        holdSecondsRemaining: _intOrNull(json['holdSecondsRemaining']),
      );
}

/// One line of the cost breakdown on CUS-011.
class CostLine {
  const CostLine({
    required this.key,
    required this.label,
    required this.amount,
    this.waived = false,
    this.highlight = false,
  });

  final String key;
  final String label;
  final double amount;
  final bool waived;

  /// The HomeMate fee is drawn out from the other lines, so the customer sees
  /// exactly what the platform is charging them and what it saves.
  final bool highlight;

  /// "TZS 0 (Waived)" rather than a missing row — a charge someone chose not
  /// to make is information, and its absence is not.
  String amountLabel(String currency) =>
      waived && amount == 0 ? '${HmMoney.format(0, currency: currency)} (Waived)' : HmMoney.format(amount, currency: currency);

  factory CostLine.fromJson(Map<String, dynamic> json) => CostLine(
        key: json['key'] as String? ?? '',
        label: json['label'] as String? ?? '',
        amount: HmMoney.parse(json['amount']),
        waived: json['waived'] as bool? ?? false,
        highlight: json['highlight'] as bool? ?? false,
      );
}

/// CUS-011. What is about to be paid and what each part of it is for.
class CheckoutSummary {
  const CheckoutSummary({
    required this.booking,
    required this.breakdown,
    required this.totalDue,
    required this.amountPaid,
    required this.amountOutstanding,
    this.currency = 'TZS',
    this.payments = const [],
    this.serviceFee,
  });

  final Booking booking;
  final List<CostLine> breakdown;
  final double totalDue;
  final double amountPaid;
  final double amountOutstanding;
  final String currency;
  final List<CustomerPayment> payments;

  /// The fee in this payment and what it saves, or null for a reservation
  /// made before the fee existed.
  final ServiceFee? serviceFee;

  String get totalLabel => HmMoney.format(totalDue, currency: currency);

  /// The payment the customer is being asked to settle, if any is still open.
  CustomerPayment? get payable {
    for (final payment in payments) {
      if (!payment.isPaid && payment.status != 'failed') return payment;
    }
    return payments.isEmpty ? null : payments.first;
  }

  factory CheckoutSummary.fromJson(Map<String, dynamic> json) => CheckoutSummary(
        booking: Booking.fromJson(json['booking'] as Map<String, dynamic>? ?? const {}),
        breakdown: (json['breakdown'] as List? ?? const [])
            .map((line) => CostLine.fromJson(line as Map<String, dynamic>))
            .toList(),
        totalDue: HmMoney.parse(json['totalDue']),
        amountPaid: HmMoney.parse(json['amountPaid']),
        amountOutstanding: HmMoney.parse(json['amountOutstanding']),
        currency: json['currency'] as String? ?? 'TZS',
        payments: (json['payments'] as List? ?? const [])
            .map((p) => CustomerPayment.fromJson(p as Map<String, dynamic>))
            .toList(),
        serviceFee: ServiceFee.fromJsonOrNull(json['serviceFee']),
      );
}

/// What a fresh checkout produced: a reservation, something to pay, and the
/// ten minutes in which to do it.
class CheckoutSession {
  const CheckoutSession({
    required this.hold,
    required this.summary,
    this.bookingId,
    this.paymentId,
  });

  final PropertyHold hold;
  final CheckoutSummary summary;
  final String? bookingId;
  final String? paymentId;

  factory CheckoutSession.fromJson(Map<String, dynamic> json) => CheckoutSession(
        hold: PropertyHold.fromJson(json['hold'] as Map<String, dynamic>? ?? const {}),
        summary: CheckoutSummary.fromJson(json['summary'] as Map<String, dynamic>? ?? const {}),
        bookingId: json['bookingId'] as String?,
        paymentId: json['paymentId'] as String?,
      );
}

/// One way to pay, as offered by CUS-014's picker.
class PaymentMethodOption {
  const PaymentMethodOption({
    required this.id,
    required this.code,
    required this.name,
    required this.kind,
    this.provider,
    this.instructions,
  });

  final String id;
  final String code;
  final String name;

  /// `mobile_money` | `card` | `bank_transfer` | `cash` — what the row's icon
  /// and its subtitle are drawn from.
  final String kind;
  final String? provider;
  final String? instructions;

  /// "Mobile Money", "Visa, Mastercard" — the second line under the name.
  String get kindLabel => switch (kind) {
        'mobile_money' => 'Mobile Money',
        'card' => 'Visa, Mastercard',
        'bank_transfer' => 'Direct Bank Deposit',
        'cash' => 'Cash',
        _ => kind.replaceAll('_', ' '),
      };

  /// Only mobile money asks for a number to push the prompt to.
  bool get needsPhoneNumber => kind == 'mobile_money';

  factory PaymentMethodOption.fromJson(Map<String, dynamic> json) => PaymentMethodOption(
        id: json['id'] as String? ?? '',
        code: json['code'] as String? ?? '',
        name: json['name'] as String? ?? '',
        kind: json['kind'] as String? ?? 'other',
        provider: json['provider'] as String?,
        instructions: json['instructions'] as String?,
      );
}

/// What came back from pressing pay: the payment as it now stands, and the
/// hold that protects it.
class PaymentAttempt {
  const PaymentAttempt({required this.payment, this.hold});

  final CustomerPayment payment;
  final PropertyHold? hold;

  factory PaymentAttempt.fromJson(Map<String, dynamic> json) => PaymentAttempt(
        payment: CustomerPayment.fromJson(json['payment'] as Map<String, dynamic>? ?? const {}),
        hold: json['hold'] == null
            ? null
            : PropertyHold.fromJson(json['hold'] as Map<String, dynamic>),
      );
}

/// One step on the status timeline — CUS-007d/e and CUS-013b.
class JourneyEvent {
  const JourneyEvent({
    required this.key,
    required this.title,
    required this.state,
    this.at,
    this.detail,
  });

  final String key;
  final String title;

  /// `done` | `current` | `upcoming` | `blocked`. The dot is drawn from this,
  /// so a screen never has to work out which step it is on.
  final String state;
  final DateTime? at;
  final String? detail;

  bool get isDone => state == 'done';
  bool get isCurrent => state == 'current';
  bool get isBlocked => state == 'blocked';
  bool get isUpcoming => state == 'upcoming';

  factory JourneyEvent.fromJson(Map<String, dynamic> json) => JourneyEvent(
        key: json['key'] as String? ?? '',
        title: json['title'] as String? ?? '',
        state: json['state'] as String? ?? 'upcoming',
        at: _date(json['at']),
        detail: json['detail'] as String?,
      );
}

/// A tenancy — CUS-012a/b. What is paid, when it is next due, and how much
/// lease is left.
class Rental {
  const Rental({
    required this.id,
    required this.reference,
    required this.status,
    required this.monthlyRent,
    this.currency = 'TZS',
    this.propertyId,
    this.propertyTitle,
    this.propertyAddress,
    this.coverMediaId,
    this.depositAmount = 0,
    this.leaseMonths,
    this.leaseStartDate,
    this.leaseEndDate,
    this.moveInDate,
    this.nextPaymentDate,
    this.daysRemaining,
    this.monthsRemaining,
    this.exitWindowOpensOn,
    this.noticePeriodDays,
    this.landlordName,
    this.landlordPhone,
    this.paymentFrequency,
    this.amountOutstanding = 0,
    this.agreementId,
    this.agreementReference,
    this.agreementVersion,
    this.leaseType,
    this.agreementDocumentUrl,
    this.agreementAcceptedAt,
  });

  final String id;
  final String reference;
  final String status;
  final double monthlyRent;
  final String currency;
  final String? propertyId;
  final String? propertyTitle;
  final String? propertyAddress;
  final String? coverMediaId;
  final double depositAmount;
  final int? leaseMonths;
  final DateTime? leaseStartDate;
  final DateTime? leaseEndDate;
  final DateTime? moveInDate;
  final DateTime? nextPaymentDate;
  final int? daysRemaining;
  final int? monthsRemaining;
  final DateTime? exitWindowOpensOn;
  final int? noticePeriodDays;
  final String? landlordName;
  final String? landlordPhone;
  final String? paymentFrequency;
  final double amountOutstanding;
  final String? agreementId;
  final String? agreementReference;
  final String? agreementVersion;
  final String? leaseType;
  final String? agreementDocumentUrl;
  final DateTime? agreementAcceptedAt;

  bool get hasAgreement => agreementId != null;

  String get rentLabel => HmMoney.perMonthShort(monthlyRent, currency: currency);

  /// The chip on the right of the row: months left while there is time, then
  /// days once it is close enough to count them.
  ///
  /// The switch to days happens at three months because "2 months" and
  /// "45 days" are the same fact, and only one of them makes a tenant act.
  String get remainingLabel {
    final days = daysRemaining;
    final months = monthsRemaining;
    if (days == null && months == null) return 'Active Lease';
    if (days != null && days <= 90) return days == 1 ? '1 day' : '$days days';
    if (months != null) return months == 1 ? '1 month' : '$months months';
    return 'Active Lease';
  }

  /// Whether the lease is close enough to its end to warrant a warning colour.
  bool get isEndingSoon => (daysRemaining ?? 999) <= 60;

  factory Rental.fromJson(Map<String, dynamic> json) => Rental(
        id: json['id'] as String? ?? '',
        reference: json['reference'] as String? ?? '',
        status: json['status'] as String? ?? 'confirmed',
        monthlyRent: HmMoney.parse(json['monthly_rent']),
        currency: json['currency'] as String? ?? 'TZS',
        propertyId: json['property_id'] as String?,
        propertyTitle: json['property_title'] as String?,
        propertyAddress: json['property_address'] as String?,
        coverMediaId: json['cover_media_id'] as String?,
        depositAmount: HmMoney.parse(json['deposit_amount']),
        leaseMonths: _intOrNull(json['lease_months']),
        leaseStartDate: _date(json['lease_start_date']),
        leaseEndDate: _date(json['lease_end_date']),
        moveInDate: _date(json['move_in_date']),
        nextPaymentDate: _date(json['next_payment_date']),
        daysRemaining: _intOrNull(json['days_remaining']),
        monthsRemaining: _intOrNull(json['months_remaining']),
        exitWindowOpensOn: _date(json['exit_window_opens_on']),
        noticePeriodDays: _intOrNull(json['notice_period_days']),
        landlordName: json['landlord_name'] as String?,
        landlordPhone: json['landlord_phone'] as String?,
        paymentFrequency: json['payment_frequency'] as String?,
        amountOutstanding: HmMoney.parse(json['amount_outstanding']),
        agreementId: json['agreement_id'] as String?,
        agreementReference: json['agreement_reference'] as String?,
        agreementVersion: json['agreement_version'] as String?,
        leaseType: json['lease_type'] as String?,
        agreementDocumentUrl: json['agreement_document_url'] as String?,
        agreementAcceptedAt: _date(json['agreement_accepted_at']),
      );
}

/// CUS-012b in full: the tenancy, what has been paid on it, what the place
/// comes with, and how it got here.
class RentalDetail {
  const RentalDetail({
    required this.rental,
    this.payments = const [],
    this.amenities = const [],
    this.timeline = const [],
  });

  final Rental rental;
  final List<CustomerPayment> payments;
  final List<NamedItem> amenities;
  final List<JourneyEvent> timeline;

  factory RentalDetail.fromJson(Map<String, dynamic> json) => RentalDetail(
        rental: Rental.fromJson(json['rental'] as Map<String, dynamic>? ?? const {}),
        payments: (json['payments'] as List? ?? const [])
            .map((p) => CustomerPayment.fromJson(p as Map<String, dynamic>))
            .toList(),
        amenities: (json['amenities'] as List? ?? const [])
            .map((a) => NamedItem.fromJson(a as Map<String, dynamic>))
            .toList(),
        timeline: (json['timeline'] as List? ?? const [])
            .map((e) => JourneyEvent.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// CUS-012c. The lease agreement behind a tenancy.
class LeaseAgreement {
  const LeaseAgreement({
    required this.bookingReference,
    this.id,
    this.reference,
    this.version,
    this.leaseType,
    this.documentUrl,
    this.noticePeriodDays,
    this.terms,
    this.houseRules,
    this.acceptedAt,
    this.leaseStartDate,
    this.leaseEndDate,
    this.leaseMonths,
    this.monthlyRent = 0,
    this.depositAmount = 0,
    this.currency = 'TZS',
    this.propertyTitle,
    this.propertyAddress,
    this.landlordName,
    this.landlordPhone,
    this.tenantName,
  });

  final String bookingReference;
  final String? id;
  final String? reference;
  final String? version;
  final String? leaseType;
  final String? documentUrl;
  final int? noticePeriodDays;
  final String? terms;
  final String? houseRules;
  final DateTime? acceptedAt;
  final DateTime? leaseStartDate;
  final DateTime? leaseEndDate;
  final int? leaseMonths;
  final double monthlyRent;
  final double depositAmount;
  final String currency;
  final String? propertyTitle;
  final String? propertyAddress;
  final String? landlordName;
  final String? landlordPhone;
  final String? tenantName;

  /// Whether a document has actually been drawn up, as opposed to the terms
  /// simply being known. The screen says so plainly rather than offering a
  /// download that cannot work.
  bool get exists => id != null;
  bool get hasDocument => (documentUrl ?? '').isNotEmpty;

  String get leaseTypeLabel => switch (leaseType) {
        'fixed_term' => 'Fixed Term',
        'periodic' => 'Periodic',
        'month_to_month' => 'Month to Month',
        _ => 'Fixed Term',
      };

  factory LeaseAgreement.fromJson(Map<String, dynamic> json) => LeaseAgreement(
        bookingReference: json['booking_reference'] as String? ?? '',
        id: json['id'] as String?,
        reference: json['reference'] as String?,
        version: json['version'] as String?,
        leaseType: json['lease_type'] as String?,
        documentUrl: json['document_url'] as String?,
        noticePeriodDays: _intOrNull(json['notice_period_days']),
        terms: json['terms'] as String?,
        houseRules: json['house_rules'] as String?,
        acceptedAt: _date(json['accepted_at']),
        leaseStartDate: _date(json['lease_start_date']),
        leaseEndDate: _date(json['lease_end_date']),
        leaseMonths: _intOrNull(json['lease_months']),
        monthlyRent: HmMoney.parse(json['monthly_rent']),
        depositAmount: HmMoney.parse(json['deposit_amount']),
        currency: json['currency'] as String? ?? 'TZS',
        propertyTitle: json['property_title'] as String?,
        propertyAddress: json['property_address'] as String?,
        landlordName: json['landlord_name'] as String?,
        landlordPhone: json['landlord_phone'] as String?,
        tenantName: json['customer_name'] as String?,
      );
}

/// An enquiry as the Favourites screen's row renders it — the status it shows
/// is the server's `display_status`, so "accepted" reads as "Awaiting Payment"
/// without the app inventing that mapping for itself.
class InquirySummary {
  const InquirySummary({
    required this.id,
    required this.reference,
    required this.status,
    required this.displayStatus,
    required this.createdAt,
    this.propertyId,
    this.propertyTitle,
    this.coverMediaId,
    this.respondedAt,
    this.lastNudgedAt,
  });

  final String id;
  final String reference;
  final String status;
  final String displayStatus;
  final DateTime createdAt;
  final String? propertyId;
  final String? propertyTitle;
  final String? coverMediaId;
  final DateTime? respondedAt;
  final DateTime? lastNudgedAt;

  bool get awaitsPayment => displayStatus == 'awaiting_payment';

  factory InquirySummary.fromJson(Map<String, dynamic> json) => InquirySummary(
        id: json['id'] as String? ?? '',
        reference: json['reference'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
        displayStatus: json['display_status'] as String? ?? json['status'] as String? ?? 'pending',
        createdAt: _date(json['created_at']) ?? DateTime.now(),
        propertyId: json['property_id'] as String?,
        propertyTitle: json['property_title'] as String?,
        coverMediaId: json['cover_media_id'] as String?,
        respondedAt: _date(json['responded_at']),
        lastNudgedAt: _date(json['last_nudged_at']),
      );
}

/// CUS-013a, whole. Three sections and their totals, from one call — the
/// screen a returning customer opens should not be three spinners.
class SavedOverview {
  const SavedOverview({
    this.activeRentals = const [],
    this.activeRentalCount = 0,
    this.favorites = const [],
    this.favoriteCount = 0,
    this.recentInquiries = const [],
    this.inquiryCount = 0,
  });

  final List<Rental> activeRentals;
  final int activeRentalCount;
  final List<PropertySummary> favorites;
  final int favoriteCount;
  final List<InquirySummary> recentInquiries;
  final int inquiryCount;

  /// Nothing at all to show — which is a different screen from "no favourites
  /// but two active leases".
  bool get isEmpty =>
      activeRentals.isEmpty &&
      favorites.isEmpty &&
      recentInquiries.isEmpty;

  static List<T> _list<T>(Object? raw, T Function(Map<String, dynamic>) parse) =>
      (raw as List? ?? const []).map((row) => parse(row as Map<String, dynamic>)).toList();

  factory SavedOverview.fromJson(Map<String, dynamic> json) => SavedOverview(
        activeRentals: _list(json['activeRentals'], Rental.fromJson),
        activeRentalCount: _int(json['activeRentalCount']),
        // The saved rows come through with `is_saved` unset because they are
        // saved by definition — a heart that renders hollow on the Favourites
        // screen is a bug people notice immediately.
        favorites: _list(json['favorites'], PropertySummary.fromJson)
            .map((property) => property.copyWith(isSaved: true))
            .toList(),
        favoriteCount: _int(json['favoriteCount']),
        recentInquiries: _list(json['recentInquiries'], InquirySummary.fromJson),
        inquiryCount: _int(json['inquiryCount']),
      );
}
