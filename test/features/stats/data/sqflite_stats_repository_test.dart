import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:earn_your_scroll/core/data/local_database.dart';
import 'package:earn_your_scroll/features/stats/data/sqflite_stats_repository.dart';
import 'package:earn_your_scroll/features/exercise/domain/exercise_session.dart';

void main() {
  late LocalDatabase localDatabase;
  late SqfliteStatsRepository repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    localDatabase = LocalDatabase(inMemory: true);
    repository = SqfliteStatsRepository(localDatabase);
  });

  tearDown(() async {
    await localDatabase.close();
  });

  test('saveSession creates new daily stat if none exists', () async {
    final session = ExerciseSession(
      id: '1',
      startTime: DateTime.now().subtract(const Duration(minutes: 1)),
      endTime: DateTime.now(),
      pushUps: 10,
      earnedSeconds: 150,
    );

    await repository.saveSession(session);
    final weeklyStats = await repository.getWeeklyStats();
    
    expect(weeklyStats.length, 1);
    expect(weeklyStats.first.pushUps, 10);
    expect(weeklyStats.first.earnedSeconds, 150);
  });

  test('saveSession aggregates daily stats', () async {
    final now = DateTime.now();
    
    final session1 = ExerciseSession(
      id: '1',
      startTime: now.subtract(const Duration(minutes: 2)),
      endTime: now,
      pushUps: 10,
      earnedSeconds: 150,
    );
    
    final session2 = ExerciseSession(
      id: '2',
      startTime: now.subtract(const Duration(minutes: 1)),
      endTime: now,
      pushUps: 5,
      earnedSeconds: 75,
    );

    await repository.saveSession(session1);
    await repository.saveSession(session2);
    
    final weeklyStats = await repository.getWeeklyStats();
    
    expect(weeklyStats.length, 1);
    expect(weeklyStats.first.pushUps, 15);
    expect(weeklyStats.first.earnedSeconds, 225);
  });

  test('getDailyStats returns null for empty date', () async {
    final stats = await repository.getDailyStats('1999-01-01');
    expect(stats, isNull);
  });
}
