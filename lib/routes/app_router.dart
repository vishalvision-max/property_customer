import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../presentation/screens/auth/forgot_password_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/onboarding_screen.dart';
import '../presentation/screens/auth/signup_screen.dart';
import '../presentation/screens/auth/splash_screen.dart';
import '../presentation/screens/home/favorites_screen.dart';
import '../presentation/screens/home/notifications_screen.dart';
import '../presentation/screens/leads/lead_create_screen.dart';
import '../presentation/screens/leads/leads_screen.dart';
import '../presentation/screens/profile/profile_screen.dart';
import '../presentation/screens/profile/edit_owner_profile_screen.dart';
import '../presentation/screens/profile/change_password_screen.dart';
import '../presentation/screens/property/property_details_screen.dart';
import '../presentation/screens/property/property_list_screen.dart';
import '../presentation/screens/property/property_name_search_args.dart';
import '../presentation/screens/property/schedule_visit_screen.dart';
import '../presentation/screens/search/name_search_results_screen.dart';
import '../presentation/screens/search/name_search_screen.dart';
import '../presentation/screens/search/search_screen.dart';
import '../presentation/screens/shell/main_shell.dart';
import '../providers/auth_provider.dart';

class GoRouterRefreshListenable extends ChangeNotifier {
  GoRouterRefreshListenable(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, __) {
      notifyListeners();
    });
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  String? redirect(BuildContext context, GoRouterState state) {
    final path = state.uri.path;
    final loggingIn =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/signup' ||
        state.matchedLocation == '/forgot';
    final onboarding = state.matchedLocation == '/onboarding';
    final splash = state.matchedLocation == '/splash';

    final isAuthed = auth.user != null;

    // --- Splash ---
    if (splash) {
      if (auth.isLoading) return null;
      if (!auth.seenOnboarding) return '/onboarding';
      if (!isAuthed) return '/login';
      return '/home';
    }

    // While auth is still loading (e.g. after a hot restart or provider rebuild),
    // never redirect — wait for bootstrap to finish first.
    if (auth.isLoading) return null;

    if (!auth.seenOnboarding && !onboarding) return '/onboarding';

    // Guest mode: allow browsing without login. Only protect specific routes.
    final isProtected =
        path == '/favorites' ||
        path.startsWith('/profile') ||
        path == '/leads' ||
        path.startsWith('/leads/') ||
        path.startsWith('/schedule/');
    if (!isAuthed && isProtected) {
      return '/login?from=${Uri.encodeComponent(path)}';
    }

    if (isAuthed && (loggingIn || onboarding)) return '/home';
    return null;
  }

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshListenable(ref),
    redirect: redirect,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const MainShell()),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/name-search',
        builder: (context, state) => const NameSearchScreen(),
      ),
      GoRoute(
        path: '/name-search-results',
        builder: (context, state) {
          final args = state.extra as PropertyNameSearchArgs;
          return NameSearchResultsScreen(args: args);
        },
      ),
      GoRoute(
        path: '/properties',
        builder: (context, state) => const PropertyListScreen(),
      ),
      GoRoute(
        path: '/property/:id',
        builder: (context, state) =>
            PropertyDetailsScreen(propertyId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/schedule/:id',
        builder: (context, state) =>
            ScheduleVisitScreen(propertyId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(path: '/leads', builder: (context, state) => const LeadsScreen()),
      GoRoute(
        path: '/leads/new',
        builder: (context, state) {
          final query = state.uri.queryParameters;
          return LeadCreateScreen(
            propertyId: query['property_id'],
            type: query['type'],
          );
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditOwnerProfileScreen(),
      ),
      GoRoute(
        path: '/profile/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
    ],
  );
});
