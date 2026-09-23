import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:earn_your_scroll/di/providers.dart';
import 'package:earn_your_scroll/features/app_restriction/domain/installed_app.dart';
import 'package:earn_your_scroll/features/app_restriction/domain/restricted_app.dart';
import 'package:earn_your_scroll/features/app_restriction/domain/restricted_app_repository.dart';
import 'package:earn_your_scroll/features/app_restriction/presentation/restricted_app_manager.dart';
import 'package:earn_your_scroll/features/app_restriction/presentation/restricted_apps_screen.dart';

class MockRestrictedAppRepository implements RestrictedAppRepository {
  List<InstalledApp> installed = [
    const InstalledApp(packageName: 'com.zhiliaoapp.musically', name: 'TikTok'),
    const InstalledApp(packageName: 'com.instagram.android', name: 'Instagram'),
    const InstalledApp(packageName: 'com.google.android.youtube', name: 'YouTube'),
    const InstalledApp(packageName: 'com.whatsapp', name: 'WhatsApp'),
    const InstalledApp(packageName: 'com.android.chrome', name: 'Chrome'),
  ];

  List<String> restrictedPackages = ['com.zhiliaoapp.musically'];

  @override
  Future<List<InstalledApp>> getInstalledApps() async => installed;

  @override
  Future<List<String>> getRestrictedPackageNames() async => restrictedPackages;

  @override
  Future<void> saveRestrictedPackageNames(List<String> packageNames) async {
    restrictedPackages = List.from(packageNames);
  }

  @override
  Future<List<RestrictedApp>> getRestrictedApps() async {
    return installed.map((app) {
      return RestrictedApp(
        packageName: app.packageName,
        name: app.name,
        iconBytes: app.iconBytes,
        isRestricted: restrictedPackages.contains(app.packageName),
      );
    }).toList();
  }
}

void main() {
  testWidgets('RestrictedAppsScreen displays apps and toggles selection', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final mockRepo = MockRestrictedAppRepository();
    final manager = RestrictedAppManager(mockRepo);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          restrictedAppRepositoryProvider.overrideWithValue(mockRepo),
          restrictedAppManagerProvider.overrideWithValue(manager),
        ],
        child: const MaterialApp(
          home: RestrictedAppsScreen(),
        ),
      ),
    );

    // Initial frame loads apps
    await tester.pumpAndSettle();

    // Verify Title & Header
    expect(find.text('RESTRICTED APPS'), findsOneWidget);
    expect(find.text('1 RESTRICTED'), findsOneWidget);

    // Verify Apps are displayed
    expect(find.text('TikTok'), findsOneWidget);
    expect(find.text('Instagram'), findsOneWidget);
    expect(find.text('YouTube'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text('Chrome'), findsOneWidget);

    // Tap on YouTube to restrict it
    await tester.tap(find.text('YouTube'));
    await tester.pumpAndSettle();

    expect(find.text('2 RESTRICTED'), findsOneWidget);
    expect(mockRepo.restrictedPackages, contains('com.google.android.youtube'));

    // Test Search filter
    await tester.enterText(find.byType(TextField), 'Whats');
    await tester.pumpAndSettle();

    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text('TikTok'), findsNothing);
    expect(find.text('Instagram'), findsNothing);

    // Clear search
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();

    expect(find.text('TikTok'), findsOneWidget);
    expect(find.text('Instagram'), findsOneWidget);

    // Test SELECT ALL
    await tester.tap(find.text('SELECT ALL'));
    await tester.pumpAndSettle();

    expect(find.text('5 RESTRICTED'), findsOneWidget);

    // Test CLEAR ALL
    await tester.tap(find.text('CLEAR ALL'));
    await tester.pumpAndSettle();

    expect(find.text('0 RESTRICTED'), findsOneWidget);
  });
}
