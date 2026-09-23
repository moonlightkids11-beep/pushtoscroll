import 'package:sqflite/sqflite.dart';
import '../../../core/data/local_database.dart';
import '../domain/time_repository.dart';
import '../domain/time_ledger.dart';
import 'models/time_ledger_model.dart';

class SqfliteTimeRepository implements TimeRepository {
  final LocalDatabase _localDatabase;

  SqfliteTimeRepository(this._localDatabase);

  @override
  Future<TimeLedger> getTimeLedger() async {
    try {
      final db = await _localDatabase.database;
      return await db.transaction((txn) async {
        final result = await txn.query(
          'time_ledger',
          where: 'id = ?',
          whereArgs: [1],
        );

        if (result.isNotEmpty) {
          return TimeLedgerModel.fromMap(result.first);
        }

        // Creation must share the same transaction boundary as reward writes.
        // Otherwise a first-read default can overwrite a simultaneous reward.
        final defaultLedger = TimeLedger(
          earnedSeconds: 0,
          usedSeconds: 0,
          remainingSeconds: 0,
          lastUpdated: DateTime.now(),
        );
        await _saveLedger(defaultLedger, executor: txn);
        return defaultLedger;
      });
    } catch (e) {
      return TimeLedger(
        earnedSeconds: 0,
        usedSeconds: 0,
        remainingSeconds: 0,
        lastUpdated: DateTime.now(),
      );
    }
  }

  Future<void> _saveLedger(
    TimeLedger ledger, {
    DatabaseExecutor? executor,
  }) async {
    final db = executor ?? await _localDatabase.database;
    final model = TimeLedgerModel.fromEntity(ledger);
    
    await db.insert(
      'time_ledger',
      model.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> addEarnedTime(int seconds) async {
    if (seconds <= 0) return;

    // A detector can publish successive totals before the previous database
    // write completes. Read-modify-write must therefore be one transaction so
    // legitimate rewards cannot overwrite one another.
    final db = await _localDatabase.database;
    await db.transaction((txn) async {
      final ledger = await _readLedger(txn);
      await _saveLedger(
        ledger.copyWith(
          earnedSeconds: ledger.earnedSeconds + seconds,
          remainingSeconds: ledger.remainingSeconds + seconds,
          lastUpdated: DateTime.now(),
        ),
        executor: txn,
      );
    });
  }

  @override
  Future<int> getAvailableTime() async {
    final ledger = await getTimeLedger();
    return ledger.remainingSeconds;
  }

  @override
  Future<void> consumeTime(int seconds) async {
    if (seconds <= 0) return;

    final db = await _localDatabase.database;
    await db.transaction((txn) async {
      final ledger = await _readLedger(txn);
      final actualConsume = seconds > ledger.remainingSeconds
          ? ledger.remainingSeconds
          : seconds;
      await _saveLedger(
        ledger.copyWith(
          usedSeconds: ledger.usedSeconds + actualConsume,
          remainingSeconds: ledger.remainingSeconds - actualConsume,
          lastUpdated: DateTime.now(),
        ),
        executor: txn,
      );
    });
  }

  Future<TimeLedger> _readLedger(DatabaseExecutor executor) async {
    final result = await executor.query(
      'time_ledger',
      where: 'id = ?',
      whereArgs: [1],
    );
    if (result.isEmpty) {
      return TimeLedger(
        earnedSeconds: 0,
        usedSeconds: 0,
        remainingSeconds: 0,
        lastUpdated: DateTime.now(),
      );
    }
    return TimeLedgerModel.fromMap(result.first);
  }
}
