import 'daily_stats.dart';
import '../../exercise/domain/exercise_session.dart';

abstract class StatsRepository {
  Future<void> saveSession(ExerciseSession session);
  Future<List<DailyStats>> getWeeklyStats();
  Future<DailyStats?> getDailyStats(String date);
}
