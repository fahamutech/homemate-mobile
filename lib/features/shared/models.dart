import '../../core/i18n/app_text.dart';
import '../../design/widgets/hm_money.dart';

/// The shapes the app reads back from the API.
///
/// These deliberately model what the *screens* need rather than mirroring the
/// database. Postgres hands numerics back as strings and dates as `YYYY-MM-DD`,
/// so the parsing lives here once — a widget should never be the place a
/// string first becomes a number.

DateTime? _date(Object? value) => value == null ? null : DateTime.tryParse('$value');
int _int(Object? value) => switch (value) {
      null => 0,
      num n => n.toInt(),
      String s => int.tryParse(s) ?? 0,
      _ => 0,
    };

/// A listing as it appears in a results list or on a card.
class PropertySummary {
  const PropertySummary({
    required this.id,
    required this.referenceCode,
    required this.title,
    this.price,
    this.currency = 'TZS',
    this.bedrooms,
    this.bathrooms,
    this.sizeSqm,
    this.addressLine,
    this.propertyTypeName,
    this.regionName,
    this.districtName,
    this.wardName,
    this.coverMediaId,
    this.latitude,
    this.longitude,
    this.totalMonthlyCost,
    this.furnishing,
    this.isSaved = false,
    this.distanceMetres,
  });

  final String id;
  final String referenceCode;
  final String title;
  final double? price;
  final String currency;
  final int? bedrooms;
  final int? bathrooms;
  final double? sizeSqm;
  final String? addressLine;
  final String? propertyTypeName;
  final String? regionName;
  final String? districtName;
  final String? wardName;
  final String? coverMediaId;
  final double? latitude;
  final double? longitude;
  final double? totalMonthlyCost;
  final String? furnishing;
  final bool isSaved;
  final double? distanceMetres;

  bool get hasLocation => latitude != null && longitude != null;

  /// "Masaki, Kinondoni" — the most specific place names available, in the
  /// order a person would say them.
  String get locationLabel {
    final parts = [wardName, districtName, regionName].whereType<String>().where((p) => p.isNotEmpty);
    return parts.isEmpty ? (addressLine ?? '') : parts.take(2).join(', ');
  }

  /// "TZS 800,000/month" in the reader's words; [short] for a card.
  String priceLabel(AppText text, {bool short = false}) =>
      HmMoney.perMonth(text, price, currency: currency, short: short);

  factory PropertySummary.fromJson(Map<String, dynamic> json) => PropertySummary(
        id: json['id'] as String? ?? '',
        referenceCode: json['reference_code'] as String? ?? '',
        title: json['title'] as String? ?? 'Untitled listing',
        price: json['price'] == null ? null : HmMoney.parse(json['price']),
        currency: json['currency'] as String? ?? 'TZS',
        bedrooms: json['bedrooms'] == null ? null : _int(json['bedrooms']),
        bathrooms: json['bathrooms'] == null ? null : _int(json['bathrooms']),
        sizeSqm: json['size_sqm'] == null ? null : HmMoney.parse(json['size_sqm']),
        addressLine: json['address_line'] as String?,
        propertyTypeName: json['property_type_name'] as String?,
        regionName: json['region_name'] as String?,
        districtName: json['district_name'] as String?,
        wardName: json['ward_name'] as String?,
        coverMediaId: json['cover_media_id'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        totalMonthlyCost:
            json['total_monthly_cost'] == null ? null : HmMoney.parse(json['total_monthly_cost']),
        furnishing: json['furnishing'] as String?,
        isSaved: json['is_saved'] as bool? ?? false,
        distanceMetres: (json['distance_metres'] as num?)?.toDouble(),
      );

  PropertySummary copyWith({bool? isSaved}) => PropertySummary(
        id: id,
        referenceCode: referenceCode,
        title: title,
        price: price,
        currency: currency,
        bedrooms: bedrooms,
        bathrooms: bathrooms,
        sizeSqm: sizeSqm,
        addressLine: addressLine,
        propertyTypeName: propertyTypeName,
        regionName: regionName,
        districtName: districtName,
        wardName: wardName,
        coverMediaId: coverMediaId,
        latitude: latitude,
        longitude: longitude,
        totalMonthlyCost: totalMonthlyCost,
        furnishing: furnishing,
        isSaved: isSaved ?? this.isSaved,
        distanceMetres: distanceMetres,
      );
}

class PropertyMedia {
  const PropertyMedia({required this.id, this.caption, this.isCover = false});

  final String id;
  final String? caption;
  final bool isCover;

  factory PropertyMedia.fromJson(Map<String, dynamic> json) => PropertyMedia(
        id: json['id'] as String? ?? '',
        caption: json['caption'] as String?,
        isCover: json['isCover'] as bool? ?? false,
      );
}

class NamedItem {
  const NamedItem({required this.id, required this.name, this.code});

  final String id;
  final String name;
  final String? code;

  factory NamedItem.fromJson(Map<String, dynamic> json) => NamedItem(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        code: json['code'] as String?,
      );
}

class PropertyCharge {
  const PropertyCharge({
    required this.id,
    required this.name,
    required this.amount,
    required this.frequency,
    this.isMandatory = true,
    this.isRefundable = false,
  });

  final String id;
  final String name;
  final double amount;
  final String frequency;
  final bool isMandatory;
  final bool isRefundable;

  factory PropertyCharge.fromJson(Map<String, dynamic> json) => PropertyCharge(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        amount: HmMoney.parse(json['amount']),
        frequency: json['frequency'] as String? ?? 'monthly',
        isMandatory: json['isMandatory'] as bool? ?? true,
        isRefundable: json['isRefundable'] as bool? ?? false,
      );
}

/// Everything the property screen shows — CUS-005, in one response.
/// The HomeMate fee: a share of one month's rent, charged once in the first
/// payment instead of the full month an agent usually takes — and what that
/// saves the customer. Shown on the listing, and highlighted at checkout.
class ServiceFee {
  const ServiceFee({
    this.amount = 0,
    this.percentage = 0,
    this.benchmarkAmount = 0,
    this.benchmarkLabel = "Usual agent fee (one month's rent)",
    this.saving = 0,
  });

  final double amount;
  final double percentage;
  final double benchmarkAmount;
  final String benchmarkLabel;
  final double saving;

  bool get isCharged => amount > 0;
  bool get savesSomething => saving > 0;

  /// "50%", without a trailing ".0" nobody asked for.
  String get percentageLabel =>
      '${percentage == percentage.roundToDouble() ? percentage.toStringAsFixed(0) : percentage.toStringAsFixed(1)}%';

  static ServiceFee? fromJsonOrNull(Object? json) =>
      json is Map<String, dynamic> ? ServiceFee.fromJson(json) : null;

  factory ServiceFee.fromJson(Map<String, dynamic> json) => ServiceFee(
        amount: HmMoney.parse(json['amount']),
        percentage: HmMoney.parse(json['percentage']),
        benchmarkAmount: HmMoney.parse(json['benchmarkAmount']),
        benchmarkLabel: json['benchmarkLabel'] as String? ?? "Usual agent fee (one month's rent)",
        saving: HmMoney.parse(json['saving']),
      );
}

class PropertyDetail {
  const PropertyDetail({
    required this.summary,
    this.description,
    this.media = const [],
    this.amenities = const [],
    this.charges = const [],
    this.paymentMethods = const [],
    this.landlordName,
    this.brokerName,
    this.agencyName,
    this.contactRole,
    this.contactVerified = false,
    this.contactActiveListings = 0,
    this.isSaved = false,
    this.myInquiryId,
    this.myInquiryStatus,
    this.depositMonths,
    this.advanceRentMonths,
    this.minLeaseMonths,
    this.paymentFrequency,
    this.noticePeriodDays,
    this.terms,
    this.houseRules,
    this.parkingSpaces,
    this.petsAllowed,
    this.availableFrom,
    this.serviceFee,
  });

  final PropertySummary summary;
  final String? description;
  final List<PropertyMedia> media;
  final List<NamedItem> amenities;
  final List<PropertyCharge> charges;
  final List<NamedItem> paymentMethods;
  final String? landlordName;
  final String? brokerName;
  final String? agencyName;

  /// 'broker' or 'landlord' — whose card the screen is showing. The server
  /// decides, so the app and the backoffice cannot disagree about who fronts
  /// a listing that has both.
  final String? contactRole;

  /// HomeMate's identity review of that person — not a claim about the home.
  final bool contactVerified;
  final int contactActiveListings;
  final bool isSaved;
  final String? myInquiryId;
  final String? myInquiryStatus;
  final double? depositMonths;
  final double? advanceRentMonths;
  final int? minLeaseMonths;
  final String? paymentFrequency;
  final int? noticePeriodDays;
  final String? terms;
  final String? houseRules;
  final int? parkingSpaces;
  final bool? petsAllowed;
  final DateTime? availableFrom;

  /// The HomeMate fee this listing will carry in the first payment, and what
  /// it saves against the usual month's agent fee.
  final ServiceFee? serviceFee;

  /// Once an enquiry is open the button changes from "Enquire" to "View
  /// enquiry", so the customer is not invited to ask the same thing twice.
  bool get hasOpenInquiry => myInquiryStatus == 'pending' || myInquiryStatus == 'responded';

  /// The name on the card: the broker fronts a listing that has one.
  String? get contactName => brokerName ?? landlordName;

  /// "Broker" / "Landlord" / the agency, for the line under the name.
  String get contactSubtitle =>
      agencyName ?? (contactRole == 'broker' ? 'Broker' : 'Landlord');

  double get _rent => summary.price ?? 0;

  /// The deposit in money rather than in months, because a customer budgets
  /// in shillings. Null when the listing does not ask for one.
  double? get depositAmount =>
      (depositMonths ?? 0) > 0 ? _rent * depositMonths! : null;

  double? get advanceRentAmount =>
      (advanceRentMonths ?? 0) > 0 ? _rent * advanceRentMonths! : null;

  /// The charges billed every month, which belong in the monthly total rather
  /// than in what is due on the day of the move.
  Iterable<PropertyCharge> get monthlyCharges =>
      charges.where((charge) => charge.frequency == 'monthly');

  Iterable<PropertyCharge> get oneOffCharges =>
      charges.where((charge) => charge.frequency != 'monthly');

  /// Rent plus whatever recurs with it.
  double get monthlyTotal =>
      _rent + monthlyCharges.fold<double>(0, (sum, charge) => sum + charge.amount);

  /// What actually has to be found before the keys change hands: the deposit,
  /// the rent paid up front, and every one-off charge. This is the number the
  /// design puts at the bottom of the breakdown, and the one a customer is
  /// otherwise left to work out with a calculator.
  double get moveInTotal =>
      (depositAmount ?? 0) +
      (advanceRentAmount ?? _rent) +
      (serviceFee?.amount ?? 0) +
      oneOffCharges.fold<double>(0, (sum, charge) => sum + charge.amount);

  /// The landlord has accepted this customer's enquiry, so the home can be
  /// paid for — the only road to paying there is.
  bool get isAccepted => myInquiryStatus == 'accepted';

  factory PropertyDetail.fromJson(Map<String, dynamic> json) {
    final property = json['property'] as Map<String, dynamic>? ?? const {};
    final contact = json['contact'] as Map<String, dynamic>? ?? const {};
    final inquiry = json['myInquiry'] as Map<String, dynamic>?;

    return PropertyDetail(
      summary: PropertySummary.fromJson(property),
      description: property['description'] as String?,
      media: (json['media'] as List? ?? const [])
          .map((m) => PropertyMedia.fromJson(m as Map<String, dynamic>))
          .toList(),
      amenities: (json['amenities'] as List? ?? const [])
          .map((a) => NamedItem.fromJson(a as Map<String, dynamic>))
          .toList(),
      charges: (json['charges'] as List? ?? const [])
          .map((c) => PropertyCharge.fromJson(c as Map<String, dynamic>))
          .toList(),
      paymentMethods: (json['paymentMethods'] as List? ?? const [])
          .map((p) => NamedItem.fromJson(p as Map<String, dynamic>))
          .toList(),
      landlordName: contact['landlordName'] as String?,
      brokerName: contact['brokerName'] as String?,
      agencyName: contact['agencyName'] as String?,
      contactRole: contact['contactRole'] as String?,
      contactVerified: contact['isVerified'] as bool? ?? false,
      contactActiveListings: _int(contact['activeListings']),
      isSaved: json['isSaved'] as bool? ?? false,
      myInquiryId: inquiry?['id'] as String?,
      myInquiryStatus: inquiry?['status'] as String?,
      depositMonths: property['deposit_months'] == null ? null : HmMoney.parse(property['deposit_months']),
      advanceRentMonths:
          property['advance_rent_months'] == null ? null : HmMoney.parse(property['advance_rent_months']),
      minLeaseMonths: property['min_lease_months'] == null ? null : _int(property['min_lease_months']),
      paymentFrequency: property['payment_frequency'] as String?,
      noticePeriodDays:
          property['notice_period_days'] == null ? null : _int(property['notice_period_days']),
      terms: property['terms'] as String?,
      houseRules: property['house_rules'] as String?,
      parkingSpaces: property['parking_spaces'] == null ? null : _int(property['parking_spaces']),
      petsAllowed: property['pets_allowed'] as bool?,
      availableFrom: _date(property['available_from']),
      serviceFee: ServiceFee.fromJsonOrNull(json['serviceFee']),
    );
  }
}

/// A page of results, with enough to know whether to ask for more.
class Paged<T> {
  const Paged({required this.items, this.total = 0, this.hasMore = false, this.offset = 0});

  final List<T> items;
  final int total;
  final bool hasMore;
  final int offset;

  bool get isEmpty => items.isEmpty;

  factory Paged.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) item) {
    final pagination = json['pagination'] as Map<String, dynamic>? ?? const {};
    return Paged(
      items: (json['items'] as List? ?? const [])
          .map((row) => item(row as Map<String, dynamic>))
          .toList(),
      total: _int(pagination['total']),
      hasMore: pagination['hasMore'] as bool? ?? false,
      offset: _int(pagination['offset']),
    );
  }

  Paged<T> append(Paged<T> next) => Paged(
        items: [...items, ...next.items],
        total: next.total,
        hasMore: next.hasMore,
        offset: next.offset,
      );
}

class Inquiry {
  const Inquiry({
    required this.id,
    required this.reference,
    required this.status,
    required this.message,
    required this.createdAt,
    this.response,
    this.rejectionReason,
    this.respondedAt,
    this.propertyId,
    this.propertyTitle,
    this.propertyReference,
    this.coverMediaId,
    this.moveInDate,
    this.occupants,
    this.hasBooking = false,
    this.bookingId,
    String? displayStatus,
  }) : displayStatus = displayStatus ?? status;

  final String id;
  final String reference;
  final String status;

  /// Where the whole journey stands, as the customer reads it: the landlord's
  /// answer until they accept, then the money — `awaiting_payment`,
  /// `awaiting_verification`, `paid`. The server works it out.
  final String displayStatus;
  final String message;
  final DateTime createdAt;
  final String? response;
  final String? rejectionReason;
  final DateTime? respondedAt;
  final String? propertyId;
  final String? propertyTitle;
  final String? propertyReference;
  final String? coverMediaId;
  final DateTime? moveInDate;
  final int? occupants;
  final bool hasBooking;

  /// The reservation this enquiry turned into once the customer started
  /// paying — and, once verified, the tenancy.
  final String? bookingId;

  bool get isPaid => displayStatus == 'paid';
  bool get isBeingVerified => displayStatus == 'awaiting_verification';

  bool get isOpen => status == 'pending' || status == 'responded';
  bool get wasAnswered => response != null && response!.isNotEmpty;

  factory Inquiry.fromJson(Map<String, dynamic> json) => Inquiry(
        id: json['id'] as String? ?? '',
        reference: json['reference'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
        message: json['message'] as String? ?? '',
        createdAt: _date(json['created_at']) ?? DateTime.now(),
        response: json['response'] as String?,
        rejectionReason: json['rejection_reason'] as String?,
        respondedAt: _date(json['responded_at']),
        propertyId: json['property_id'] as String?,
        propertyTitle: json['property_title'] as String?,
        propertyReference: json['property_reference'] as String?,
        coverMediaId: json['cover_media_id'] as String?,
        moveInDate: _date(json['move_in_date']),
        occupants: json['occupants'] == null ? null : _int(json['occupants']),
        hasBooking: json['has_booking'] as bool? ?? false,
        bookingId: json['booking_id'] as String?,
        displayStatus: json['display_status'] as String?,
      );
}

class CustomerPayment {
  const CustomerPayment({
    required this.id,
    required this.reference,
    required this.amount,
    required this.currency,
    required this.status,
    required this.customerState,
    this.purpose = 'rent',
    this.bookingId,
    this.bookingReference,
    this.propertyTitle,
    this.payToName,
    this.payToAccountName,
    this.payToAccountNumber,
    this.payReference,
    this.payInstructions,
    this.paymentMethodName,
    this.declaredAt,
    this.declaredReference,
    this.confirmedAt,
    this.failureReason,
    this.createdAt,
  });

  final String id;
  final String reference;
  final double amount;
  final String currency;
  final String status;

  /// What the button should say — the backend decides this so the app and the
  /// portal cannot disagree about whether a payment is payable.
  final String customerState;
  final String purpose;
  final String? bookingId;
  final String? bookingReference;
  final String? propertyTitle;
  final String? payToName;
  final String? payToAccountName;
  final String? payToAccountNumber;
  final String? payReference;
  final String? payInstructions;
  final String? paymentMethodName;
  final DateTime? declaredAt;
  final String? declaredReference;
  final DateTime? confirmedAt;
  final String? failureReason;
  final DateTime? createdAt;

  bool get hasInstructions => payToAccountNumber != null && payReference != null;
  bool get canDeclare => customerState == 'awaiting_payment';
  bool get isAwaitingVerification => customerState == 'awaiting_verification';
  bool get isPaid => customerState == 'paid';

  String get amountLabel => HmMoney.format(amount, currency: currency);

  factory CustomerPayment.fromJson(Map<String, dynamic> json) => CustomerPayment(
        id: json['id'] as String? ?? '',
        reference: json['reference'] as String? ?? '',
        amount: HmMoney.parse(json['amount']),
        currency: json['currency'] as String? ?? 'TZS',
        status: json['status'] as String? ?? 'pending',
        customerState: json['customer_state'] as String? ?? 'awaiting_instructions',
        purpose: json['purpose'] as String? ?? 'rent',
        bookingId: json['booking_id'] as String?,
        bookingReference: json['booking_reference'] as String?,
        propertyTitle: json['property_title'] as String?,
        payToName: json['pay_to_name'] as String?,
        payToAccountName: json['pay_to_account_name'] as String?,
        payToAccountNumber: json['pay_to_account_number'] as String?,
        payReference: json['pay_reference'] as String?,
        payInstructions: json['pay_instructions'] as String?,
        paymentMethodName: json['payment_method_name'] as String?,
        declaredAt: _date(json['customer_declared_paid_at']),
        declaredReference: json['customer_declared_reference'] as String?,
        confirmedAt: _date(json['confirmed_at']),
        failureReason: json['failure_reason'] as String?,
        createdAt: _date(json['created_at']),
      );
}

class Booking {
  const Booking({
    required this.id,
    required this.reference,
    required this.status,
    required this.monthlyRent,
    required this.totalDue,
    required this.amountPaid,
    required this.amountOutstanding,
    this.currency = 'TZS',
    this.depositAmount = 0,
    this.amountAwaitingVerification = 0,
    this.leaseMonths,
    this.moveInDate,
    this.leaseStartDate,
    this.leaseEndDate,
    this.propertyId,
    this.propertyTitle,
    this.propertyAddress,
    this.coverMediaId,
    this.landlordName,
    this.landlordPhone,
    this.cancellationReason,
    this.createdAt,
    this.payments = const [],
  });

  final String id;
  final String reference;
  final String status;
  final double monthlyRent;
  final double totalDue;
  final double amountPaid;
  final double amountOutstanding;
  final String currency;
  final double depositAmount;
  final double amountAwaitingVerification;
  final int? leaseMonths;
  final DateTime? moveInDate;
  final DateTime? leaseStartDate;
  final DateTime? leaseEndDate;
  final String? propertyId;
  final String? propertyTitle;
  final String? propertyAddress;
  final String? coverMediaId;
  final String? landlordName;
  final String? landlordPhone;
  final String? cancellationReason;
  final DateTime? createdAt;
  final List<CustomerPayment> payments;

  bool get isSettled => amountOutstanding <= 0;
  bool get canCancel =>
      status == 'pending' || status == 'awaiting_payment' || status == 'confirmed';

  /// The one payment the customer is being asked to act on, if any.
  CustomerPayment? get actionablePayment {
    for (final payment in payments) {
      if (payment.canDeclare) return payment;
    }
    for (final payment in payments) {
      if (payment.isAwaitingVerification) return payment;
    }
    return payments.isEmpty ? null : payments.first;
  }

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'] as String? ?? '',
        reference: json['reference'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
        monthlyRent: HmMoney.parse(json['monthly_rent']),
        totalDue: HmMoney.parse(json['total_due']),
        amountPaid: HmMoney.parse(json['amount_paid']),
        amountOutstanding: HmMoney.parse(json['amount_outstanding']),
        currency: json['currency'] as String? ?? 'TZS',
        depositAmount: HmMoney.parse(json['deposit_amount']),
        amountAwaitingVerification: HmMoney.parse(json['amount_awaiting_verification']),
        leaseMonths: json['lease_months'] == null ? null : _int(json['lease_months']),
        moveInDate: _date(json['move_in_date']),
        leaseStartDate: _date(json['lease_start_date']),
        leaseEndDate: _date(json['lease_end_date']),
        propertyId: json['property_id'] as String?,
        propertyTitle: json['property_title'] as String?,
        propertyAddress: json['property_address'] as String?,
        coverMediaId: json['cover_media_id'] as String?,
        landlordName: json['landlord_name'] as String?,
        landlordPhone: json['landlord_phone'] as String?,
        cancellationReason: json['cancellation_reason'] as String?,
        createdAt: _date(json['created_at']),
        payments: (json['payments'] as List? ?? const [])
            .map((p) => CustomerPayment.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.kind,
    required this.createdAt,
    this.body,
    this.readAt,
    this.subjectTable,
    this.subjectId,
  });

  final String id;
  final String title;
  final String kind;
  final DateTime createdAt;
  final String? body;
  final DateTime? readAt;
  final String? subjectTable;
  final String? subjectId;

  bool get isUnread => readAt == null;

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        kind: json['kind'] as String? ?? 'system',
        createdAt: _date(json['created_at']) ?? DateTime.now(),
        body: json['body'] as String?,
        readAt: _date(json['read_at']),
        subjectTable: json['subject_table'] as String?,
        subjectId: json['subject_id'] as String?,
      );
}

/// The counts behind the home screen and the profile badges.
class ActivitySummary {
  const ActivitySummary({
    this.savedCount = 0,
    this.openInquiries = 0,
    this.activeBookings = 0,
    this.amountOutstanding = 0,
    this.paymentsAwaitingVerification = 0,
    this.unreadNotifications = 0,
  });

  final int savedCount;
  final int openInquiries;
  final int activeBookings;
  final double amountOutstanding;
  final int paymentsAwaitingVerification;
  final int unreadNotifications;

  factory ActivitySummary.fromJson(Map<String, dynamic> json) => ActivitySummary(
        savedCount: _int(json['savedCount']),
        openInquiries: _int(json['openInquiries']),
        activeBookings: _int(json['activeBookings']),
        amountOutstanding: HmMoney.parse(json['amountOutstanding']),
        paymentsAwaitingVerification: _int(json['paymentsAwaitingVerification']),
        unreadNotifications: _int(json['unreadNotifications']),
      );
}

/// A place from OpenStreetMap, for the location picker.
class GeoPlace {
  const GeoPlace({required this.displayName, required this.latitude, required this.longitude});

  final String displayName;
  final double latitude;
  final double longitude;

  factory GeoPlace.fromJson(Map<String, dynamic> json) => GeoPlace(
        displayName: json['displayName'] as String? ?? '',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      );
}

/// One entry from a dictionary, with the parent that places it in the
/// region → district → ward tree.
class ReferenceItem {
  const ReferenceItem({required this.id, required this.name, this.code, this.parentId});

  final String id;
  final String name;
  final String? code;
  final String? parentId;

  factory ReferenceItem.fromJson(Map<String, dynamic> json) => ReferenceItem(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        code: json['code'] as String?,
        parentId: json['parentId'] as String?,
      );
}

/// Every list the app's pickers are built from, fetched once.
///
/// The filter sheet, the search overlay and the onboarding preferences step
/// all draw from this, so a property type added in the backoffice appears in
/// all three without a release.
class ReferenceData {
  const ReferenceData({
    this.propertyTypes = const [],
    this.amenities = const [],
    this.regions = const [],
    this.districts = const [],
    this.wards = const [],
    this.banks = const [],
    this.mobileMoneyProviders = const [],
  });

  final List<ReferenceItem> propertyTypes;
  final List<ReferenceItem> amenities;
  final List<ReferenceItem> regions;
  final List<ReferenceItem> districts;
  final List<ReferenceItem> wards;

  /// Where a partner can be paid (BRK-002c).
  final List<ReferenceItem> banks;
  final List<String> mobileMoneyProviders;

  List<ReferenceItem> districtsIn(String? regionId) =>
      regionId == null ? districts : districts.where((d) => d.parentId == regionId).toList();

  List<ReferenceItem> wardsIn(String? districtId) =>
      districtId == null ? const [] : wards.where((w) => w.parentId == districtId).toList();

  static List<ReferenceItem> _list(Object? raw) => (raw as List? ?? const [])
      .map((row) => ReferenceItem.fromJson(row as Map<String, dynamic>))
      .toList();

  factory ReferenceData.fromJson(Map<String, dynamic> json) => ReferenceData(
        propertyTypes: _list(json['propertyTypes']),
        amenities: _list(json['amenities']),
        regions: _list(json['regions']),
        districts: _list(json['districts']),
        wards: _list(json['wards']),
        banks: _list(json['banks']),
        mobileMoneyProviders: [for (final p in (json['mobileMoneyProviders'] as List? ?? const [])) '$p'],
      );
}

/// What the customer has told us they are looking for — CUS-008a, step 2, and
/// the source of the "new match" notifications.
class CustomerPreferences {
  const CustomerPreferences({
    this.budgetMin,
    this.budgetMax,
    this.bedroomsMin,
    this.preferredRegionId,
    this.propertyTypeIds = const [],
    this.amenityIds = const [],
    this.furnishing,
    this.moveInFrom,
    this.notifyNewMatches = true,
    this.notifyPriceDrops = true,
    this.notifyBySms = false,
  });

  final double? budgetMin;
  final double? budgetMax;
  final int? bedroomsMin;
  final String? preferredRegionId;
  final List<String> propertyTypeIds;
  final List<String> amenityIds;
  final String? furnishing;
  final DateTime? moveInFrom;
  final bool notifyNewMatches;
  final bool notifyPriceDrops;
  final bool notifyBySms;

  static List<String> _ids(Object? raw) =>
      (raw as List? ?? const []).map((value) => '$value').toList();

  factory CustomerPreferences.fromJson(Map<String, dynamic> json) => CustomerPreferences(
        budgetMin: json['budget_min'] == null ? null : HmMoney.parse(json['budget_min']),
        budgetMax: json['budget_max'] == null ? null : HmMoney.parse(json['budget_max']),
        bedroomsMin: json['bedrooms_min'] == null ? null : _int(json['bedrooms_min']),
        preferredRegionId: json['preferred_region_id'] as String?,
        propertyTypeIds: _ids(json['property_type_ids']),
        amenityIds: _ids(json['amenity_ids']),
        furnishing: json['furnishing'] as String?,
        moveInFrom: _date(json['move_in_from']),
        notifyNewMatches: json['notify_new_matches'] as bool? ?? true,
        notifyPriceDrops: json['notify_price_drops'] as bool? ?? true,
        notifyBySms: json['notify_by_sms'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'budgetMin': budgetMin,
        'budgetMax': budgetMax,
        'bedroomsMin': bedroomsMin,
        'preferredRegionId': preferredRegionId,
        'propertyTypeIds': propertyTypeIds,
        'amenityIds': amenityIds,
        'furnishing': furnishing,
        // A date, not a moment: "I can move in on the 3rd" has no time of day.
        'moveInFrom': moveInFrom == null
            ? null
            : '${moveInFrom!.year.toString().padLeft(4, '0')}-'
                '${moveInFrom!.month.toString().padLeft(2, '0')}-'
                '${moveInFrom!.day.toString().padLeft(2, '0')}',
        'notifyNewMatches': notifyNewMatches,
        'notifyPriceDrops': notifyPriceDrops,
        'notifyBySms': notifyBySms,
      };

  CustomerPreferences copyWith({
    Object? budgetMin = _unset,
    Object? budgetMax = _unset,
    Object? bedroomsMin = _unset,
    Object? preferredRegionId = _unset,
    List<String>? propertyTypeIds,
    List<String>? amenityIds,
    Object? furnishing = _unset,
    Object? moveInFrom = _unset,
    bool? notifyNewMatches,
    bool? notifyPriceDrops,
    bool? notifyBySms,
  }) =>
      CustomerPreferences(
        budgetMin: budgetMin == _unset ? this.budgetMin : budgetMin as double?,
        budgetMax: budgetMax == _unset ? this.budgetMax : budgetMax as double?,
        bedroomsMin: bedroomsMin == _unset ? this.bedroomsMin : bedroomsMin as int?,
        preferredRegionId:
            preferredRegionId == _unset ? this.preferredRegionId : preferredRegionId as String?,
        propertyTypeIds: propertyTypeIds ?? this.propertyTypeIds,
        amenityIds: amenityIds ?? this.amenityIds,
        furnishing: furnishing == _unset ? this.furnishing : furnishing as String?,
        moveInFrom: moveInFrom == _unset ? this.moveInFrom : moveInFrom as DateTime?,
        notifyNewMatches: notifyNewMatches ?? this.notifyNewMatches,
        notifyPriceDrops: notifyPriceDrops ?? this.notifyPriceDrops,
        notifyBySms: notifyBySms ?? this.notifyBySms,
      );

  static const Object _unset = Object();
}

/// One piece of identity evidence the customer has uploaded.
class IdentityDocument {
  const IdentityDocument({
    required this.id,
    required this.documentType,
    required this.status,
    this.rejectionReason,
  });

  final String id;
  final String documentType;
  final String status;
  final String? rejectionReason;

  factory IdentityDocument.fromJson(Map<String, dynamic> json) => IdentityDocument(
        id: json['id'] as String? ?? '',
        documentType: json['document_type'] as String? ?? 'other',
        status: json['status'] as String? ?? 'pending',
        rejectionReason: json['rejection_reason'] as String?,
      );
}

/// Where the customer stands with identity verification — CUS-008b.
class IdentityStatus {
  const IdentityStatus({
    this.kycStatus = 'not_started',
    this.rejectionReason,
    this.hasPhoto = false,
    this.documents = const [],
  });

  final String kycStatus;
  final String? rejectionReason;
  final bool hasPhoto;
  final List<IdentityDocument> documents;

  bool get isVerified => kycStatus == 'verified';

  /// Whether a document of this kind has already been sent in. The screen
  /// shows "not verified" against each slot until an operator has looked, so
  /// this answers "has anything been uploaded", not "has it been accepted".
  bool has(String documentType) =>
      documents.any((document) => document.documentType == documentType);

  String statusOf(String documentType) => documents
      .firstWhere(
        (document) => document.documentType == documentType,
        orElse: () => const IdentityDocument(id: '', documentType: '', status: 'not_started'),
      )
      .status;

  factory IdentityStatus.fromJson(Map<String, dynamic> json) => IdentityStatus(
        kycStatus: json['kycStatus'] as String? ?? 'not_started',
        rejectionReason: json['rejectionReason'] as String?,
        hasPhoto: json['hasPhoto'] as bool? ?? false,
        documents: (json['documents'] as List? ?? const [])
            .map((row) => IdentityDocument.fromJson(row as Map<String, dynamic>))
            .toList(),
      );
}
