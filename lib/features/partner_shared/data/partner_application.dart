import 'json_read.dart';

/// One step of a partner application: details, identity, ownership (landlord
/// only), payout, agreement.
class ApplicationStep {
  const ApplicationStep({required this.step, required this.complete});

  final String step;
  final bool complete;

  factory ApplicationStep.fromJson(Map<String, dynamic> json) =>
      ApplicationStep(step: json['step'] as String? ?? '', complete: json['complete'] as bool? ?? false);
}

/// A broker or landlord application as `GET /app/partner/applications` has it.
class PartnerApplication {
  const PartnerApplication({
    required this.role,
    required this.status,
    this.steps = const [],
    this.nextStep,
    this.missingSteps = const [],
    this.canSubmit = false,
    this.canDraftListings = false,
    this.canSubmitListings = false,
    this.identityVerified = false,
    this.agreementVersion,
    this.currentAgreementVersion,
    this.submittedAt,
    this.rejectionReason,
  });

  final String role;

  /// `not_started`, `invited`, `applied`, `pending_review`, `action_needed`,
  /// `active`, `rejected`, `suspended`.
  final String status;
  final List<ApplicationStep> steps;
  final String? nextStep;
  final List<String> missingSteps;
  final bool canSubmit;
  final bool canDraftListings;
  final bool canSubmitListings;
  final bool identityVerified;
  final String? agreementVersion;
  final String? currentAgreementVersion;
  final DateTime? submittedAt;
  final String? rejectionReason;

  bool isDone(String step) => steps.any((s) => s.step == step && s.complete);
  bool get isActive => status == 'active';
  bool get isUnderReview => status == 'pending_review';
  bool get needsAction => status == 'action_needed';

  /// Still filling in the setup: nothing sent for review yet.
  bool get isSettingUp => const {'not_started', 'invited', 'applied'}.contains(status);

  factory PartnerApplication.fromJson(Map<String, dynamic> json) => PartnerApplication(
        role: json['role'] as String? ?? '',
        status: json['status'] as String? ?? 'not_started',
        steps: readList(json['steps'], ApplicationStep.fromJson),
        nextStep: json['nextStep'] as String?,
        missingSteps: [for (final s in (json['missingSteps'] as List? ?? const [])) '$s'],
        canSubmit: json['canSubmit'] as bool? ?? false,
        canDraftListings: json['canDraftListings'] as bool? ?? false,
        canSubmitListings: json['canSubmitListings'] as bool? ?? false,
        identityVerified: json['identityVerified'] as bool? ?? false,
        agreementVersion: json['agreementVersion'] as String?,
        currentAgreementVersion: json['currentAgreementVersion'] as String?,
        submittedAt: readDate(json['submittedAt']),
        rejectionReason: json['rejectionReason'] as String?,
      );
}

/// Where HomeMate pays the partner.
class PayoutAccount {
  const PayoutAccount({required this.method, this.provider, this.accountName, this.accountNumber});

  /// `mobile_money` or `bank`.
  final String method;
  final String? provider;
  final String? accountName;
  final String? accountNumber;

  static PayoutAccount? fromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    return PayoutAccount(
      method: raw['method'] as String? ?? 'mobile_money',
      provider: raw['provider'] as String?,
      accountName: raw['accountName'] as String?,
      accountNumber: raw['accountNumber'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'method': method,
        'provider': provider,
        'accountName': accountName,
        'accountNumber': accountNumber,
      };
}

/// "Your details", prefilled from the customer profile.
class PartnerProfile {
  const PartnerProfile({
    this.fullName,
    this.dateOfBirth,
    this.nationalIdNumber,
    this.tinNumber,
    this.physicalAddress,
    this.kycStatus = 'not_started',
    this.payout,
  });

  final String? fullName;
  final DateTime? dateOfBirth;
  final String? nationalIdNumber;
  final String? tinNumber;
  final String? physicalAddress;
  final String kycStatus;
  final PayoutAccount? payout;

  bool get identityVerified => kycStatus == 'verified';

  factory PartnerProfile.fromJson(Map<String, dynamic> json) => PartnerProfile(
        fullName: json['fullName'] as String?,
        dateOfBirth: readDate(json['dateOfBirth']),
        nationalIdNumber: json['nationalIdNumber'] as String?,
        tinNumber: json['tinNumber'] as String?,
        physicalAddress: json['physicalAddress'] as String?,
        kycStatus: json['kycStatus'] as String? ?? 'not_started',
        payout: PayoutAccount.fromJson(json['payout']),
      );
}

/// What the backoffice asked the applicant to fix (BRK-002e).
class Remediation {
  const Remediation({required this.id, required this.issue, required this.requestedAction, this.documentType});

  final String id;
  final String issue;
  final String requestedAction;
  final String? documentType;

  factory Remediation.fromJson(Map<String, dynamic> json) => Remediation(
        id: json['id'] as String? ?? '',
        issue: json['issue'] as String? ?? '',
        requestedAction: json['requestedAction'] as String? ?? '',
        documentType: json['documentType'] as String?,
      );
}

/// BRK-002c "How you earn — an example", worked out by the server.
class FeeExample {
  const FeeExample({
    required this.rent,
    required this.tenantFee,
    required this.tenantFeePercentage,
    required this.platformAmount,
    required this.platformPercentage,
    required this.youReceive,
  });

  final double rent;
  final double tenantFee;
  final double tenantFeePercentage;
  final double platformAmount;
  final double platformPercentage;
  final double youReceive;

  static FeeExample? fromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    return FeeExample(
      rent: readNum(raw['rent']),
      tenantFee: readNum(raw['tenantFee']),
      tenantFeePercentage: readNum(raw['tenantFeePercentage']),
      platformAmount: readNum(raw['platformAmount']),
      platformPercentage: readNum(raw['platformPercentage']),
      youReceive: readNum(raw['youReceive']),
    );
  }
}

/// Everything the setup screens need in one read.
class ApplicationsOverview {
  const ApplicationsOverview({
    required this.profile,
    this.applications = const [],
    this.remediations = const [],
    this.feeExample,
  });

  final PartnerProfile profile;
  final List<PartnerApplication> applications;
  final List<Remediation> remediations;
  final FeeExample? feeExample;

  PartnerApplication application(String role) => applications.firstWhere(
        (a) => a.role == role,
        orElse: () => PartnerApplication(role: role, status: 'not_started'),
      );

  factory ApplicationsOverview.fromJson(Map<String, dynamic> json) => ApplicationsOverview(
        profile: PartnerProfile.fromJson(readMap(json['profile'])),
        applications: readList(json['applications'], PartnerApplication.fromJson),
        remediations: readList(json['remediations'], Remediation.fromJson),
        feeExample: FeeExample.fromJson(json['feeExample']),
      );
}

/// What "Your details" sends.
class PartnerDetails {
  const PartnerDetails({
    required this.fullName,
    this.dateOfBirth,
    this.nationalIdNumber,
    this.tinNumber,
    this.physicalAddress,
  });

  final String fullName;
  final DateTime? dateOfBirth;
  final String? nationalIdNumber;
  final String? tinNumber;
  final String? physicalAddress;

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'dateOfBirth': dateOfBirth == null
            ? null
            : '${dateOfBirth!.year.toString().padLeft(4, '0')}-'
                '${dateOfBirth!.month.toString().padLeft(2, '0')}-'
                '${dateOfBirth!.day.toString().padLeft(2, '0')}',
        'nationalIdNumber': nationalIdNumber,
        'tinNumber': tinNumber,
        'physicalAddress': physicalAddress,
      };
}
