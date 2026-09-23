import 'package:sqflite/sqflite.dart';
import '../../../core/data/local_database.dart';
import '../domain/settings_repository.dart';
import '../domain/user_settings.dart';
import 'models/user_settings_model.dart';

class SqfliteSettingsRepository implements SettingsRepository {
  final LocalDatabase _localDatabase;

  SqfliteSettingsRepository(this._localDatabase);

  @override
  Future<UserSettings> getUserSettings() async {
    try {
      final db = await _localDatabase.database;
      final result = await db.query(
        'user_settings',
        where: 'id = ?',
        whereArgs: [1],
      );

      if (result.isNotEmpty) {
        return UserSettingsModel.fromMap(result.first);
      } else {
        // Return defaults and save
        const defaultSettings = UserSettings(
          selectedTheme: 'default',
          selectedRestrictedApps: [],
          rewardRate: 15,
        );
        await updateUserSettings(defaultSettings);
        return defaultSettings;
      }
    } catch (e) {
      // Handle corrupted data by returning defaults
      return const UserSettings(
        selectedTheme: 'default',
        selectedRestrictedApps: [],
        rewardRate: 15,
      );
    }
  }

  @override
  Future<void> updateUserSettings(UserSettings settings) async {
    final db = await _localDatabase.database;
    final model = UserSettingsModel.fromEntity(settings);
    
    await db.insert(
      'user_settings',
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateTheme(String theme) async {
    final settings = await getUserSettings();
    await updateUserSettings(settings.copyWith(selectedTheme: theme));
  }

  @override
  Future<void> updateRestrictedApps(List<String> apps) async {
    final settings = await getUserSettings();
    await updateUserSettings(settings.copyWith(selectedRestrictedApps: apps));
  }

  @override
  Future<void> updateRewardRate(int rate) async {
    final settings = await getUserSettings();
    await updateUserSettings(settings.copyWith(rewardRate: rate));
  }
}
