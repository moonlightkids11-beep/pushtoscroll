import 'package:shared_preferences/shared_preferences.dart';
import '../domain/app_theme_mode.dart';
import '../domain/theme_repository.dart';

class SharedPrefsThemeRepository implements ThemeRepository {
  static const String _themeKey = 'selected_app_theme';
  final SharedPreferences _preferences;

  SharedPrefsThemeRepository(this._preferences);

  @override
  Future<AppThemeMode?> getSelectedTheme() async {
    final value = _preferences.getString(_themeKey);
    if (value == null) return null;
    switch (value) {
      case 'blackAndWhite':
        return AppThemeMode.blackAndWhite;
      case 'defaultTheme':
        return AppThemeMode.defaultTheme;
      default:
        return null;
    }
  }

  @override
  Future<void> saveSelectedTheme(AppThemeMode theme) async {
    final value = theme == AppThemeMode.blackAndWhite ? 'blackAndWhite' : 'defaultTheme';
    await _preferences.setString(_themeKey, value);
  }
}
