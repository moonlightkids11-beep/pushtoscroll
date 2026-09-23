import '../../domain/exercise_session.dart';

class ExerciseSessionModel extends ExerciseSession {
  const ExerciseSessionModel({
    required super.id,
    required super.startTime,
    required super.endTime,
    required super.pushUps,
    required super.earnedSeconds,
  });

  factory ExerciseSessionModel.fromMap(Map<String, dynamic> map) {
    return ExerciseSessionModel(
      id: map['id'] as String,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: DateTime.parse(map['end_time'] as String),
      pushUps: map['push_ups'] as int,
      earnedSeconds: map['earned_seconds'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'push_ups': pushUps,
      'earned_seconds': earnedSeconds,
    };
  }

  factory ExerciseSessionModel.fromEntity(ExerciseSession entity) {
    return ExerciseSessionModel(
      id: entity.id,
      startTime: entity.startTime,
      endTime: entity.endTime,
      pushUps: entity.pushUps,
      earnedSeconds: entity.earnedSeconds,
    );
  }
}
