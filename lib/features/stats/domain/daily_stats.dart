class DailyStats {
  final String date;
  final int pushUps;
  final int earnedSeconds;
  final int usedSeconds;

  const DailyStats({
    required this.date,
    required this.pushUps,
    required this.earnedSeconds,
    required this.usedSeconds,
  });

  DailyStats copyWith({
    String? date,
    int? pushUps,
    int? earnedSeconds,
    int? usedSeconds,
  }) {
    return DailyStats(
      date: date ?? this.date,
      pushUps: pushUps ?? this.pushUps,
      earnedSeconds: earnedSeconds ?? this.earnedSeconds,
      usedSeconds: usedSeconds ?? this.usedSeconds,
    );
  }
}
