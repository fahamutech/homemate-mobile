import '../../../core/network/api_client.dart';
import 'customer.dart';

/// Every authentication call the app makes, and nothing else.
///
/// Screens talk to this, never to [ApiClient] — so a widget never has to know
/// a path, and the whole auth surface can be swapped for a fake in a test
/// without a single HTTP stub.
abstract class AuthRepository {
  Future<OtpChallenge> requestOtp({required String phoneNumber, String purpose});
  Future<PhoneVerification> verifyOtp({required String challengeId, required String code});
  Future<AuthSession> setPin({required String verificationToken, required String pin, required String confirmPin});
  Future<AuthSession> resetPin({required String verificationToken, required String pin, required String confirmPin});
  Future<AuthSession> login({required String phoneNumber, required String pin});
  Future<Customer> me();
  Future<Customer> completeProfile({
    required String fullName,
    String? email,
    String preferredLanguage,
    DateTime? dateOfBirth,
    String? gender,
  });
  Future<void> changePin({required String currentPin, required String pin, required String confirmPin});
}

/// A signed-in customer and the token that proves it.
class AuthSession {
  const AuthSession({required this.token, required this.customer});

  final String token;
  final Customer customer;

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        token: json['token'] as String? ?? '',
        customer: Customer.fromJson(json['user'] as Map<String, dynamic>? ?? const {}),
      );
}

class HttpAuthRepository implements AuthRepository {
  HttpAuthRepository(this._api);

  final ApiClient _api;

  @override
  Future<OtpChallenge> requestOtp({required String phoneNumber, String purpose = 'login'}) async =>
      OtpChallenge.fromJson(await _api.post(
        '/customer/auth/otp/request',
        body: {'phoneNumber': phoneNumber, 'purpose': purpose},
      ));

  @override
  Future<PhoneVerification> verifyOtp({required String challengeId, required String code}) async =>
      PhoneVerification.fromJson(await _api.post(
        '/customer/auth/otp/verify',
        body: {'challengeId': challengeId, 'code': code},
      ));

  @override
  Future<AuthSession> setPin({
    required String verificationToken,
    required String pin,
    required String confirmPin,
  }) async =>
      AuthSession.fromJson(await _api.post(
        '/customer/auth/pin',
        body: {'verificationToken': verificationToken, 'pin': pin, 'confirmPin': confirmPin},
      ));

  @override
  Future<AuthSession> resetPin({
    required String verificationToken,
    required String pin,
    required String confirmPin,
  }) async =>
      AuthSession.fromJson(await _api.post(
        '/customer/auth/pin/reset',
        body: {'verificationToken': verificationToken, 'pin': pin, 'confirmPin': confirmPin},
      ));

  @override
  Future<AuthSession> login({required String phoneNumber, required String pin}) async =>
      AuthSession.fromJson(await _api.post(
        '/customer/auth/login',
        body: {'phoneNumber': phoneNumber, 'pin': pin},
      ));

  @override
  Future<Customer> me() async => Customer.fromJson(await _api.get('/app/me'));

  @override
  Future<Customer> completeProfile({
    required String fullName,
    String? email,
    String preferredLanguage = 'en',
    DateTime? dateOfBirth,
    String? gender,
  }) async =>
      Customer.fromJson(await _api.post(
        '/app/me/profile',
        body: {
          'fullName': fullName,
          'email': email,
          'preferredLanguage': preferredLanguage,
          // A birthday is a day, not an instant — sending it as a timestamp
          // would let a timezone move somebody's date of birth.
          'dateOfBirth': dateOfBirth == null
              ? null
              : '${dateOfBirth.year.toString().padLeft(4, '0')}-'
                  '${dateOfBirth.month.toString().padLeft(2, '0')}-'
                  '${dateOfBirth.day.toString().padLeft(2, '0')}',
          'gender': gender,
        },
      ));

  @override
  Future<void> changePin({
    required String currentPin,
    required String pin,
    required String confirmPin,
  }) async {
    await _api.post(
      '/app/me/pin',
      body: {'currentPin': currentPin, 'pin': pin, 'confirmPin': confirmPin},
    );
  }
}
