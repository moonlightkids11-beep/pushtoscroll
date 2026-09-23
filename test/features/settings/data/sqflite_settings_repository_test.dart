import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:earn_your_scroll/core/data/local_database.dart';
import 'package:earn_your_scroll/features/settings/data/sqflite_settings_repository.dart';
import 'package:earn_your_scroll/features/settings/domain/user_settings.dart';

void main() {
  late LocalDatabase localDatabase;
  late SqfliteSettingsRepository repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    localDatabase = LocalDatabase(inMemory: true);
    repository = SqfliteSettingsRepository(localDatabase);
  });

  tearDown(() async {
    await localDatabase.close();
  });

  test('getUserSettings returns default when empty', () async {
    final settings = await repository.getUserSettings();
    expect(settings.selectedTheme, 'default');
    expect(settings.selectedRestrictedApps, isEmpty);
    expect(settings.rewardRate, 15);
  });

  test('updateUserSettings saves and retrieves correctly', () async {
    const newSettings = UserSettings(
      selectedTheme: 'dark',
      selectedRestrictedApps: ['com.example.app'],
      rewardRate: 30,
    );

    await repository.updateUserSettings(newSettings);
    final retrieved = await repository.getUserSettings();

    expect(retrieved.selectedTheme, 'dark');
    expect(retrieved.selectedRestrictedApps, ['com.example.app']);
    expect(retrieved.rewardRate, 30);
  });

  test('getUserSettings recovers from corrupt restricted apps JSON', () async {
    await repository.updateUserSettings(
      const UserSettings(
        selectedTheme: 'dark',
        selectedRestrictedApps: ['com.example.app'],
        rewardRate: 15,
      ),
    );
    final db = await localDatabase.database;
    await db.update(
      'user_settings',
      {
        'selected_theme': 'dark',
        'selected_restricted_apps': '{broken',
        'reward_rate': -1,
      },
      where: 'id = ?',
      whereArgs: [1],
    );

    final settings = await repository.getUserSettings();
    expect(settings.selectedRestrictedApps, isEmpty);
    expect(settings.rewardRate, 15);
  });
}
