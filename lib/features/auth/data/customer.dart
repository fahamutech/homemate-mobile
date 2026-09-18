/// The signed-in customer, as the app needs them.
///
/// Only what a screen actually shows or branches on — the API returns more,
/// but a model that mirrors every column becomes a second schema to maintain.
class Customer {
  const Customer({
    required this.id,
    required this.phoneNumber,
    this.fullName,
    this.email,
    this.preferredLanguage = 'en',
    this.hasPin = false,
    this.onboardingComplete = false,
    this.kycStatus = 'not_started',
    this.status = 'active',
  });

  final String id;
  final String phoneNumber;
  final String? fullName;
  final String? email;
  final String preferredLanguage;
  final bool hasPin;
  final bool onboardingComplete;
  final String kycStatus;
  final String status;

  /// What the profile screen shows before a name has been given.
  String get displayName =>
      (fullName != null && fullName!.trim().isNotEmpty) ? fullName!.trim() : phoneNumber;

  String get initials {
    final name = fullName?.trim();
    if (name == null || name.isEmpty) return '#';
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: json['id'] as String? ?? '',
        phoneNumber: json['phoneNumber'] as String? ?? '',
        fullName: json['fullName'] as String?,
        email: json['email'] as String?,
        preferredLanguage: json['preferredLanguage'] as String? ?? 'en',
        hasPin: json['hasPin'] as bool? ?? false,
        onboardingComplete: json['onboardingComplete'] as bool? ?? false,
        kycStatus: json['kycStatus'] as String? ?? 'not_started',
        status: json['status'] as String? ?? 'active',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'phoneNumber': phoneNumber,
        'fullName': fullName,
        'email': email,
        'preferredLanguage': preferredLanguage,
        'hasPin': hasPin,
        'onboardingComplete': onboardingComplete,
        'kycStatus': kycStatus,
        'status': status,
      };

  Customer copyWith({String? fullName, String? email, String? preferredLanguage, bool? onboardingComplete}) =>
      Customer(
        id: id,
        phoneNumber: phoneNumber,
        fullName: fullName ?? this.fullName,
        email: email ?? this.email,
        preferredLanguage: preferredLanguage ?? this.preferredLanguage,
        hasPin: hasPin,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
        kycStatus: kycStatus,
        status: status,
      );
}

/// What `POST /customer/auth/otp/request` answers.
class OtpChallenge {
  const OtpChallenge({this.challengeId, this.resendAfterSeconds = 60, this.expiresAt});

  final String? challengeId;
  final int resendAfterSeconds;
  final DateTime? expiresAt;

  /// A reset for an unregistered number returns no challenge on purpose, so
  /// the screen must not assume there is one to verify against.
  bool get wasSent => challengeId != null;

  factory OtpChallenge.fromJson(Map<String, dynamic> json) => OtpChallenge(
        challengeId: json['challengeId'] as String?,
        resendAfterSeconds: (json['resendAfterSeconds'] as num?)?.toInt() ?? 60,
        expiresAt: DateTime.tryParse('${json['expiresAt'] ?? ''}'),
      );
}

/// What verifying a code gives back: permission to set a PIN, not a session.
class PhoneVerification {
  const PhoneVerification({
    required this.verificationToken,
    required this.hasPin,
    required this.onboardingComplete,
  });

  final String verificationToken;
  final bool hasPin;
  final bool onboardingComplete;

  factory PhoneVerification.fromJson(Map<String, dynamic> json) => PhoneVerification(
        verificationToken: json['verificationToken'] as String? ?? '',
        hasPin: json['hasPin'] as bool? ?? false,
        onboardingComplete: json['onboardingComplete'] as bool? ?? false,
      );
}
