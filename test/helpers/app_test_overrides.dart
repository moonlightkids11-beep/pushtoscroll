import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:earn_your_scroll/core/data/local_database.dart';
import 'package:earn_your_scroll/di/providers.dart';
import 'package:earn_your_scroll/features/app_restriction/domain/installed_app.dart';
import 'package:earn_your_scroll/features/app_restriction/domain/restricted_app.dart';
import 'package:earn_your_scroll/features/app_restriction/domain/restricted_app_repository.dart';
import 'package:earn_your_scroll/features/onboarding/domain/app_theme_mode.dart';

/// A no-op repository used in widget tests to avoid real MethodChannel calls
/// (and the 500 ms timeout timer they create in the FakeAsync environment).
class _NoOpRestrictedAppRepository implements RestrictedAppRepository {
  @override
  Future<List<InstalledApp>> getInstalledApps() async => [];

  @override
  Future<List<String>> getRestrictedPackageNames() async => [];

  @override
  Future<void> saveRestrictedPackageNames(List<String> packageNames) async {}

  @override
  Future<List<RestrictedApp>> getRestrictedApps() async => [];
}

List<Override> earnYourScrollTestOverrides({
  required SharedPreferences prefs,
  AppThemeMode? theme,
  bool onboardingCompleted = false,
}) {
  return [
    sharedPreferencesProvider.overrideWithValue(prefs),
    initialThemeModeProvider.overrideWithValue(theme),
    initialOnboardingCompletedProvider.overrideWithValue(onboardingCompleted),
    localDatabaseProvider.overrideWithValue(LocalDatabase(inMemory: true)),
    restrictedAppRepositoryProvider
        .overrideWithValue(_NoOpRestrictedAppRepository()),
  ];
}
