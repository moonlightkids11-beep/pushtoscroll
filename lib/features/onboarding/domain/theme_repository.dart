import 'app_theme_mode.dart';

abstract class ThemeRepository {
  Future<AppThemeMode?> getSelectedTheme();
  Future<void> saveSelectedTheme(AppThemeMode theme);
}
