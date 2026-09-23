import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/data/local_database.dart';
import '../features/onboarding/data/platform_permission_repository.dart';
import '../features/onboarding/data/shared_prefs_onboarding_repository.dart';
import '../features/onboarding/data/shared_prefs_theme_repository.dart';
import '../features/onboarding/domain/app_theme_mode.dart';
import '../features/onboarding/domain/onboarding_repository.dart';
import '../features/onboarding/domain/permission_repository.dart';
import '../features/onboarding/domain/theme_repository.dart';

import '../features/settings/domain/settings_repository.dart';
import '../features/settings/data/sqflite_settings_repository.dart';
import '../features/timer/domain/time_repository.dart';
import '../features/timer/data/sqflite_time_repository.dart';
import '../features/timer/domain/usecases/get_remaining_time_usecase.dart';
import '../features/timer/domain/usecases/consume_time_usecase.dart';
import '../features/timer/domain/usecases/earn_time_usecase.dart';
import '../features/timer/domain/reward_calculator.dart';
import '../features/timer/domain/timer_manager.dart';
import '../features/stats/domain/stats_repository.dart';
import '../features/stats/data/sqflite_stats_repository.dart';
import '../features/exercise/domain/pose/push_up_detector.dart';
import '../features/exercise/data/pose/google_mlkit_push_up_detector.dart';
import '../features/exercise/presentation/exercise_controller.dart';
import '../features/app_restriction/domain/restricted_app_repository.dart';
import '../features/app_restriction/data/platform_restricted_app_repository.dart';
import '../features/app_restriction/presentation/restricted_app_manager.dart';
import '../features/app_restriction/data/native_enforcement_service.dart';
import '../features/app_restriction/presentation/enforcement_controller.dart';
import '../core/utils/app_router.dart';
import 'package:go_router/go_router.dart';

/// Database provider
final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  return LocalDatabase();
});

/// SharedPreferences instance provider (injected in main)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

/// Initial preloaded values to prevent flash of wrong screen/theme
final initialThemeModeProvider = Provider<AppThemeMode?>((ref) => null);
final initialOnboardingCompletedProvider = Provider<bool>((ref) => false);

/// Onboarding and Theme repositories
final themeRepositoryProvider = Provider<ThemeRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SharedPrefsThemeRepository(prefs);
});

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SharedPrefsOnboardingRepository(prefs);
});

final permissionRepositoryProvider = Provider<PermissionRepository>((ref) {
  return PlatformPermissionRepository();
});

/// Core business domain repositories
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SqfliteSettingsRepository(ref.watch(localDatabaseProvider));
});

final timeRepositoryProvider = Provider<TimeRepository>((ref) {
  return SqfliteTimeRepository(ref.watch(localDatabaseProvider));
});

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return SqfliteStatsRepository(ref.watch(localDatabaseProvider));
});

final restrictedAppRepositoryProvider = Provider<RestrictedAppRepository>((ref) {
  return PlatformRestrictedAppRepository(
    settingsRepository: ref.watch(settingsRepositoryProvider),
  );
});

final restrictedAppManagerProvider = Provider<RestrictedAppManager>((ref) {
  final manager = RestrictedAppManager(ref.watch(restrictedAppRepositoryProvider));
  manager.loadApps();
  return manager;
});

final rewardCalculatorProvider = Provider<RewardCalculator>((ref) {
  return RewardCalculator();
});

final getRemainingTimeUseCaseProvider = Provider<GetRemainingTimeUseCase>((ref) {
  return GetRemainingTimeUseCase(ref.watch(timeRepositoryProvider));
});

final consumeTimeUseCaseProvider = Provider<ConsumeTimeUseCase>((ref) {
  return ConsumeTimeUseCase(ref.watch(timeRepositoryProvider));
});

final earnTimeUseCaseProvider = Provider<EarnTimeUseCase>((ref) {
  return EarnTimeUseCase(
    ref.watch(timeRepositoryProvider),
    ref.watch(rewardCalculatorProvider),
  );
});

final timerManagerProvider = Provider<TimerManager>((ref) {
  final manager = TimerManager(
    ref.watch(getRemainingTimeUseCaseProvider),
    ref.watch(consumeTimeUseCaseProvider),
    ref.watch(sharedPreferencesProvider),
  );
  manager.initialize();
  ref.onDispose(manager.dispose);
  return manager;
});

final pushUpDetectorProvider = Provider<PushUpDetector>((ref) {
  return GoogleMlKitPushUpDetector();
});

final exerciseControllerProvider = Provider<ExerciseController>((ref) {
  return ExerciseController(
    detector: ref.watch(pushUpDetectorProvider),
    earnTimeUseCase: ref.watch(earnTimeUseCaseProvider),
    rewardCalculator: ref.watch(rewardCalculatorProvider),
    statsRepository: ref.watch(statsRepositoryProvider),
    timerManager: ref.watch(timerManagerProvider),
  );
});

final nativeEnforcementServiceProvider = Provider<NativeEnforcementService>((ref) {
  return NativeEnforcementService();
});


final enforcementControllerProvider = Provider<EnforcementController>((ref) {
  final controller = EnforcementController(
    ref.watch(timerManagerProvider),
    ref.watch(restrictedAppManagerProvider),
    ref.watch(nativeEnforcementServiceProvider),
    ref.watch(consumeTimeUseCaseProvider),
    ref.watch(permissionRepositoryProvider),
  );
  
  // Use Future.microtask to avoid reading provider during initialization phase
  Future.microtask(() {
    controller.onShowBlockedScreen = () {
      final context = rootNavigatorKey.currentContext;
      if (context != null) {
        GoRouter.of(context).go('/blocked');
      }
    };
  });
  
  return controller;
});