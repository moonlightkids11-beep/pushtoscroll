import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:earn_your_scroll/features/onboarding/domain/app_theme_mode.dart';
import 'package:earn_your_scroll/main.dart';
import '../helpers/app_test_overrides.dart';

void main() {
  Future<void> pumpCompletedApp(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
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
  }

  testWidgets('Home, blocked, and progress layouts fit a compact phone', (tester) async {
    await pumpCompletedApp(tester, const Size(360, 640));

    expect(tester.takeException(), isNull);
    expect(find.text('TIME REMAINING'), findsOneWidget);
    expect(find.text('PUSH-UPS'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.bar_chart_rounded));
    await tester.pumpAndSettle();
    expect(find.text('PROGRESS & STATS'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    final homeElement = tester.element(find.text('TIME REMAINING'));
    GoRouter.of(homeElement).go('/blocked');
    await tester.pumpAndSettle();

    expect(find.text('TIME EXPIRED'), findsOneWidget);
    expect(find.text('DO PUSH-UPS (+15s)'), findsOneWidget);
    expect(find.text('RETURN HOME'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home layout fits a wide desktop window', (tester) async {
    await pumpCompletedApp(tester, const Size(1280, 800));

    expect(tester.takeException(), isNull);
    expect(find.text('TIME REMAINING'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });
}
