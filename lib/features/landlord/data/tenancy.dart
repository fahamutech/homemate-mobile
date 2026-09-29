import '../../partner_shared/data/json_read.dart';
import '../../shared/models.dart' show CustomerPayment;

/// Where a tenancy stands for its landlord (LND-030).
enum TenancyStage {
  movingIn('moving_in'),
  current('current'),
  past('past');

  const TenancyStage(this.code);

  final String code;

  static TenancyStage fromCode(String? code) =>
      values.firstWhere((stage) => stage.code == code, orElse: () => TenancyStage.past);
}

/// A tenancy as its landlord sees it (LND-030–033).
class Tenancy {
  const Tenancy({
    required this.id,
    required this.stage,
    this.reference,
    this.status = 'confirmed',
    this.tenantName = '',
    this.tenantPhone,
    this.propertyId = '',
    this.propertyTitle = '',
    this.propertyAddress,
    this.coverPhotoUrl,
    this.monthlyRent = 0,
    this.currency = 'TZS',
    this.depositAmount = 0,
    this.leaseMonths,
    this.leaseStartDate,
    this.leaseEndDate,
    this.moveInDate,
    this.endedOn,
    this.endReason,
    this.amountPaid = 0,
    this.amountOutstanding = 0,
    this.nextPaymentDate,
    this.monthsRemaining,
    this.agreementReference,
    this.payments = const [],
  });

  final String id;
  final TenancyStage stage;
  final String? reference;
  final String status;
  final String tenantName;
  final String? tenantPhone;
  final String propertyId;
  final String propertyTitle;
  final String? propertyAddress;
  final String? coverPhotoUrl;
  final double monthlyRent;
  final String currency;
  final double depositAmount;
  final int? leaseMonths;
  final DateTime? leaseStartDate;
  final DateTime? leaseEndDate;
  final DateTime? moveInDate;
  final DateTime? endedOn;
  final String? endReason;
  final double amountPaid;
  final double amountOutstanding;
  final DateTime? nextPaymentDate;
  final int? monthsRemaining;
  final String? agreementReference;

  /// Only on the detail.
  final List<CustomerPayment> payments;

  /// LND-032: only a tenancy waiting for its tenant can be started.
  bool get canConfirmMoveIn => stage == TenancyStage.movingIn;

  /// Only a tenancy someone lives in can be ended.
  bool get canEnd => stage == TenancyStage.current;

  factory Tenancy.fromJson(Map<String, dynamic> json) {
    final tenant = readMap(json['tenant']);
    final property = readMap(json['property']);
    return Tenancy(
      id: json['id'] as String? ?? '',
      stage: TenancyStage.fromCode(json['stage'] as String?),
      reference: json['reference'] as String?,
      status: json['status'] as String? ?? 'confirmed',
      tenantName: tenant['name'] as String? ?? '',
      tenantPhone: tenant['phone'] as String?,
      propertyId: property['id'] as String? ?? '',
      propertyTitle: property['title'] as String? ?? '',
      propertyAddress: property['address'] as String?,
      coverPhotoUrl: property['coverPhotoUrl'] as String?,
      monthlyRent: readNum(json['monthlyRent']),
      currency: json['currency'] as String? ?? 'TZS',
      depositAmount: readNum(json['depositAmount']),
      leaseMonths: json['leaseMonths'] == null ? null : readInt(json['leaseMonths']),
      leaseStartDate: readDate(json['leaseStartDate']),
      leaseEndDate: readDate(json['leaseEndDate']),
      moveInDate: readDate(json['moveInDate']),
      endedOn: readDate(json['endedOn']),
      endReason: json['endReason'] as String?,
      amountPaid: readNum(json['amountPaid']),
      amountOutstanding: readNum(json['amountOutstanding']),
      nextPaymentDate: readDate(json['nextPaymentDate']),
      monthsRemaining: json['monthsRemaining'] == null ? null : readInt(json['monthsRemaining']),
      agreementReference: json['agreementReference'] as String?,
      payments: [
        for (final row in (json['payments'] as List? ?? const []))
          if (row is Map<String, dynamic>) CustomerPayment.fromJson(row),
      ],
    );
  }
}

/// "2026-10-01": the day the server expects, in the phone's own calendar.
String isoDay(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
