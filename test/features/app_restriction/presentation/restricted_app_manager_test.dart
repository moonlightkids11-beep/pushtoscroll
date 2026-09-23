import 'package:flutter_test/flutter_test.dart';
import 'package:earn_your_scroll/features/app_restriction/domain/installed_app.dart';
import 'package:earn_your_scroll/features/app_restriction/domain/restricted_app.dart';
import 'package:earn_your_scroll/features/app_restriction/domain/restricted_app_repository.dart';
import 'package:earn_your_scroll/features/app_restriction/presentation/restricted_app_manager.dart';

class FakeRestrictedAppRepository implements RestrictedAppRepository {
  List<InstalledApp> installed = [
    const InstalledApp(packageName: 'com.zhiliaoapp.musically', name: 'TikTok'),
    const InstalledApp(packageName: 'com.instagram.android', name: 'Instagram'),
    const InstalledApp(packageName: 'com.google.android.youtube', name: 'YouTube'),
    const InstalledApp(packageName: 'com.whatsapp', name: 'WhatsApp'),
    const InstalledApp(packageName: 'com.android.chrome', name: 'Chrome'),
  ];

  List<String> restrictedPackages = ['com.zhiliaoapp.musically'];
  bool shouldThrow = false;

  @override
  Future<List<InstalledApp>> getInstalledApps() async {
    if (shouldThrow) throw Exception('Permission error');
    return installed;
  }

  @override
  Future<List<String>> getRestrictedPackageNames() async {
    return restrictedPackages;
  }

  @override
  Future<void> saveRestrictedPackageNames(List<String> packageNames) async {
    restrictedPackages = List.from(packageNames);
  }

  @override
  Future<List<RestrictedApp>> getRestrictedApps() async {
    if (shouldThrow) throw Exception('Permission error');
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
  group('RestrictedAppManager', () {
    late FakeRestrictedAppRepository repository;
    late RestrictedAppManager manager;

    setUp(() {
      repository = FakeRestrictedAppRepository();
      manager = RestrictedAppManager(repository);
    });

    test('initial state is clean', () {
      expect(manager.apps, isEmpty);
      expect(manager.selectedPackageNames, isEmpty);
      expect(manager.isLoading, isFalse);
      expect(manager.errorMessage, isNull);
    });

    test('loadApps loads installed apps and restricted state', () async {
      await manager.loadApps();

      expect(manager.isLoading, isFalse);
      expect(manager.apps.length, 5);
      expect(manager.restrictedCount, 1);
      expect(manager.selectedPackageNames.contains('com.zhiliaoapp.musically'), isTrue);
    });

    test('toggleAppRestriction updates state and persists', () async {
      await manager.loadApps();

      // Add Instagram
      await manager.toggleAppRestriction('com.instagram.android');
      expect(manager.selectedPackageNames.contains('com.instagram.android'), isTrue);
      expect(manager.restrictedCount, 2);
      expect(repository.restrictedPackages, contains('com.instagram.android'));

      // Remove TikTok
      await manager.toggleAppRestriction('com.zhiliaoapp.musically');
      expect(manager.selectedPackageNames.contains('com.zhiliaoapp.musically'), isFalse);
      expect(manager.restrictedCount, 1);
      expect(repository.restrictedPackages.contains('com.zhiliaoapp.musically'), isFalse);
    });

    test('selectAll and clearAll work and persist', () async {
      await manager.loadApps();

      await manager.selectAll();
      expect(manager.restrictedCount, 5);
      expect(repository.restrictedPackages.length, 5);

      await manager.clearAll();
      expect(manager.restrictedCount, 0);
      expect(repository.restrictedPackages, isEmpty);
    });

    test('filteredApps filters correctly by search query', () async {
      await manager.loadApps();

      manager.setSearchQuery('you');
      expect(manager.filteredApps.length, 1);
      expect(manager.filteredApps.first.name, 'YouTube');

      manager.setSearchQuery('gram');
      expect(manager.filteredApps.length, 1);
      expect(manager.filteredApps.first.name, 'Instagram');

      manager.setSearchQuery('');
      expect(manager.filteredApps.length, 5);
    });

    test('handles error gracefully when loading apps fails', () async {
      repository.shouldThrow = true;
      await manager.loadApps();

      expect(manager.isLoading, isFalse);
      expect(manager.apps, isEmpty);
      expect(manager.errorMessage, isNotNull);
    });
  });
}
