import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_repository.dart';
import 'customer.dart';
import 'session_store.dart';

/// Where the app is in the sign-in journey.
///
/// The router reads exactly this to decide what to show, so "am I signed in"
/// has one answer rather than one per screen.
enum AuthStage {
  /// Reading the stored session; nothing should be shown but the splash.
  restoring,

  /// No session. Onboarding, sign-in and the OTP screens are reachable.
  signedOut,

  /// Signed in, but the profile step has not been done — CUS-008a.
  needsProfile,

  /// Fully signed in.
  ready,
}

class AuthState {
  const AuthState({
    required this.stage,
    this.customer,
    this.lastPhoneNumber,
    this.pinEnrolledNumber,
  });

  final AuthStage stage;
  final Customer? customer;

  /// Prefills the PIN screen for someone coming back.
  final String? lastPhoneNumber;

  /// The number this device has completed OTP *and* PIN setup for, or null.
  ///
  /// When it is set, sign-in opens straight on the keypad — the whole point of
  /// having a PIN. When it is not, the only way in is an SMS, even if a number
  /// was typed here before: an abandoned verification must not be mistaken for
  /// an enrolled device.
  final String? pinEnrolledNumber;

  bool get isSignedIn => stage == AuthStage.needsProfile || stage == AuthStage.ready;

  /// Whether this device may sign in with a PIN alone.
  bool get isPinEnrolled => (pinEnrolledNumber ?? '').isNotEmpty;

  AuthState copyWith({
    AuthStage? stage,
    Customer? customer,
    String? lastPhoneNumber,
    Object? pinEnrolledNumber = _unset,
  }) =>
      AuthState(
        stage: stage ?? this.stage,
        customer: customer ?? this.customer,
        lastPhoneNumber: lastPhoneNumber ?? this.lastPhoneNumber,
        // A sentinel, because forgetting the device is `null` meaning "clear
        // it", not `null` meaning "leave it alone".
        pinEnrolledNumber: pinEnrolledNumber == _unset
            ? this.pinEnrolledNumber
            : pinEnrolledNumber as String?,
      );

  static const Object _unset = Object();
}

/// Owns the session: restoring it at launch, replacing it on sign-in, and
/// dropping it when the server says it is no longer good.
///
/// Every screen that needs to know who is signed in watches this; none of them
/// read storage or call the auth endpoints themselves.
class AuthController extends StateNotifier<AuthState> {
  AuthController({required AuthRepository repository, required SessionStore store})
      : _repository = repository,
        _store = store,
        super(const AuthState(stage: AuthStage.restoring));

  final AuthRepository _repository;
  final SessionStore _store;

  /// The live token, read by the [ApiClient] on every request.
  String? token;

  /// Called once at launch. A stored token is trusted enough to route on, but
  /// is confirmed against the server so a revoked session does not leave
  /// someone staring at screens that will all fail.
  Future<void> restore() async {
    final stored = await _store.read();
    final phone = await _store.lastPhoneNumber();
    final enrolled = await _store.pinEnrolledNumber();

    if (stored == null) {
      state = AuthState(
        stage: AuthStage.signedOut,
        lastPhoneNumber: phone,
        pinEnrolledNumber: enrolled,
      );
      return;
    }

    token = stored.token;
    try {
      final customer = await _repository.me();
      state = AuthState(
        stage: _stageFor(customer),
        customer: customer,
        lastPhoneNumber: phone,
        pinEnrolledNumber: enrolled,
      );
    } catch (_) {
      // Expired, revoked, or the backend is unreachable. Either way the safe
      // landing is the sign-in screen, with their number remembered.
      token = null;
      await _store.clear();
      state = AuthState(
        stage: AuthStage.signedOut,
        lastPhoneNumber: phone,
        pinEnrolledNumber: enrolled,
      );
    }
  }

  /// Every path that reaches here — setting a PIN, resetting one, signing in
  /// with one — means this phone number has a working PIN, so this is the one
  /// place the device gets marked as enrolled.
  Future<void> adopt(AuthSession session) async {
    token = session.token;
    await _store.write(
      StoredSession(token: session.token, userJson: session.customer.toJson()),
    );
    await _store.rememberPinEnrolment(session.customer.phoneNumber);
    state = AuthState(
      stage: _stageFor(session.customer),
      customer: session.customer,
      lastPhoneNumber: session.customer.phoneNumber,
      pinEnrolledNumber: session.customer.phoneNumber,
    );
  }

  Future<void> rememberPhoneNumber(String phoneNumber) async {
    await _store.rememberPhoneNumber(phoneNumber);
    state = state.copyWith(lastPhoneNumber: phoneNumber);
  }

  /// "Not you?" / "Use a different number" — drops the PIN shortcut so the
  /// next sign-in has to prove the phone by SMS again. It does not touch the
  /// server: the PIN is still the account's, this device just stops offering
  /// it.
  Future<void> forgetDevice() async {
    await _store.forgetPinEnrolment();
    token = null;
    await _store.clear();
    state = AuthState(
      stage: AuthStage.signedOut,
      lastPhoneNumber: state.lastPhoneNumber,
      pinEnrolledNumber: null,
    );
  }

  /// After the profile step, so the router stops holding them there.
  Future<void> applyProfile(Customer customer) async {
    if (token case final current?) {
      await _store.write(StoredSession(token: current, userJson: customer.toJson()));
    }
    state = state.copyWith(stage: _stageFor(customer), customer: customer);
  }

  Future<void> signOut() async {
    token = null;
    await _store.clear();
    // The enrolment survives on purpose: signing out should land on the
    // keypad, not on an SMS that costs credit to send.
    state = AuthState(
      stage: AuthStage.signedOut,
      lastPhoneNumber: state.lastPhoneNumber,
      pinEnrolledNumber: state.pinEnrolledNumber,
    );
  }

  static AuthStage _stageFor(Customer customer) =>
      customer.onboardingComplete ? AuthStage.ready : AuthStage.needsProfile;
}
