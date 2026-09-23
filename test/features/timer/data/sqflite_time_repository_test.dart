import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:earn_your_scroll/core/data/local_database.dart';
import 'package:earn_your_scroll/features/timer/data/sqflite_time_repository.dart';

void main() {
  late LocalDatabase localDatabase;
  late SqfliteTimeRepository repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    localDatabase = LocalDatabase(inMemory: true);
    repository = SqfliteTimeRepository(localDatabase);
  });

  tearDown(() async {
    await localDatabase.close();
  });

  test('getTimeLedger returns default on first call', () async {
    final ledger = await repository.getTimeLedger();
    expect(ledger.earnedSeconds, 0);
    expect(ledger.usedSeconds, 0);
    expect(ledger.remainingSeconds, 0);
  });

  test('addEarnedTime increases earned and remaining seconds', () async {
    await repository.addEarnedTime(15);
    final ledger = await repository.getTimeLedger();
    expect(ledger.earnedSeconds, 15);
    expect(ledger.usedSeconds, 0);
    expect(ledger.remainingSeconds, 15);
  });

  test('concurrent rewards are accumulated without a lost update', () async {
    await Future.wait([
      repository.addEarnedTime(15),
      repository.addEarnedTime(30),
    ]);

    final ledger = await repository.getTimeLedger();
    expect(ledger.earnedSeconds, 45);
    expect(ledger.remainingSeconds, 45);
  });

  test('first read cannot overwrite a concurrent reward', () async {
    await Future.wait([
      repository.getTimeLedger(),
      repository.addEarnedTime(15),
    ]);

    final ledger = await repository.getTimeLedger();
    expect(ledger.earnedSeconds, 15);
    expect(ledger.remainingSeconds, 15);
  });

  test('consumeTime decreases remaining and increases used seconds', () async {
    await repository.addEarnedTime(30);
    await repository.consumeTime(10);
    
    final ledger = await repository.getTimeLedger();
    expect(ledger.earnedSeconds, 30);
    expect(ledger.usedSeconds, 10);
    expect(ledger.remainingSeconds, 20);
  });
  
  test('consumeTime does not over-consume', () async {
    await repository.addEarnedTime(10);
    await repository.consumeTime(20);
    
    final ledger = await repository.getTimeLedger();
    expect(ledger.earnedSeconds, 10);
    expect(ledger.usedSeconds, 10); // only consumed what was available
    expect(ledger.remainingSeconds, 0);
  });

  test('getAvailableTime reads remaining after updates', () async {
    expect(await repository.getAvailableTime(), 0);
    await repository.addEarnedTime(45);
    expect(await repository.getAvailableTime(), 45);
    await repository.consumeTime(10);
    expect(await repository.getAvailableTime(), 35);
  });

  test('getTimeLedger recovers from corrupt stored row', () async {
    await repository.addEarnedTime(15);
    final db = await localDatabase.database;
    await db.update(
      'time_ledger',
      {
        'earned_seconds': 'bad',
        'used_seconds': -9,
        'remaining_seconds': 'nope',
        'last_updated': 'not-a-date',
      },
      where: 'id = ?',
      whereArgs: [1],
    );

    final ledger = await repository.getTimeLedger();
    expect(ledger.earnedSeconds, 0);
    expect(ledger.usedSeconds, 0);
    expect(ledger.remainingSeconds, 0);
  });
}
