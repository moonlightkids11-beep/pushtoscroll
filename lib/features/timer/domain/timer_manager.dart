import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'usecases/get_remaining_time_usecase.dart';
import 'usecases/consume_time_usecase.dart';

class TimerManager extends ChangeNotifier {
  final GetRemainingTimeUseCase _getRemainingTime;
  final ConsumeTimeUseCase _consumeTime;
  final SharedPreferences _prefs;

  Timer? _ticker;
  bool _isRunning = false;
  bool _isSyncing = false;
  bool _isDisposed = false;
  int _currentRemainingSeconds = 0;

  static const String _timerStartKey = 'timer_start_timestamp';
  static const String _timerWasRunningKey = 'timer_was_running';

  TimerManager(this._getRemainingTime, this._consumeTime, this._prefs);
  
  bool get isRunning => _isRunning;
  int get remainingSeconds => _currentRemainingSeconds;

  Future<void> initialize() async {
    _currentRemainingSeconds = await _getRemainingTime.execute();
    if (_isDisposed) return;
    
    final wasRunning = _prefs.getBool(_timerWasRunningKey) ?? false;
    final startTimestamp = _prefs.getInt(_timerStartKey);
    
    if (wasRunning && startTimestamp != null) {
      final passedSeconds = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(startTimestamp)).inSeconds;
      if (passedSeconds > 0) {
        await _consumeTime.execute(passedSeconds);
        if (_isDisposed) return;
        _currentRemainingSeconds = await _getRemainingTime.execute();
        if (_isDisposed) return;
      }
      
      if (_currentRemainingSeconds > 0) {
        await _prefs.setInt(_timerStartKey, DateTime.now().millisecondsSinceEpoch);
        if (!_isDisposed) _startTicker();
      } else {
        await _prefs.setBool(_timerWasRunningKey, false);
        await _prefs.remove(_timerStartKey);
      }
    }
    
    if (!_isDisposed) notifyListeners();
  }

  Future<void> start() async {
    if (_isRunning || _isDisposed) return;
    
    _currentRemainingSeconds = await _getRemainingTime.execute();
    if (_isDisposed || _currentRemainingSeconds <= 0) return;

    await _prefs.setBool(_timerWasRunningKey, true);
    await _prefs.setInt(_timerStartKey, DateTime.now().millisecondsSinceEpoch);
    
    if (_isDisposed) return;
    _startTicker();
    notifyListeners();
  }

  /// Stops the in-process ticker without clearing recovery flags.
  /// Native enforcement owns consumption while the app is backgrounded.
  void pauseForBackground() {
    _ticker?.cancel();
    _ticker = null;
  }

  Future<void> resumeFromForeground() async {
    _currentRemainingSeconds = await _getRemainingTime.execute();
    if (_isDisposed) return;
    if (_isRunning && _currentRemainingSeconds > 0) {
      await _prefs.setInt(_timerStartKey, DateTime.now().millisecondsSinceEpoch);
      _startTicker();
    } else if (_isRunning && _currentRemainingSeconds <= 0) {
      await stop();
      return;
    }
    if (!_isDisposed) notifyListeners();
  }

  Future<void> stop() async {
    if (_isDisposed || !_isRunning) return;
    
    _ticker?.cancel();
    _isRunning = false;
    
    await _syncTime();
    
    await _prefs.setBool(_timerWasRunningKey, false);
    await _prefs.remove(_timerStartKey);
    
    notifyListeners();
  }

  void _startTicker() {
    _isRunning = true;
    _ticker?.cancel();
    // Update every second, but calculate based on timestamps
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) async {
      await _syncTime();
      if (_currentRemainingSeconds <= 0) {
        await stop();
      }
    });
  }

  Future<void> _syncTime() async {
    if (_isDisposed || _isSyncing) return;
    _isSyncing = true;
    try {
      final startTimestamp = _prefs.getInt(_timerStartKey);
      if (startTimestamp != null) {
        final now = DateTime.now();
        final passedSeconds = now.difference(DateTime.fromMillisecondsSinceEpoch(startTimestamp)).inSeconds;
        
        if (passedSeconds > 0) {
          await _consumeTime.execute(passedSeconds);
          if (_isDisposed) return;
          _currentRemainingSeconds = await _getRemainingTime.execute();
          
          await _prefs.setInt(_timerStartKey, now.millisecondsSinceEpoch);
          if (!_isDisposed) {
            notifyListeners();
          }
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  // Helper method to sync immediately after earning time so UI updates
  Future<void> syncExternalTimeUpdate() async {
    if (_isDisposed) return;
    _currentRemainingSeconds = await _getRemainingTime.execute();
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _ticker?.cancel();
    _ticker = null;
    super.dispose();
  }
}
