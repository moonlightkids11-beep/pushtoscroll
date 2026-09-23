import '../../domain/time_ledger.dart';

class TimeLedgerModel extends TimeLedger {
  const TimeLedgerModel({
    required super.earnedSeconds,
    required super.usedSeconds,
    required super.remainingSeconds,
    required super.lastUpdated,
  });

  factory TimeLedgerModel.fromMap(Map<String, dynamic> map) {
    final lastUpdatedRaw = map['last_updated'];
    DateTime lastUpdated;
    if (lastUpdatedRaw is String) {
      lastUpdated = DateTime.tryParse(lastUpdatedRaw) ?? DateTime.fromMillisecondsSinceEpoch(0);
    } else {
      lastUpdated = DateTime.fromMillisecondsSinceEpoch(0);
    }

    return TimeLedgerModel(
      earnedSeconds: _readNonNegativeInt(map['earned_seconds']),
      usedSeconds: _readNonNegativeInt(map['used_seconds']),
      remainingSeconds: _readNonNegativeInt(map['remaining_seconds']),
      lastUpdated: lastUpdated,
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
      'id': 1,
      'earned_seconds': earnedSeconds,
      'used_seconds': usedSeconds,
      'remaining_seconds': remainingSeconds,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  factory TimeLedgerModel.fromEntity(TimeLedger entity) {
    return TimeLedgerModel(
      earnedSeconds: entity.earnedSeconds,
      usedSeconds: entity.usedSeconds,
      remainingSeconds: entity.remainingSeconds,
      lastUpdated: entity.lastUpdated,
    );
  }
}
