import 'json_read.dart';

/// An enquiry on one of the partner's listings (BRK-040/041).
class PartnerEnquiry {
  const PartnerEnquiry({
    required this.id,
    required this.status,
    this.reference,
    this.message,
    this.moveInDate,
    this.occupants,
    this.budgetAmount,
    this.contactPreference,
    this.preferredContactTime,
    this.response,
    this.rejectionReason,
    this.createdAt,
    this.propertyId = '',
    this.propertyTitle = '',
    this.propertyCoverUrl,
    this.customerName = '',
    this.customerIdVerified = false,
    this.customerPhone,
    this.canAnswer = false,
  });

  final String id;

  /// `pending`, `responded`, `accepted`, `rejected`, `withdrawn`, `closed`.
  final String status;
  final String? reference;
  final String? message;
  final DateTime? moveInDate;
  final int? occupants;
  final double? budgetAmount;
  final String? contactPreference;
  final String? preferredContactTime;
  final String? response;
  final String? rejectionReason;
  final DateTime? createdAt;
  final String propertyId;
  final String propertyTitle;
  final String? propertyCoverUrl;
  final String customerName;
  final bool customerIdVerified;

  /// Only for whoever answers the enquiry.
  final String? customerPhone;
  final bool canAnswer;

  bool get isOpen => status == 'pending' || status == 'responded';

  factory PartnerEnquiry.fromJson(Map<String, dynamic> json) {
    final property = readMap(json['property']);
    final customer = readMap(json['customer']);
    return PartnerEnquiry(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      reference: json['reference'] as String?,
      message: json['message'] as String?,
      moveInDate: readDate(json['moveInDate']),
      occupants: json['occupants'] == null ? null : readInt(json['occupants']),
      budgetAmount: json['budgetAmount'] == null ? null : readNum(json['budgetAmount']),
      contactPreference: json['contactPreference'] as String?,
      preferredContactTime: json['preferredContactTime'] as String?,
      response: json['response'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: readDate(json['createdAt']),
      propertyId: property['id'] as String? ?? '',
      propertyTitle: property['title'] as String? ?? '',
      propertyCoverUrl: property['coverPhotoUrl'] as String?,
      customerName: customer['name'] as String? ?? '',
      customerIdVerified: customer['idVerified'] as bool? ?? false,
      customerPhone: customer['phone'] as String?,
      canAnswer: json['canAnswer'] as bool? ?? false,
    );
  }
}

/// One step of the BRK-042 tracker; the server decides its state.
class EnquiryStep {
  const EnquiryStep({required this.key, required this.title, required this.state, this.at});

  final String key;
  final String title;
  final String state;
  final DateTime? at;

  factory EnquiryStep.fromJson(Map<String, dynamic> json) => EnquiryStep(
        key: json['key'] as String? ?? '',
        title: json['title'] as String? ?? '',
        state: json['state'] as String? ?? 'upcoming',
        at: readDate(json['at']),
      );
}

/// BRK-042: the tracker, what the customer pays, and what the partner earns.
class EnquiryJourney {
  const EnquiryJourney({
    required this.enquiry,
    this.steps = const [],
    this.yourShare = 0,
    this.firstRent = 0,
    this.deposit = 0,
    this.advance = 0,
    this.tenantFee = 0,
    this.tenantFeePercentage = 0,
    this.total = 0,
  });

  final PartnerEnquiry enquiry;
  final List<EnquiryStep> steps;
  final double yourShare;
  final double firstRent;
  final double deposit;
  final double advance;
  final double tenantFee;
  final double tenantFeePercentage;
  final double total;

  factory EnquiryJourney.fromJson(Map<String, dynamic> json) {
    final earning = readMap(json['earning']);
    final payment = readMap(json['payment']);
    return EnquiryJourney(
      enquiry: PartnerEnquiry.fromJson(readMap(json['inquiry'])),
      steps: readList(json['steps'], EnquiryStep.fromJson),
      yourShare: readNum(earning['yourShare']),
      firstRent: readNum(payment['firstRent']),
      deposit: readNum(payment['deposit']),
      advance: readNum(payment['advance']),
      tenantFee: readNum(payment['tenantFee'] ?? earning['tenantFee']),
      tenantFeePercentage: readNum(payment['tenantFeePercentage']),
      total: readNum(payment['total']),
    );
  }
}

/// The four outcomes on BRK-041.
enum EnquiryOutcome {
  reply('responded'),
  accept('accepted'),
  decline('rejected'),
  close('closed');

  const EnquiryOutcome(this.status);

  final String status;
}
