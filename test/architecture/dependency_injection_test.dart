import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:earn_your_scroll/core/data/local_database.dart';
import 'package:earn_your_scroll/di/providers.dart';
import 'package:earn_your_scroll/features/settings/domain/settings_repository.dart';
import 'package:earn_your_scroll/features/stats/domain/stats_repository.dart';
import 'package:earn_your_scroll/features/timer/data/sqflite_time_repository.dart';
import 'package:earn_your_scroll/features/timer/domain/time_repository.dart';
import 'package:earn_your_scroll/features/timer/domain/usecases/get_remaining_time_usecase.dart';

import '../features/timer/domain/reward_engine_test.dart';

void main() {
  test('DI wires abstract repositories and allows substitution', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final fakeTime = FakeTimeRepository()..remaining = 45;

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        localDatabaseProvider.overrideWithValue(LocalDatabase(inMemory: true)),
        timeRepositoryProvider.overrideWithValue(fakeTime),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(timeRepositoryProvider), same(fakeTime));
    expect(container.read(settingsRepositoryProvider), isA<SettingsRepository>());
    expect(container.read(statsRepositoryProvider), isA<StatsRepository>());
    expect(container.read(getRemainingTimeUseCaseProvider), isA<GetRemainingTimeUseCase>());
    expect(await container.read(getRemainingTimeUseCaseProvider).execute(), 45);
  });

  test('default time repository stays behind the TimeRepository boundary', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        localDatabaseProvider.overrideWithValue(LocalDatabase(inMemory: true)),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(timeRepositoryProvider), isA<SqfliteTimeRepository>());
    expect(container.read(timeRepositoryProvider), isA<TimeRepository>());
  });
}
