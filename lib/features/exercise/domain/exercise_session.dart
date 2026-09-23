class ExerciseSession {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final int pushUps;
  final int earnedSeconds;

  const ExerciseSession({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.pushUps,
    required this.earnedSeconds,
  });
}
