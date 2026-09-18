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
  const AuthState({required this.stage, this.customer, this.lastPhoneNumber});

  final AuthStage stage;
  final Customer? customer;

  /// Prefills the PIN screen for someone coming back.
  final String? lastPhoneNumber;

  bool get isSignedIn => stage == AuthStage.needsProfile || stage == AuthStage.ready;

  AuthState copyWith({AuthStage? stage, Customer? customer, String? lastPhoneNumber}) => AuthState(
        stage: stage ?? this.stage,
        customer: customer ?? this.customer,
        lastPhoneNumber: lastPhoneNumber ?? this.lastPhoneNumber,
      );
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

    if (stored == null) {
      state = AuthState(stage: AuthStage.signedOut, lastPhoneNumber: phone);
      return;
    }

    token = stored.token;
    try {
      final customer = await _repository.me();
      state = AuthState(stage: _stageFor(customer), customer: customer, lastPhoneNumber: phone);
    } catch (_) {
      // Expired, revoked, or the backend is unreachable. Either way the safe
      // landing is the sign-in screen, with their number remembered.
      token = null;
      await _store.clear();
      state = AuthState(stage: AuthStage.signedOut, lastPhoneNumber: phone);
    }
  }

  Future<void> adopt(AuthSession session) async {
    token = session.token;
    await _store.write(
      StoredSession(token: session.token, userJson: session.customer.toJson()),
    );
    state = AuthState(
      stage: _stageFor(session.customer),
      customer: session.customer,
      lastPhoneNumber: session.customer.phoneNumber,
    );
  }

  Future<void> rememberPhoneNumber(String phoneNumber) async {
    await _store.rememberPhoneNumber(phoneNumber);
    state = state.copyWith(lastPhoneNumber: phoneNumber);
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
    state = AuthState(stage: AuthStage.signedOut, lastPhoneNumber: state.lastPhoneNumber);
  }

  static AuthStage _stageFor(Customer customer) =>
      customer.onboardingComplete ? AuthStage.ready : AuthStage.needsProfile;
}
