import 'user_settings.dart';

abstract class SettingsRepository {
  Future<UserSettings> getUserSettings();
  Future<void> updateUserSettings(UserSettings settings);
  Future<void> updateTheme(String theme);
  Future<void> updateRestrictedApps(List<String> apps);
  Future<void> updateRewardRate(int rate);
}
