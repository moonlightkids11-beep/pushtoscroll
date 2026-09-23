import 'dart:math';
import 'pose_landmark.dart';

class PushUpValidator {
  static const double minLikelihood = 0.5;

  bool isReady(Pose pose) {
    return _areLandmarksVisible(pose, [
      LandmarkType.leftShoulder,
      LandmarkType.rightShoulder,
      LandmarkType.leftElbow,
      LandmarkType.rightElbow,
      LandmarkType.leftWrist,
      LandmarkType.rightWrist,
    ]);
  }

  bool isUpPosition(Pose pose) {
    if (!isReady(pose)) return false;
    
    final leftAngle = calculateAngle(
      pose.landmarks[LandmarkType.leftShoulder]!,
      pose.landmarks[LandmarkType.leftElbow]!,
      pose.landmarks[LandmarkType.leftWrist]!,
    );
    final rightAngle = calculateAngle(
      pose.landmarks[LandmarkType.rightShoulder]!,
      pose.landmarks[LandmarkType.rightElbow]!,
      pose.landmarks[LandmarkType.rightWrist]!,
    );

    // Arms straight
    return leftAngle > 150.0 && rightAngle > 150.0;
  }

  bool isDownPosition(Pose pose) {
    if (!isReady(pose)) return false;
    
    final leftAngle = calculateAngle(
      pose.landmarks[LandmarkType.leftShoulder]!,
      pose.landmarks[LandmarkType.leftElbow]!,
      pose.landmarks[LandmarkType.leftWrist]!,
    );
    final rightAngle = calculateAngle(
      pose.landmarks[LandmarkType.rightShoulder]!,
      pose.landmarks[LandmarkType.rightElbow]!,
      pose.landmarks[LandmarkType.rightWrist]!,
    );

    // Elbows bent
    return leftAngle < 100.0 && rightAngle < 100.0;
  }

  bool _areLandmarksVisible(Pose pose, List<LandmarkType> types) {
    for (final type in types) {
      if (!pose.landmarks.containsKey(type) ||
          pose.landmarks[type]!.likelihood < minLikelihood) {
        return false;
      }
    }
    return true;
  }

  double calculateAngle(PoseLandmark first, PoseLandmark middle, PoseLandmark last) {
    double angle = atan2(last.y - middle.y, last.x - middle.x) -
                   atan2(first.y - middle.y, first.x - middle.x);
    angle = angle * (180.0 / pi);
    angle = angle.abs();
    if (angle > 180.0) {
      angle = 360.0 - angle;
    }
    return angle;
  }
}
