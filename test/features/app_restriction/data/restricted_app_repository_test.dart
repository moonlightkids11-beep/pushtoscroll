import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:earn_your_scroll/features/app_restriction/data/platform_restricted_app_repository.dart';
import 'package:earn_your_scroll/features/settings/domain/settings_repository.dart';
import 'package:earn_your_scroll/features/settings/domain/user_settings.dart';

class FakeSettingsRepository implements SettingsRepository {
  UserSettings _settings = const UserSettings(
    selectedTheme: 'default',
    selectedRestrictedApps: [],
    rewardRate: 15,
  );

  @override
  Future<UserSettings> getUserSettings() async => _settings;

  @override
  Future<void> updateUserSettings(UserSettings settings) async {
    _settings = settings;
  }

  @override
  Future<void> updateTheme(String theme) async {
    _settings = _settings.copyWith(selectedTheme: theme);
  }

  @override
  Future<void> updateRestrictedApps(List<String> apps) async {
    _settings = _settings.copyWith(selectedRestrictedApps: apps);
  }

  @override
  Future<void> updateRewardRate(int rate) async {
    _settings = _settings.copyWith(rewardRate: rate);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlatformRestrictedAppRepository', () {
    late FakeSettingsRepository settingsRepo;
    late MethodChannel channel;
    late PlatformRestrictedAppRepository repository;

    final mockPlatformApps = [
      {'packageName': 'com.zhiliaoapp.musically', 'name': 'TikTok', 'icon': null},
      {'packageName': 'com.instagram.android', 'name': 'Instagram', 'icon': null},
      {'packageName': 'com.google.android.youtube', 'name': 'YouTube', 'icon': null},
      {'packageName': 'com.whatsapp', 'name': 'WhatsApp', 'icon': null},
    ];

    setUp(() {
      settingsRepo = FakeSettingsRepository();
      channel = const MethodChannel('com.example.earnyourscroll/app_restriction_test');

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'getInstalledApps') {
          return mockPlatformApps;
        }
        return null;
      });

      repository = PlatformRestrictedAppRepository(
        settingsRepository: settingsRepo,
        channel: channel,
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('getInstalledApps retrieves installed apps via MethodChannel', () async {
      final apps = await repository.getInstalledApps();
      expect(apps.length, 4);
      expect(apps[0].packageName, 'com.zhiliaoapp.musically');
      expect(apps[0].name, 'TikTok');
    });

    test('getRestrictedPackageNames and saveRestrictedPackageNames persist correctly', () async {
      expect(await repository.getRestrictedPackageNames(), isEmpty);

      await repository.saveRestrictedPackageNames(['com.instagram.android', 'com.zhiliaoapp.musically']);

      final saved = await repository.getRestrictedPackageNames();
      expect(saved, containsAll(['com.instagram.android', 'com.zhiliaoapp.musically']));
    });

    test('getRestrictedApps maps isRestricted correctly', () async {
      await repository.saveRestrictedPackageNames(['com.zhiliaoapp.musically']);

      final apps = await repository.getRestrictedApps();
      expect(apps.length, 4);

      final tiktok = apps.firstWhere((a) => a.packageName == 'com.zhiliaoapp.musically');
      final youtube = apps.firstWhere((a) => a.packageName == 'com.google.android.youtube');

      expect(tiktok.isRestricted, isTrue);
      expect(youtube.isRestricted, isFalse);
    });

    test('handles uninstalled apps gracefully and cleans up dead package names', () async {
      // User had an old app restricted that is no longer in mockPlatformApps
      await repository.saveRestrictedPackageNames([
        'com.zhiliaoapp.musically',
        'com.deleted.app', // Uninstalled app
      ]);

      final apps = await repository.getRestrictedApps();
      // Should return only 4 installed apps
      expect(apps.length, 4);
      expect(apps.any((a) => a.packageName == 'com.deleted.app'), isFalse);

      // The uninstalled app should have been pruned from persisted storage
      final updatedPersisted = await repository.getRestrictedPackageNames();
      expect(updatedPersisted, equals(['com.zhiliaoapp.musically']));
      expect(updatedPersisted.contains('com.deleted.app'), isFalse);
    });

    test('handles channel errors gracefully by returning empty list', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        throw PlatformException(code: 'ERROR', message: 'Permission denied');
      });

      final apps = await repository.getInstalledApps();
      expect(apps, isEmpty);
    });
  });
}
