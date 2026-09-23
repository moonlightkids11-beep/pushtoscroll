import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:earn_your_scroll/features/onboarding/domain/app_theme_mode.dart';
import 'package:earn_your_scroll/main.dart';
import 'helpers/app_test_overrides.dart';

void main() {
  group('HomeScreen UI & Navigation Tests', () {
    testWidgets('Renders Samsung-lock-screen minimalist elements and navigates correctly',
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

      // 1. Verify Top/Middle: Large remaining time
      expect(find.text('00:00'), findsOneWidget);

      // 2. Verify TIME REMAINING label
      expect(find.text('TIME REMAINING'), findsOneWidget);

      // 3. Verify horizontal progress bar
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // 4. Verify Center: Large PUSH-UPS button and EARN TIME label
      expect(find.text('PUSH-UPS'), findsOneWidget);
      expect(find.text('EARN TIME'), findsOneWidget);

      // 5. Verify Bottom shortcuts and Top shortcut
      expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
      expect(find.byIcon(Icons.bar_chart_rounded), findsOneWidget);
      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);

      // 6. Test PUSH-UPS button navigation to /exercise
      await tester.tap(find.text('PUSH-UPS'));
      await tester.pumpAndSettle();
      expect(find.text('PUSH-UP CAMERA'), findsOneWidget);

      // Close exercise placeholder to return to home
      await tester.tap(find.byTooltip('Return Home'));
      await tester.pumpAndSettle();

      // 7. Test bottom-left camera shortcut navigation to /exercise
      await tester.tap(find.byIcon(Icons.camera_alt_outlined));
      await tester.pumpAndSettle();
      expect(find.text('PUSH-UP CAMERA'), findsOneWidget);

      await tester.tap(find.byTooltip('Return Home'));
      await tester.pumpAndSettle();

      // 8. Test bottom-right progress shortcut navigation to /progress
      await tester.tap(find.byIcon(Icons.bar_chart_rounded));
      await tester.pumpAndSettle();
      expect(find.text('PROGRESS & STATS'), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      // 9. Test top-right restricted apps navigation
      await tester.tap(find.byTooltip('Restricted Apps'));
      await tester.pumpAndSettle();
      expect(find.text('RESTRICTED APPS'), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('TIME REMAINING'), findsOneWidget);
    });
  });
}
