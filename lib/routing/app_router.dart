import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';
import '../features/auth/data/auth_controller.dart';
import '../features/auth/presentation/forgot_pin_screen.dart';
import '../features/auth/presentation/onboarding_screen.dart';
import '../features/auth/presentation/otp_screen.dart';
import '../features/auth/presentation/pin_setup_screen.dart';
import '../features/auth/presentation/profile_setup_screen.dart';
import '../features/auth/presentation/sign_in_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/booking/presentation/booking_detail_screen.dart';
import '../features/booking/presentation/bookings_screen.dart';
import '../features/discovery/presentation/home_screen.dart';
import '../features/discovery/presentation/search_screen.dart';
import '../features/inquiry/presentation/inquiries_screen.dart';
import '../features/inquiry/presentation/inquiry_detail_screen.dart';
import '../features/inquiry/presentation/inquiry_form_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/payment/presentation/payment_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/property/presentation/property_screen.dart';
import '../features/saved/presentation/saved_screen.dart';
import '../features/viewing/presentation/viewing_detail_screen.dart';
import '../features/viewing/presentation/viewings_screen.dart';
import '../features/viewing/presentation/schedule_viewing_screen.dart';
import 'app_shell.dart';

/// Every path in the app, named once.
///
/// Screens navigate with `context.go(Routes.property(id))` rather than a
/// string literal, so a renamed path is a compile error rather than a dead
/// link someone finds in production.
class Routes {
  const Routes._();

  static const splash = '/';
  static const onboarding = '/welcome';
  static const signIn = '/sign-in';
  static const otp = '/verify';
  static const pinSetup = '/set-pin';
  static const forgotPin = '/forgot-pin';
  static const profileSetup = '/complete-profile';

  static const home = '/home';
  static const search = '/search';
  static const saved = '/saved';
  static const activity = '/activity';
  static const profile = '/profile';
  static const notifications = '/notifications';

  static String property(String id) => '/property/$id';
  static String inquiryForm(String propertyId) => '/property/$propertyId/enquire';
  static String scheduleViewing(String propertyId) => '/property/$propertyId/viewing';
  static const inquiries = '/activity/enquiries';
  static const viewings = '/activity/viewings';
  static const bookings = '/activity';

  /// Detail screens sit outside the tab shell, alongside /property and
  /// /payment. A detail is reachable from a list, from a notification and from
  /// the screen that created it — nesting it inside one tab's navigator means
  /// pushing it from anywhere else collides with that tab's page keys.
  static String inquiry(String id) => '/enquiry/$id';
  static String viewing(String id) => '/viewing/$id';
  static String booking(String id) => '/booking/$id';
  static String payment(String id) => '/payment/$id';

  /// The screens reachable without a session.
  ///
  /// The splash is deliberately NOT one of them. It is only ever correct while
  /// the stored session is being read; treating it as a normal public route
  /// meant the redirect had no reason to move off it once reading finished,
  /// and the app sat on the splash screen forever.
  static const _public = {onboarding, signIn, otp, pinSetup, forgotPin};

  static bool isPublic(String location) =>
      _public.contains(location) || location.startsWith('$otp?') || location.startsWith('$pinSetup?');
}

/// Rebuilds the router's redirect whenever the session changes.
///
/// go_router needs a `Listenable`; Riverpod gives a stream. This is the one
/// adapter between them, so nothing else has to know that go_router is
/// listening at all.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen(authControllerProvider, (previous, next) {
      if (previous?.stage != next.stage) notifyListeners();
    });
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,

    /// The only place the app decides who may see what.
    ///
    /// Putting it here rather than in each screen means a new screen is
    /// guarded the moment it is added, and there is exactly one answer to
    /// "where does an unauthenticated person end up".
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final location = state.matchedLocation;

      // Still reading storage: hold on the splash rather than flashing the
      // sign-in screen at someone who is already signed in.
      if (auth.stage == AuthStage.restoring) {
        return location == Routes.splash ? null : Routes.splash;
      }

      if (!auth.isSignedIn) {
        // Anyone still on the splash has finished restoring and has no
        // session, so they go on to the welcome screens.
        return Routes.isPublic(location) ? null : Routes.onboarding;
      }

      // Signed in but the profile step is outstanding — CUS-008a. Everything
      // else waits until it is done, because an enquiry with no name on it is
      // not much use to the landlord receiving it.
      if (auth.stage == AuthStage.needsProfile) {
        return location == Routes.profileSetup ? null : Routes.profileSetup;
      }

      // Signed in and complete: the entry screens have nothing left to offer.
      if (Routes.isPublic(location) || location == Routes.profileSetup) {
        return Routes.home;
      }
      return null;
    },

    routes: [
      GoRoute(path: Routes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: Routes.onboarding, builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: Routes.signIn, builder: (_, __) => const SignInScreen()),
      GoRoute(
        path: Routes.otp,
        builder: (_, state) => OtpScreen(
          phoneNumber: state.uri.queryParameters['phone'] ?? '',
          challengeId: state.uri.queryParameters['challenge'] ?? '',
          purpose: state.uri.queryParameters['purpose'] ?? 'login',
        ),
      ),
      GoRoute(
        path: Routes.pinSetup,
        builder: (_, state) => PinSetupScreen(
          verificationToken: state.uri.queryParameters['token'] ?? '',
          isReset: state.uri.queryParameters['reset'] == 'true',
        ),
      ),
      GoRoute(path: Routes.forgotPin, builder: (_, __) => const ForgotPinScreen()),
      GoRoute(path: Routes.profileSetup, builder: (_, __) => const ProfileSetupScreen()),

      // The five tabs keep their own navigation stacks, so moving between them
      // does not throw away where you were.
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.home,
              builder: (_, __) => const HomeScreen(),
              routes: [
                GoRoute(path: 'notifications', builder: (_, __) => const NotificationsScreen()),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.search, builder: (_, __) => const SearchScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.saved, builder: (_, __) => const SavedScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.activity,
              builder: (_, __) => const BookingsScreen(),
              routes: [
                GoRoute(path: 'enquiries', builder: (_, __) => const InquiriesScreen()),
                GoRoute(path: 'viewings', builder: (_, __) => const ViewingsScreen()),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.profile, builder: (_, __) => const ProfileScreen()),
          ]),
        ],
      ),

      // Full-screen routes that cover the tabs.
      GoRoute(
        path: '/property/:id',
        builder: (_, state) => PropertyScreen(propertyId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'enquire',
            builder: (_, state) => InquiryFormScreen(propertyId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'viewing',
            builder: (_, state) => ScheduleViewingScreen(propertyId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: '/enquiry/:id',
        builder: (_, state) => InquiryDetailScreen(inquiryId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/viewing/:id',
        builder: (_, state) => ViewingDetailScreen(viewingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/booking/:id',
        builder: (_, state) => BookingDetailScreen(bookingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/payment/:id',
        builder: (_, state) => PaymentScreen(paymentId: state.pathParameters['id']!),
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.explore_off_outlined, size: 44),
              const SizedBox(height: 16),
              const Text('That page does not exist.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go(Routes.home),
                child: const Text('Go home'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
});
