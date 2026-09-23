class TimeLedger {
  final int earnedSeconds;
  final int usedSeconds;
  final int remainingSeconds;
  final DateTime lastUpdated;

  const TimeLedger({
    required this.earnedSeconds,
    required this.usedSeconds,
    required this.remainingSeconds,
    required this.lastUpdated,
  });

  TimeLedger copyWith({
    int? earnedSeconds,
    int? usedSeconds,
    int? remainingSeconds,
    DateTime? lastUpdated,
  }) {
    return TimeLedger(
      earnedSeconds: earnedSeconds ?? this.earnedSeconds,
      usedSeconds: usedSeconds ?? this.usedSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
