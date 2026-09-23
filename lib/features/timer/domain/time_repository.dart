import 'time_ledger.dart';

abstract class TimeRepository {
  Future<TimeLedger> getTimeLedger();
  Future<void> addEarnedTime(int seconds);
  Future<int> getAvailableTime();
  Future<void> consumeTime(int seconds);
}
