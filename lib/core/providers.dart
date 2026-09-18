import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/data/auth_controller.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/session_store.dart';
import '../features/shared/activity_repository.dart';
import '../features/shared/catalogue_repository.dart';
import '../features/shared/models.dart';
import 'config/env.dart';
import 'network/api_client.dart';

/// The composition root.
///
/// Every dependency the app has is built here and nowhere else, which is what
/// lets a test swap the whole backend for a fake with one override — and what
/// keeps widgets from reaching for an HTTP client of their own.

final sessionStoreProvider = Provider<SessionStore>(
  (ref) => SharedPreferencesSessionStore(),
);

/// Bridges the session into the transport without either knowing the other:
/// the client asks for a token, and reports a rejected one back.
class _ControllerSession implements SessionSource {
  _ControllerSession(this._ref);

  final Ref _ref;

  @override
  String? get token => _ref.read(authControllerProvider.notifier).token;

  @override
  Future<void> onSessionRejected() =>
      _ref.read(authControllerProvider.notifier).signOut();
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(session: _ControllerSession(ref));
  ref.onDispose(client.close);
  return client;
});

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => HttpAuthRepository(ref.watch(apiClientProvider)),
);

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(
    repository: ref.watch(authRepositoryProvider),
    store: ref.watch(sessionStoreProvider),
  ),
);

final catalogueRepositoryProvider = Provider<CatalogueRepository>(
  (ref) => HttpCatalogueRepository(ref.watch(apiClientProvider), baseUrl: Env.apiBaseUrl),
);

final activityRepositoryProvider = Provider<ActivityRepository>(
  (ref) => HttpActivityRepository(ref.watch(apiClientProvider)),
);

/// The signed-in customer, or null. Screens watch this rather than digging
/// into the auth state themselves.
final currentCustomerProvider = Provider(
  (ref) => ref.watch(authControllerProvider).customer,
);

/// The badge counts on the home screen and the profile tab. It is a family of
/// one so that any screen can `invalidate` it after acting, and every badge in
/// the app moves together.
final activitySummaryProvider = FutureProvider<ActivitySummary>(
  (ref) => ref.watch(activityRepositoryProvider).summary(),
);
