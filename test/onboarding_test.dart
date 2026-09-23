import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:earn_your_scroll/features/onboarding/data/platform_permission_repository.dart';
import 'package:earn_your_scroll/features/onboarding/data/shared_prefs_onboarding_repository.dart';
import 'package:earn_your_scroll/features/onboarding/data/shared_prefs_theme_repository.dart';
import 'package:earn_your_scroll/features/onboarding/domain/app_theme_mode.dart';
import 'package:earn_your_scroll/features/onboarding/domain/permission_state.dart';
import 'package:earn_your_scroll/features/onboarding/domain/permission_type.dart';
import 'package:earn_your_scroll/main.dart';
import 'helpers/app_test_overrides.dart';

void main() {
  group('Theme and Onboarding Persistence Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('SharedPrefsThemeRepository saves and retrieves theme correctly', () async {
      final repo = SharedPrefsThemeRepository(prefs);

      expect(await repo.getSelectedTheme(), isNull);

      await repo.saveSelectedTheme(AppThemeMode.blackAndWhite);
      expect(await repo.getSelectedTheme(), AppThemeMode.blackAndWhite);

      await repo.saveSelectedTheme(AppThemeMode.defaultTheme);
      expect(await repo.getSelectedTheme(), AppThemeMode.defaultTheme);
    });

    test('SharedPrefsOnboardingRepository persists completion state', () async {
      final repo = SharedPrefsOnboardingRepository(prefs);

      expect(await repo.isOnboardingCompleted(), isFalse);

      await repo.setOnboardingCompleted(true);
      expect(await repo.isOnboardingCompleted(), isTrue);
    });

    test('PlatformPermissionRepository never claims permission granted on non-Android test runner', () async {
      final repo = PlatformPermissionRepository();

      for (final type in AppPermissionType.values) {
        final status = await repo.checkPermission(type);
        expect(status, PermissionState.denied, reason: '$type should not fake granted');
      }
    });
  });

  group('Onboarding Navigation Flow Widget Tests', () {
    testWidgets('First launch displays ThemeSelectionScreen and navigates to PermissionSetupScreen and Home',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: earnYourScrollTestOverrides(
            prefs: prefs,
          ),
          child: const EarnYourScrollApp(),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify on ThemeSelectionScreen
      expect(find.text('Choose Your Theme'), findsOneWidget);
      expect(find.text('DEFAULT THEME'), findsOneWidget);
      expect(find.text('OUR THEME'), findsOneWidget);

      // 2. Select OUR THEME (Black & White)
      await tester.tap(find.text('OUR THEME'));
      await tester.pumpAndSettle();

      // 3. Tap CONTINUE to navigate to PermissionSetupScreen
      await tester.tap(find.text('CONTINUE'));
      await tester.pumpAndSettle();

      // 4. Verify on PermissionSetupScreen
      expect(find.text('Setup Permissions'), findsOneWidget);
      expect(find.text('CAMERA'), findsOneWidget);
      expect(find.text('Used for on-device pose detection to analyze push-up form.'), findsOneWidget);

      expect(find.text('USAGE ACCESS'), findsOneWidget);
      expect(find.text('Used to identify selected restricted apps and measure screen time.'), findsOneWidget);

      expect(find.text('ACCESSIBILITY'), findsOneWidget);
      expect(
        find.text('Required on Android to reliably detect foreground restricted apps and display the focus intervention screen.'),
        findsOneWidget,
      );

      // Permissions should be reported as NOT GRANTED (never faked)
      expect(find.text('NOT GRANTED'), findsNWidgets(3));

      // 5. Tap FINISH & START EARNING
      await tester.tap(find.text('FINISH & START EARNING'));
      await tester.pumpAndSettle();

      // Confirmation dialog shows up because permissions are not granted
      expect(find.text('Permissions Incomplete'), findsOneWidget);

      // Tap PROCEED ANYWAY
      await tester.tap(find.text('PROCEED ANYWAY'));
      await tester.pumpAndSettle();

      // 6. Verify we have landed on HomeScreen
      expect(find.text('TIME REMAINING'), findsOneWidget);
      expect(find.text('PUSH-UPS'), findsOneWidget);
    });

    testWidgets('Subsequent launch with completed onboarding opens HomeScreen directly',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'selected_app_theme': 'blackAndWhite',
        'is_onboarding_completed': true,
      });
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: earnYourScrollTestOverrides(
            prefs: prefs,
            theme: AppThemeMode.blackAndWhite,
            onboardingCompleted: true,
          ),
          child: const EarnYourScrollApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Should open directly to HomeScreen
      expect(find.text('TIME REMAINING'), findsOneWidget);
      expect(find.text('Choose Your Theme'), findsNothing);
      expect(find.text('Setup Permissions'), findsNothing);
    });
  });
}
