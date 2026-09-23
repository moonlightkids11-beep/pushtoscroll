import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../di/providers.dart';
import '../../features/app_restriction/presentation/blocked_screen.dart';
import '../../features/app_restriction/presentation/restricted_apps_screen.dart';
import '../../features/exercise/presentation/exercise_screen.dart';
import '../../features/onboarding/presentation/onboarding_controller.dart';
import '../../features/onboarding/presentation/permission_setup_screen.dart';
import '../../features/onboarding/presentation/theme_selection_screen.dart';
import '../../features/stats/presentation/progress_screen.dart';
import '../../features/timer/presentation/home_screen.dart';

import 'package:flutter/widgets.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final initialCompleted = ref.watch(initialOnboardingCompletedProvider);
  final initialTheme = ref.watch(initialThemeModeProvider);

  // Determine initial location based on persisted onboarding state upon app start/restart
  final initialLocation = initialCompleted
      ? '/'
      : (initialTheme != null ? '/permissions' : '/theme-selection');

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    redirect: (context, state) {
      final onboardingState = ref.read(onboardingControllerProvider);
      final isCompleted = onboardingState.isCompleted;
      final isThemeSelected = onboardingState.isThemeSelected;
      final loc = state.matchedLocation;

      final isProtectedPath = loc == '/' ||
          loc == '/exercise' ||
          loc == '/apps' ||
          loc == '/restricted-apps' ||
          loc == '/progress' ||
          loc == '/blocked';

      if (!isCompleted && isProtectedPath) {
        return isThemeSelected ? '/permissions' : '/theme-selection';
      }

      if (isCompleted && (loc == '/theme-selection' || loc == '/permissions')) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/theme-selection',
        builder: (context, state) => const ThemeSelectionScreen(),
      ),
      GoRoute(
        path: '/permissions',
        builder: (context, state) => const PermissionSetupScreen(),
      ),
      GoRoute(
        path: '/exercise',
        builder: (context, state) => const ExerciseScreen(),
      ),
      GoRoute(
        path: '/blocked',
        builder: (context, state) => const BlockedScreen(),
      ),
      GoRoute(
        path: '/restricted-apps',
        builder: (context, state) => const RestrictedAppsScreen(),
      ),
      GoRoute(
        path: '/apps',
        redirect: (context, state) => '/restricted-apps',
      ),
      GoRoute(
        path: '/progress',
        builder: (context, state) => const ProgressScreen(),
      ),
    ],
  );
});
