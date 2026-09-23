import 'package:flutter_test/flutter_test.dart';
import 'package:earn_your_scroll/features/settings/data/models/user_settings_model.dart';
import 'package:earn_your_scroll/features/stats/data/models/daily_stats_model.dart';
import 'package:earn_your_scroll/features/timer/data/models/time_ledger_model.dart';

void main() {
  test('TimeLedgerModel sanitizes corrupt numeric and timestamp values', () {
    final ledger = TimeLedgerModel.fromMap({
      'earned_seconds': -40,
      'used_seconds': 'not-a-number',
      'remaining_seconds': '-12',
      'last_updated': 'corrupt-date',
    });

    expect(ledger.earnedSeconds, 0);
    expect(ledger.usedSeconds, 0);
    expect(ledger.remainingSeconds, 0);
    expect(ledger.lastUpdated, DateTime.fromMillisecondsSinceEpoch(0));
  });

  test('DailyStatsModel sanitizes corrupt values', () {
    final stats = DailyStatsModel.fromMap({
      'date': null,
      'push_ups': -8,
      'earned_seconds': 'abc',
      'used_seconds': -1,
    });

    expect(stats.date, '');
    expect(stats.pushUps, 0);
    expect(stats.earnedSeconds, 0);
    expect(stats.usedSeconds, 0);
  });

  test('UserSettingsModel recovers from corrupt JSON and invalid reward rate', () {
    final settings = UserSettingsModel.fromMap({
      'selected_theme': null,
      'selected_restricted_apps': '{not-json',
      'reward_rate': -3,
    });

    expect(settings.selectedTheme, 'default');
    expect(settings.selectedRestrictedApps, isEmpty);
    expect(settings.rewardRate, 15);
  });
}
