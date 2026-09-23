import 'package:flutter_test/flutter_test.dart';
import 'package:earn_your_scroll/features/exercise/domain/pose/pose_landmark.dart';
import 'package:earn_your_scroll/features/exercise/domain/pose/push_up_state.dart';
import 'package:earn_your_scroll/features/exercise/domain/pose/push_up_validator.dart';
import 'package:earn_your_scroll/features/exercise/domain/pose/push_up_counter.dart';

Pose createPose(double armAngle, {bool visible = true}) {
  // Simplistic simulation: 
  // We manipulate coordinates to result in a specific angle using the validator's calculation.
  // Straight arm (180 deg): Shoulder (0, 0), Elbow (0, 50), Wrist (0, 100)
  // Bent arm (90 deg): Shoulder (0,0), Elbow (0,50), Wrist (50,50)
  
  // Actually, we can just mock the coordinates properly based on the angle requested.
  // For straight arm, angle is 180.
  // For bent arm, angle is 90.
  
  double wristX = 0;
  double wristY = 100;
  
  if (armAngle < 100) {
    wristX = 50;
    wristY = 50; // forms a 90 degree angle with elbow at 0,50 and shoulder at 0,0
  }
  
  final likelihood = visible ? 0.9 : 0.1;
  
  return Pose({
    LandmarkType.leftShoulder: PoseLandmark(type: LandmarkType.leftShoulder, x: 0, y: 0, z: 0, likelihood: likelihood),
    LandmarkType.rightShoulder: PoseLandmark(type: LandmarkType.rightShoulder, x: 20, y: 0, z: 0, likelihood: likelihood),
    LandmarkType.leftElbow: PoseLandmark(type: LandmarkType.leftElbow, x: 0, y: 50, z: 0, likelihood: likelihood),
    LandmarkType.rightElbow: PoseLandmark(type: LandmarkType.rightElbow, x: 20, y: 50, z: 0, likelihood: likelihood),
    LandmarkType.leftWrist: PoseLandmark(type: LandmarkType.leftWrist, x: wristX, y: wristY, z: 0, likelihood: likelihood),
    LandmarkType.rightWrist: PoseLandmark(type: LandmarkType.rightWrist, x: 20 + wristX, y: wristY, z: 0, likelihood: likelihood),
  });
}

void main() {
  group('PushUpCounter State Machine', () {
    late PushUpValidator validator;
    late PushUpCounter counter;

    setUp(() {
      validator = PushUpValidator();
      counter = PushUpCounter(validator);
    });

    test('Valid complete movement cycle', () async {
      expect(counter.currentState, PushUpState.ready);

      // Go UP
      bool counted = counter.processPose(createPose(180));
      expect(counted, false);
      expect(counter.currentState, PushUpState.up);

      // Go DOWN
      counted = counter.processPose(createPose(90));
      expect(counted, false);
      expect(counter.currentState, PushUpState.down);
      
      // Wait to bypass minInterval
      await Future.delayed(const Duration(milliseconds: 600));

      // Go UP again (completes rep)
      counted = counter.processPose(createPose(180));
      expect(counted, true);
      expect(counter.currentState, PushUpState.up);
    });

    test('Incomplete movement is not counted', () {
      // Go UP
      counter.processPose(createPose(180));
      expect(counter.currentState, PushUpState.up);

      // Stay UP
      bool counted = counter.processPose(createPose(180));
      expect(counted, false);
      expect(counter.currentState, PushUpState.up);
    });

    test('Rapid noise is ignored due to minInterval', () {
      // UP -> DOWN -> UP (counted)
      counter.processPose(createPose(180));
      counter.processPose(createPose(90));
      bool counted = counter.processPose(createPose(180));
      
      // The first rep might be counted immediately if we initialized _lastPushUpTime in the past
      expect(counted, true);

      // Noise: Rapid DOWN -> UP again instantly
      counter.processPose(createPose(90));
      counted = counter.processPose(createPose(180));
      
      // Should NOT be counted because 500ms hasn't passed
      expect(counted, false);
    });

    test('Temporary pose loss preserves state', () {
      // Go UP
      counter.processPose(createPose(180));
      expect(counter.currentState, PushUpState.up);

      // Pose tracking lost
      counter.processPose(createPose(180, visible: false));
      // State should remain UP
      expect(counter.currentState, PushUpState.up);
      
      // Go DOWN
      counter.processPose(createPose(90));
      expect(counter.currentState, PushUpState.down);
      
      // Pose tracking lost
      counter.processPose(createPose(90, visible: false));
      // State should remain DOWN
      expect(counter.currentState, PushUpState.down);
    });
  });
}
