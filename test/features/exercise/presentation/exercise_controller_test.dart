import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:earn_your_scroll/features/exercise/presentation/exercise_controller.dart';
import 'package:earn_your_scroll/features/exercise/domain/pose/push_up_detector.dart';
import 'package:earn_your_scroll/features/exercise/domain/pose/push_up_state.dart';
import 'package:earn_your_scroll/features/timer/domain/usecases/earn_time_usecase.dart';
import 'package:earn_your_scroll/features/timer/domain/reward_calculator.dart';
import 'package:earn_your_scroll/features/timer/domain/timer_manager.dart';
import 'package:earn_your_scroll/features/timer/domain/usecases/consume_time_usecase.dart';
import 'package:earn_your_scroll/features/timer/domain/usecases/get_remaining_time_usecase.dart';
import 'package:earn_your_scroll/features/stats/domain/stats_repository.dart';
import 'package:earn_your_scroll/features/stats/domain/daily_stats.dart';
import 'package:earn_your_scroll/features/exercise/domain/exercise_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../timer/domain/reward_engine_test.dart' show FakeTimeRepository;

class FakePushUpDetector implements PushUpDetector {
  final StreamController<int> _pushUpController = StreamController<int>.broadcast();
  final StreamController<PushUpState> _stateController = StreamController<PushUpState>.broadcast();

  bool isDetecting = false;
  bool isDisposed = false;
  bool throwOnStart = false;

  void simulatePushUps(int total) {
    _pushUpController.add(total);
  }

  void simulateState(PushUpState state) {
    _stateController.add(state);
  }

  @override
  Stream<int> get pushUpStream => _pushUpController.stream;

  @override
  Stream<PushUpState> get stateStream => _stateController.stream;

  @override
  Future<void> startDetection() async {
    if (throwOnStart) throw StateError('camera unavailable');
    isDetecting = true;
  }

  @override
  Future<void> stopDetection() async {
    isDetecting = false;
  }

  @override
  void dispose() {
    isDisposed = true;
    _pushUpController.close();
    _stateController.close();
  }
}

class FakeStatsRepository implements StatsRepository {
  final List<ExerciseSession> sessions = [];

  @override
  Future<void> saveSession(ExerciseSession session) async {
    sessions.add(session);
  }

  @override
  Future<DailyStats?> getDailyStats(String date) async => null;

  @override
  Future<List<DailyStats>> getWeeklyStats() async => [];
}

void main() {
  group('ExerciseController', () {
    late FakePushUpDetector detector;
    late FakeTimeRepository timeRepo;
    late FakeStatsRepository statsRepo;
    late EarnTimeUseCase earnTimeUseCase;
    late RewardCalculator rewardCalculator;
    late TimerManager timerManager;
    late ExerciseController controller;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      detector = FakePushUpDetector();
      timeRepo = FakeTimeRepository();
      statsRepo = FakeStatsRepository();
      rewardCalculator = RewardCalculator();
      earnTimeUseCase = EarnTimeUseCase(timeRepo, rewardCalculator);
      
      timerManager = TimerManager(
        GetRemainingTimeUseCase(timeRepo),
        ConsumeTimeUseCase(timeRepo),
        prefs,
      );

      controller = ExerciseController(
        detector: detector,
        earnTimeUseCase: earnTimeUseCase,
        rewardCalculator: rewardCalculator,
        statsRepository: statsRepo,
        timerManager: timerManager,
      );
    });

    test('Initial state is correct', () {
      expect(controller.pushUps, 0);
      expect(controller.isSessionActive, false);
      expect(controller.currentState, PushUpState.ready);
    });

    test('startSession starts detection and sets state', () async {
      await controller.startSession();
      expect(controller.isSessionActive, true);
      expect(detector.isDetecting, true);
    });

    test('failed detector start cleans up the active session state', () async {
      detector.throwOnStart = true;

      await expectLater(controller.startSession(), throwsStateError);

      expect(controller.isSessionActive, false);
      detector.simulatePushUps(1);
      await Future<void>.delayed(Duration.zero);
      expect(timeRepo.earned, 0);
    });

    test('endSession stops detection and saves session', () async {
      await controller.startSession();
      
      detector.simulatePushUps(1);
      detector.simulatePushUps(3); // total 3
      
      // Wait for stream events to be processed
      await Future.delayed(Duration.zero);
      
      await controller.endSession();
      
      expect(controller.isSessionActive, false);
      expect(detector.isDetecting, false);
      expect(statsRepo.sessions.length, 1);
      expect(statsRepo.sessions.first.pushUps, 3);
      expect(statsRepo.sessions.first.earnedSeconds, 45); // 3 * 15
    });

    test('Delta push-ups properly earn time', () async {
      await controller.startSession();
      
      detector.simulatePushUps(1); // delta 1
      await Future.delayed(Duration.zero);
      expect(timeRepo.earned, 15);
      
      detector.simulatePushUps(3); // delta 2
      await Future.delayed(Duration.zero);
      expect(timeRepo.earned, 45); // +30s
      
      detector.simulatePushUps(3); // duplicate, no delta
      await Future.delayed(Duration.zero);
      expect(timeRepo.earned, 45); // unchanged
    });

    test('State changes update the controller', () async {
      await controller.startSession();
      
      detector.simulateState(PushUpState.down);
      await Future.delayed(Duration.zero);
      
      expect(controller.currentState, PushUpState.down);
    });

    test('events emitted after a session ends do not earn additional time', () async {
      await controller.startSession();
      await controller.endSession();

      detector.simulatePushUps(1);
      detector.simulateState(PushUpState.down);
      await Future<void>.delayed(Duration.zero);

      expect(controller.pushUps, 0);
      expect(timeRepo.earned, 0);
      expect(controller.currentState, PushUpState.ready);
    });
  });
}
