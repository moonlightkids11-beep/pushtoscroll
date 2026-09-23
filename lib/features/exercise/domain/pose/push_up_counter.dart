import 'pose_landmark.dart';
import 'push_up_state.dart';
import 'push_up_validator.dart';

class PushUpCounter {
  final PushUpValidator _validator;
  PushUpState _currentState = PushUpState.ready;
  DateTime _lastPushUpTime = DateTime.fromMillisecondsSinceEpoch(0);
  
  static const Duration _minInterval = Duration(milliseconds: 500);

  PushUpCounter(this._validator);

  PushUpState get currentState => _currentState;

  /// Processes a pose and returns true if a valid push-up was completed
  bool processPose(Pose pose) {
    if (!_validator.isReady(pose)) {
      return false; // Ignore frames with poor tracking to avoid noise
    }

    final isUp = _validator.isUpPosition(pose);
    final isDown = _validator.isDownPosition(pose);

    switch (_currentState) {
      case PushUpState.ready:
        if (isUp) {
          _currentState = PushUpState.up;
        }
        break;

      case PushUpState.up:
        if (isDown) {
          _currentState = PushUpState.down;
        }
        break;

      case PushUpState.down:
        if (isUp) {
          final now = DateTime.now();
          if (now.difference(_lastPushUpTime) > _minInterval) {
            _lastPushUpTime = now;
            _currentState = PushUpState.up; // Reset for next rep
            return true; // Valid repetition!
          }
        }
        break;
    }

    return false;
  }
}
