import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:earn_your_scroll/features/timer/domain/reward_calculator.dart';
import 'package:earn_your_scroll/features/timer/domain/usecases/earn_time_usecase.dart';
import 'package:earn_your_scroll/features/timer/domain/usecases/consume_time_usecase.dart';
import 'package:earn_your_scroll/features/timer/domain/usecases/get_remaining_time_usecase.dart';
import 'package:earn_your_scroll/features/timer/domain/timer_manager.dart';
import 'package:earn_your_scroll/features/timer/domain/time_repository.dart';
import 'package:earn_your_scroll/features/timer/domain/time_ledger.dart';

class FakeTimeRepository implements TimeRepository {
  int earned = 0;
  int used = 0;
  int remaining = 0;

  @override
  Future<void> addEarnedTime(int seconds) async {
    earned += seconds;
    remaining += seconds;
  }

  @override
  Future<void> consumeTime(int seconds) async {
    final actual = seconds > remaining ? remaining : seconds;
    used += actual;
    remaining -= actual;
  }

  @override
  Future<int> getAvailableTime() async => remaining;
  
  @override
  Future<TimeLedger> getTimeLedger() async {
    return TimeLedger(
      earnedSeconds: earned,
      usedSeconds: used,
      remainingSeconds: remaining,
      lastUpdated: DateTime.now(),
    );
  }
}

void main() {
  group('RewardCalculator', () {
    test('calculateReward returns 15s per push-up', () {
      final calculator = RewardCalculator();
      expect(calculator.calculateReward(1), 15);
      expect(calculator.calculateReward(10), 150);
      expect(calculator.calculateReward(20), 300);
      expect(calculator.calculateReward(40), 600);
    });

    test('calculateReward zero or negative', () {
      final calculator = RewardCalculator();
      expect(calculator.calculateReward(0), 0);
      expect(calculator.calculateReward(-5), 0);
    });
  });

  group('Use Cases', () {
    late FakeTimeRepository repo;

    setUp(() {
      repo = FakeTimeRepository();
    });

    test('EarnTimeUseCase accumulates properly', () async {
      final usecase = EarnTimeUseCase(repo, RewardCalculator());
      
      await usecase.execute(10); // 150s
      expect(repo.remaining, 150);

      await usecase.execute(2); // 30s
      expect(repo.remaining, 180);
    });

    test('ConsumeTimeUseCase prevents negative time (zero time)', () async {
      final earn = EarnTimeUseCase(repo, RewardCalculator());
      final consume = ConsumeTimeUseCase(repo);
      
      await earn.execute(2); // 30s
      
      await consume.execute(10);
      expect(repo.remaining, 20);

      await consume.execute(30); // Try to consume more than available
      expect(repo.remaining, 0); // Stops at zero
    });

    test('EarnTimeUseCase ignores duplicate zero-delta events', () async {
      final usecase = EarnTimeUseCase(repo, RewardCalculator());
      expect(await usecase.execute(0), 0);
      expect(repo.remaining, 0);
      expect(await usecase.execute(-2), 0);
      expect(repo.remaining, 0);
    });
  });

  group('TimerManager', () {
    late FakeTimeRepository repo;
    late TimerManager manager;

    setUp(() {
      repo = FakeTimeRepository();
      SharedPreferences.setMockInitialValues({});
    });

    test('restart/recovery - background time correctly calculated', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      
      repo.remaining = 100; // Mock existing time
      
      // Simulate app killed while running 10 seconds ago
      final tenSecondsAgo = DateTime.now().subtract(const Duration(seconds: 10)).millisecondsSinceEpoch;
      prefs.setBool('timer_was_running', true);
      prefs.setInt('timer_start_timestamp', tenSecondsAgo);

      manager = TimerManager(
        GetRemainingTimeUseCase(repo),
        ConsumeTimeUseCase(repo),
        prefs,
      );

      await manager.initialize();
      
      // The 10 seconds passed should have been consumed
      expect(repo.remaining, 90);
      expect(manager.remainingSeconds, 90);
      expect(manager.isRunning, true); // It auto-resumes since time is left
    });

    test('timer expiration - timer stops when reaching zero', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      
      repo.remaining = 5;
      
      manager = TimerManager(
        GetRemainingTimeUseCase(repo),
        ConsumeTimeUseCase(repo),
        prefs,
      );

      await manager.initialize();
      await manager.start();
      
      expect(manager.isRunning, true);
      
      // Wait slightly more than 5 seconds (simulated by updating timestamp manually for speed or just delay)
      // Since it's a real timer, let's just hack the timestamp and call _syncTime via reflection...
      // Or we can just wait. Since it's 5s, we could wait in test, but tests should be fast.
      // Instead, we can simulate time passing by altering the start timestamp in prefs.
      
      final past = DateTime.now().subtract(const Duration(seconds: 10)).millisecondsSinceEpoch;
      await prefs.setInt('timer_start_timestamp', past);
      
      // Wait for next tick to process the past timestamp
      await Future.delayed(const Duration(seconds: 2));
      
      expect(repo.remaining, 0);
      expect(manager.remainingSeconds, 0);
      expect(manager.isRunning, false);
    });
    
    test('stop clears state', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      
      repo.remaining = 100;
      
      manager = TimerManager(
        GetRemainingTimeUseCase(repo),
        ConsumeTimeUseCase(repo),
        prefs,
      );

      await manager.start();
      expect(prefs.getBool('timer_was_running'), true);
      expect(prefs.getInt('timer_start_timestamp'), isNotNull);

      await manager.stop();
      expect(prefs.getBool('timer_was_running'), false);
      expect(prefs.getInt('timer_start_timestamp'), isNull);
      expect(manager.isRunning, false);
    });

    test('countdown consumes time on ticker using timestamps', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      repo.remaining = 30;

      manager = TimerManager(
        GetRemainingTimeUseCase(repo),
        ConsumeTimeUseCase(repo),
        prefs,
      );
      addTearDown(manager.dispose);

      await manager.start();
      final past = DateTime.now().subtract(const Duration(seconds: 3)).millisecondsSinceEpoch;
      await prefs.setInt('timer_start_timestamp', past);
      await Future.delayed(const Duration(seconds: 2));

      expect(repo.remaining, lessThan(30));
      expect(manager.isRunning, true);
    });

    test('background pause stops ticker without clearing recovery flags', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      repo.remaining = 40;

      manager = TimerManager(
        GetRemainingTimeUseCase(repo),
        ConsumeTimeUseCase(repo),
        prefs,
      );
      addTearDown(manager.dispose);

      await manager.start();
      manager.pauseForBackground();

      expect(manager.isRunning, true);
      expect(prefs.getBool('timer_was_running'), true);
      expect(prefs.getInt('timer_start_timestamp'), isNotNull);

      final remainingAfterPause = repo.remaining;
      await Future.delayed(const Duration(seconds: 2));
      expect(repo.remaining, remainingAfterPause);
    });

    test('foreground resume refreshes remaining and can stop when expired', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      repo.remaining = 5;

      manager = TimerManager(
        GetRemainingTimeUseCase(repo),
        ConsumeTimeUseCase(repo),
        prefs,
      );
      addTearDown(manager.dispose);

      await manager.start();
      manager.pauseForBackground();
      repo.remaining = 0;
      await manager.resumeFromForeground();

      expect(manager.isRunning, false);
      expect(manager.remainingSeconds, 0);
    });
  });
}
