// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../domain/pose/push_up_detector.dart';
import '../domain/pose/push_up_state.dart';
import '../../timer/domain/usecases/earn_time_usecase.dart';
import '../../timer/domain/reward_calculator.dart';
import '../../timer/domain/timer_manager.dart';
import '../../stats/domain/stats_repository.dart';
import '../domain/exercise_session.dart';

class ExerciseController extends ChangeNotifier {
  final PushUpDetector _detector;
  final EarnTimeUseCase _earnTimeUseCase;
  final RewardCalculator _rewardCalculator;
  final StatsRepository _statsRepository;
  final TimerManager _timerManager;

  DateTime? _sessionStartTime;
  int _pushUps = 0;
  PushUpState _currentState = PushUpState.ready;
  StreamSubscription? _pushUpSub;
  StreamSubscription? _stateSub;
  bool _isSessionActive = false;

  ExerciseController({
    required PushUpDetector detector,
    required EarnTimeUseCase earnTimeUseCase,
    required RewardCalculator rewardCalculator,
    required StatsRepository statsRepository,
    required TimerManager timerManager,
  })  : _detector = detector,
        _earnTimeUseCase = earnTimeUseCase,
        _rewardCalculator = rewardCalculator,
        _statsRepository = statsRepository,
        _timerManager = timerManager;

  int get pushUps => _pushUps;
  PushUpState get currentState => _currentState;
  bool get isSessionActive => _isSessionActive;

  Future<void> startSession() async {
    if (_isSessionActive) return;
    
    _isSessionActive = true;
    _pushUps = 0;
    _currentState = PushUpState.ready;
    _sessionStartTime = DateTime.now();
    notifyListeners();

    _pushUpSub = _detector.pushUpStream.listen(_onPushUpDetected);
    _stateSub = _detector.stateStream.listen(_onStateChanged);

    try {
      await _detector.startDetection();
    } catch (_) {
      _isSessionActive = false;
      _sessionStartTime = null;
      await _pushUpSub?.cancel();
      await _stateSub?.cancel();
      _pushUpSub = null;
      _stateSub = null;
      notifyListeners();
      rethrow;
    }
  }

  void _onPushUpDetected(int totalPushUps) async {
    if (!_isSessionActive || totalPushUps <= _pushUps) return;

    final delta = totalPushUps - _pushUps;
    _pushUps = totalPushUps;
    notifyListeners();

    // Earn time for the new valid repetitions.
    await _earnTimeUseCase.execute(delta);

    // A session may have ended while the persistence write was in flight.
    // Refreshing the timer after that point would notify a disposed UI tree.
    if (_isSessionActive) {
      await _timerManager.syncExternalTimeUpdate();
    }
  }

  void _onStateChanged(PushUpState state) {
    if (!_isSessionActive) return;
    if (_currentState != state) {
      _currentState = state;
      notifyListeners();
    }
  }

  Future<void> endSession() async {
    if (!_isSessionActive) return;
    
    _isSessionActive = false;
    final endTime = DateTime.now();

    try {
      await _detector.stopDetection();
    } catch (_) {
      // The camera can already be detached by the platform while this screen
      // is closing. Subscription cleanup and session persistence still apply.
    }
    await _pushUpSub?.cancel();
    await _stateSub?.cancel();
    
    _pushUpSub = null;
    _stateSub = null;

    if (_pushUps > 0 && _sessionStartTime != null) {
      final totalEarned = _rewardCalculator.calculateReward(_pushUps);
      
      final session = ExerciseSession(
        id: const Uuid().v4(),
        startTime: _sessionStartTime!,
        endTime: endTime,
        pushUps: _pushUps,
        earnedSeconds: totalEarned,
      );
      
      await _statsRepository.saveSession(session);
    }
    
    _sessionStartTime = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _pushUpSub?.cancel();
    _stateSub?.cancel();
    _detector.dispose();
    super.dispose();
  }
}
