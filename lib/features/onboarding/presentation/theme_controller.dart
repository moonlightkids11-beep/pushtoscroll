import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../di/providers.dart';
import '../domain/app_theme_mode.dart';
import '../domain/theme_repository.dart';

class ThemeController extends Notifier<AppThemeMode> {
  late final ThemeRepository _repository;

  @override
  AppThemeMode build() {
    _repository = ref.watch(themeRepositoryProvider);
    final initial = ref.watch(initialThemeModeProvider);
    return initial ?? AppThemeMode.blackAndWhite;
  }

  Future<void> setTheme(AppThemeMode mode) async {
    state = mode;
    await _repository.saveSelectedTheme(mode);
  }
}

final themeControllerProvider = NotifierProvider<ThemeController, AppThemeMode>(
  ThemeController.new,
);
