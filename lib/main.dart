import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'core/utils/app_router.dart';
import 'di/providers.dart';
import 'features/onboarding/data/shared_prefs_onboarding_repository.dart';
import 'features/onboarding/data/shared_prefs_theme_repository.dart';
import 'features/onboarding/domain/app_theme_mode.dart';
import 'features/onboarding/presentation/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();

  final themeRepo = SharedPrefsThemeRepository(preferences);
  final initialTheme = await themeRepo.getSelectedTheme();

  final onboardingRepo = SharedPrefsOnboardingRepository(preferences);
  final initialOnboardingCompleted = await onboardingRepo.isOnboardingCompleted();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        initialThemeModeProvider.overrideWithValue(initialTheme),
        initialOnboardingCompletedProvider.overrideWithValue(initialOnboardingCompleted),
      ],
      child: const EarnYourScrollApp(),
    ),
  );
}

class EarnYourScrollApp extends ConsumerWidget {
  const EarnYourScrollApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize the enforcement controller to start listening to state changes
    ref.watch(enforcementControllerProvider);
    
    final themeMode = ref.watch(themeControllerProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Earn Your Scroll',
      theme: themeMode == AppThemeMode.defaultTheme
          ? AppTheme.defaultTheme
          : AppTheme.blackAndWhite,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
