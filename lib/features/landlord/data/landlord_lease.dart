import '../../partner_shared/data/json_read.dart';
import '../../shared/journey_models.dart' show LeaseAgreement;

/// The landlord's `/app/landlord/tenancies/:id/lease` read into the same
/// [LeaseAgreement] the tenant's lease screen draws (LND-033). The agreement
/// is nested and null until one is drawn up; the terms agreed at booking are
/// always there.
LeaseAgreement leaseFromLandlordJson(Map<String, dynamic> json) {
  final agreement = readMap(json['agreement']);
  final hasAgreement = json['agreement'] is Map;
  return LeaseAgreement(
    bookingReference: json['bookingReference'] as String? ?? '',
    id: hasAgreement ? agreement['id'] as String? : null,
    reference: agreement['reference'] as String?,
    version: agreement['version'] as String?,
    leaseType: agreement['leaseType'] as String?,
    documentUrl: agreement['documentUrl'] as String?,
    noticePeriodDays: agreement['noticePeriodDays'] == null ? null : readInt(agreement['noticePeriodDays']),
    terms: agreement['terms'] as String?,
    houseRules: agreement['houseRules'] as String?,
    acceptedAt: readDate(agreement['acceptedAt']),
    leaseStartDate: readDate(json['leaseStartDate']),
    leaseEndDate: readDate(json['leaseEndDate']),
    leaseMonths: json['leaseMonths'] == null ? null : readInt(json['leaseMonths']),
    monthlyRent: readNum(json['monthlyRent']),
    depositAmount: readNum(json['depositAmount']),
    currency: json['currency'] as String? ?? 'TZS',
    propertyTitle: json['propertyTitle'] as String?,
    propertyAddress: json['propertyAddress'] as String?,
    tenantName: json['tenantName'] as String?,
  );
}
