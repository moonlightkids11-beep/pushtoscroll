import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../di/providers.dart';
import '../domain/app_theme_mode.dart';
import '../domain/onboarding_repository.dart';
import '../domain/theme_repository.dart';
import 'theme_controller.dart';

class OnboardingState {
  final bool isCompleted;
  final bool isThemeSelected;
  final AppThemeMode? selectedTheme;

  const OnboardingState({
    required this.isCompleted,
    required this.isThemeSelected,
    this.selectedTheme,
  });

  OnboardingState copyWith({
    bool? isCompleted,
    bool? isThemeSelected,
    AppThemeMode? selectedTheme,
  }) {
    return OnboardingState(
      isCompleted: isCompleted ?? this.isCompleted,
      isThemeSelected: isThemeSelected ?? this.isThemeSelected,
      selectedTheme: selectedTheme ?? this.selectedTheme,
    );
  }
}

class OnboardingController extends Notifier<OnboardingState> {
  late final OnboardingRepository _onboardingRepository;
  late final ThemeRepository _themeRepository;

  @override
  OnboardingState build() {
    _onboardingRepository = ref.watch(onboardingRepositoryProvider);
    _themeRepository = ref.watch(themeRepositoryProvider);

    final isCompleted = ref.watch(initialOnboardingCompletedProvider);
    final selectedTheme = ref.watch(initialThemeModeProvider);

    return OnboardingState(
      isCompleted: isCompleted,
      isThemeSelected: selectedTheme != null,
      selectedTheme: selectedTheme,
    );
  }

  Future<void> selectTheme(AppThemeMode theme) async {
    state = state.copyWith(
      isThemeSelected: true,
      selectedTheme: theme,
    );
    await _themeRepository.saveSelectedTheme(theme);
    ref.read(themeControllerProvider.notifier).setTheme(theme);
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(isCompleted: true);
    await _onboardingRepository.setOnboardingCompleted(true);
  }
}

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingState>(
  OnboardingController.new,
);
