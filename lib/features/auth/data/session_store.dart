import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// What the app remembers about who is signed in.
///
/// The token and the phone number are kept so a returning customer lands on
/// the PIN pad with their number already filled. The PIN itself is never
/// stored — it is typed every time, which is the whole point of having one.
class StoredSession {
  const StoredSession({required this.token, required this.userJson});

  final String token;
  final Map<String, dynamic> userJson;
}

abstract class SessionStore {
  Future<StoredSession?> read();
  Future<void> write(StoredSession session);
  Future<void> clear();

  /// Remembered across sign-out so the login screen can greet them by number.
  Future<String?> lastPhoneNumber();
  Future<void> rememberPhoneNumber(String phoneNumber);

  /// The number this device has actually been through OTP *and* PIN setup for.
  ///
  /// This is deliberately not [lastPhoneNumber]: that one is written the
  /// moment a code is requested, so trusting it would send somebody who
  /// abandoned the SMS step to a PIN pad for a PIN that does not exist. Only a
  /// completed enrolment writes this one, and it is what decides whether the
  /// app opens on the keypad or on the phone-number form.
  Future<String?> pinEnrolledNumber();
  Future<void> rememberPinEnrolment(String phoneNumber);

  /// "Not my number" / "Re-verify this phone" — the device goes back to
  /// needing an SMS.
  Future<void> forgetPinEnrolment();
}

class SharedPreferencesSessionStore implements SessionStore {
  SharedPreferencesSessionStore({SharedPreferences? preferences}) : _injected = preferences;

  static const _tokenKey = 'hm.session.token';
  static const _userKey = 'hm.session.user';
  static const _phoneKey = 'hm.session.lastPhone';
  static const _enrolledKey = 'hm.session.pinEnrolledPhone';

  final SharedPreferences? _injected;
  SharedPreferences? _cached;

  Future<SharedPreferences> get _prefs async =>
      _injected ?? (_cached ??= await SharedPreferences.getInstance());

  @override
  Future<StoredSession?> read() async {
    final prefs = await _prefs;
    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) return null;

    final raw = prefs.getString(_userKey);
    Map<String, dynamic> user = const {};
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) user = decoded;
      } catch (_) {
        // A corrupted profile is not worth failing a launch over; the token
        // still signs requests and /app/me will refresh the details.
      }
    }
    return StoredSession(token: token, userJson: user);
  }

  @override
  Future<void> write(StoredSession session) async {
    final prefs = await _prefs;
    await prefs.setString(_tokenKey, session.token);
    await prefs.setString(_userKey, jsonEncode(session.userJson));
    if (session.userJson['phoneNumber'] case final String phone) {
      await prefs.setString(_phoneKey, phone);
    }
  }

  @override
  Future<void> clear() async {
    final prefs = await _prefs;
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    // The phone number and the PIN enrolment deliberately survive: signing out
    // is not forgetting the device, and making someone re-do an SMS because
    // they tapped "sign out" is exactly what the PIN exists to avoid.
  }

  @override
  Future<String?> lastPhoneNumber() async => (await _prefs).getString(_phoneKey);

  @override
  Future<void> rememberPhoneNumber(String phoneNumber) async =>
      (await _prefs).setString(_phoneKey, phoneNumber);

  @override
  Future<String?> pinEnrolledNumber() async => (await _prefs).getString(_enrolledKey);

  @override
  Future<void> rememberPinEnrolment(String phoneNumber) async {
    final prefs = await _prefs;
    await prefs.setString(_enrolledKey, phoneNumber);
    await prefs.setString(_phoneKey, phoneNumber);
  }

  @override
  Future<void> forgetPinEnrolment() async => (await _prefs).remove(_enrolledKey);
}

/// In-memory store for tests and for the web preview, where there is no point
/// persisting a session between refreshes of a throwaway build.
class InMemorySessionStore implements SessionStore {
  StoredSession? _session;
  String? _phone;
  String? _enrolled;

  @override
  Future<StoredSession?> read() async => _session;

  @override
  Future<void> write(StoredSession session) async {
    _session = session;
    if (session.userJson['phoneNumber'] case final String phone) _phone = phone;
  }

  @override
  Future<void> clear() async => _session = null;

  @override
  Future<String?> lastPhoneNumber() async => _phone;

  @override
  Future<void> rememberPhoneNumber(String phoneNumber) async => _phone = phoneNumber;

  @override
  Future<String?> pinEnrolledNumber() async => _enrolled;

  @override
  Future<void> rememberPinEnrolment(String phoneNumber) async {
    _enrolled = phoneNumber;
    _phone = phoneNumber;
  }

  @override
  Future<void> forgetPinEnrolment() async => _enrolled = null;
}
