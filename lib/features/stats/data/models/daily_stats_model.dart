import '../../domain/daily_stats.dart';

class DailyStatsModel extends DailyStats {
  const DailyStatsModel({
    required super.date,
    required super.pushUps,
    required super.earnedSeconds,
    required super.usedSeconds,
  });

  factory DailyStatsModel.fromMap(Map<String, dynamic> map) {
    return DailyStatsModel(
      date: map['date']?.toString() ?? '',
      pushUps: _readNonNegativeInt(map['push_ups']),
      earnedSeconds: _readNonNegativeInt(map['earned_seconds']),
      usedSeconds: _readNonNegativeInt(map['used_seconds']),
    );
  }

  static int _readNonNegativeInt(dynamic value) {
    int parsed = 0;
    if (value is int) {
      parsed = value;
    } else if (value is num) {
      parsed = value.toInt();
    } else if (value is String) {
      parsed = int.tryParse(value) ?? 0;
    }
    return parsed < 0 ? 0 : parsed;
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'push_ups': pushUps,
      'earned_seconds': earnedSeconds,
      'used_seconds': usedSeconds,
    };
  }

  factory DailyStatsModel.fromEntity(DailyStats entity) {
    return DailyStatsModel(
      date: entity.date,
      pushUps: entity.pushUps,
      earnedSeconds: entity.earnedSeconds,
      usedSeconds: entity.usedSeconds,
    );
  }
}
