import 'package:sqflite/sqflite.dart';
import '../../../core/data/local_database.dart';
import '../domain/stats_repository.dart';
import '../domain/daily_stats.dart';
import 'models/daily_stats_model.dart';
import '../../exercise/domain/exercise_session.dart';
import '../../exercise/data/models/exercise_session_model.dart';

class SqfliteStatsRepository implements StatsRepository {
  final LocalDatabase _localDatabase;

  SqfliteStatsRepository(this._localDatabase);

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Future<void> saveSession(ExerciseSession session) async {
    final db = await _localDatabase.database;
    final model = ExerciseSessionModel.fromEntity(session);

    await db.transaction((txn) async {
      await txn.insert(
        'exercise_sessions',
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      final dateStr = _formatDate(session.endTime);
      final statsResult = await txn.query(
        'daily_stats',
        where: 'date = ?',
        whereArgs: [dateStr],
      );

      DailyStats stats;
      if (statsResult.isNotEmpty) {
        stats = DailyStatsModel.fromMap(statsResult.first);
        stats = stats.copyWith(
          pushUps: stats.pushUps + session.pushUps,
          earnedSeconds: stats.earnedSeconds + session.earnedSeconds,
        );
      } else {
        stats = DailyStats(
          date: dateStr,
          pushUps: session.pushUps,
          earnedSeconds: session.earnedSeconds,
          usedSeconds: 0,
        );
      }

      await txn.insert(
        'daily_stats',
        DailyStatsModel.fromEntity(stats).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  @override
  Future<List<DailyStats>> getWeeklyStats() async {
    try {
      final db = await _localDatabase.database;
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      
      final result = await db.query(
        'daily_stats',
        where: 'date >= ?',
        whereArgs: [_formatDate(sevenDaysAgo)],
        orderBy: 'date DESC',
      );

      return result.map((e) => DailyStatsModel.fromMap(e)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<DailyStats?> getDailyStats(String date) async {
    try {
      final db = await _localDatabase.database;
      final result = await db.query(
        'daily_stats',
        where: 'date = ?',
        whereArgs: [date],
      );

      if (result.isNotEmpty) {
        return DailyStatsModel.fromMap(result.first);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
