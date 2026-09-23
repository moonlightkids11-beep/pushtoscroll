enum LandmarkType {
  leftShoulder,
  rightShoulder,
  leftElbow,
  rightElbow,
  leftWrist,
  rightWrist,
  leftHip,
  rightHip,
  leftKnee,
  rightKnee,
  leftAnkle,
  rightAnkle,
  other
}

class PoseLandmark {
  final LandmarkType type;
  final double x;
  final double y;
  final double z;
  final double likelihood;

  const PoseLandmark({
    required this.type,
    required this.x,
    required this.y,
    required this.z,
    required this.likelihood,
  });
}

class Pose {
  final Map<LandmarkType, PoseLandmark> landmarks;
  const Pose(this.landmarks);
}
