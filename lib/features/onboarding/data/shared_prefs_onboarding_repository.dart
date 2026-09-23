import 'package:shared_preferences/shared_preferences.dart';
import '../domain/onboarding_repository.dart';

class SharedPrefsOnboardingRepository implements OnboardingRepository {
  static const String _completedKey = 'is_onboarding_completed';
  final SharedPreferences _preferences;

  SharedPrefsOnboardingRepository(this._preferences);

  @override
  Future<bool> isOnboardingCompleted() async {
    return _preferences.getBool(_completedKey) ?? false;
  }

  @override
  Future<void> setOnboardingCompleted(bool completed) async {
    await _preferences.setBool(_completedKey, completed);
  }
}
