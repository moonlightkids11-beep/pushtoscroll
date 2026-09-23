import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:earn_your_scroll/features/onboarding/domain/app_theme_mode.dart';
import 'package:earn_your_scroll/main.dart';
import 'helpers/app_test_overrides.dart';

void main() {
  group('Complete MVP Navigation Architecture Tests', () {
    testWidgets('Home -> Exercise, Progress, Restricted Apps, and return home',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

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

      // 1. Verify Home screen
      expect(find.text('TIME REMAINING'), findsOneWidget);

      // 2. Home -> Push-Up Exercise
      await tester.tap(find.text('PUSH-UPS'));
      await tester.pumpAndSettle();
      expect(find.text('PUSH-UP CAMERA'), findsOneWidget);

      // 3. Exercise -> Home via FINISH & RETURN HOME button
      await tester.tap(find.text('FINISH & RETURN HOME'));
      await tester.pumpAndSettle();
      expect(find.text('TIME REMAINING'), findsOneWidget);

      // 4. Home -> Progress
      await tester.tap(find.byIcon(Icons.bar_chart_rounded));
      await tester.pumpAndSettle();
      expect(find.text('PROGRESS & STATS'), findsOneWidget);

      // Back navigation from Progress -> Home
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('TIME REMAINING'), findsOneWidget);

      // 5. Home -> Restricted Apps
      await tester.tap(find.byTooltip('Restricted Apps'));
      await tester.pumpAndSettle();
      expect(find.text('RESTRICTED APPS'), findsOneWidget);

      // Back navigation from Restricted Apps -> Home
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('TIME REMAINING'), findsOneWidget);
    });

    testWidgets('Blocked Screen -> Push-Up Exercise and Return Home',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

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

      // Navigate to /blocked
      final homeElement = tester.element(find.text('TIME REMAINING'));
      GoRouter.of(homeElement).go('/blocked');
      await tester.pumpAndSettle();

      // Verify on Blocked Screen
      expect(find.text('TIME EXPIRED'), findsOneWidget);
      expect(find.text('DO PUSH-UPS (+15s)'), findsOneWidget);

      // Blocked Screen -> Push-Up Exercise
      await tester.tap(find.text('DO PUSH-UPS (+15s)'));
      await tester.pumpAndSettle();
      expect(find.text('PUSH-UP CAMERA'), findsOneWidget);

      // Return home
      await tester.tap(find.byTooltip('Return Home'));
      await tester.pumpAndSettle();
      expect(find.text('TIME REMAINING'), findsOneWidget);
    });

    testWidgets('Initial launch starts at ThemeSelectionScreen',
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
      expect(find.text('Choose Your Theme'), findsOneWidget);
    });

    testWidgets('Restart with theme chosen resumes at PermissionSetupScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({
        'selected_app_theme': 'blackAndWhite',
        'is_onboarding_completed': false,
      });
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: earnYourScrollTestOverrides(
            prefs: prefs,
            theme: AppThemeMode.blackAndWhite,
          ),
          child: const EarnYourScrollApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Setup Permissions'), findsOneWidget);
    });

    testWidgets('Restart after completed onboarding resumes directly at HomeScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

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
      expect(find.text('TIME REMAINING'), findsOneWidget);
    });
  });
}
