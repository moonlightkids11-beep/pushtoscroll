import '../time_repository.dart';
import '../reward_calculator.dart';

class EarnTimeUseCase {
  final TimeRepository _timeRepository;
  final RewardCalculator _rewardCalculator;

  EarnTimeUseCase(this._timeRepository, this._rewardCalculator);

  Future<int> execute(int pushUps) async {
    final earnedSeconds = _rewardCalculator.calculateReward(pushUps);
    if (earnedSeconds > 0) {
      await _timeRepository.addEarnedTime(earnedSeconds);
    }
    return earnedSeconds;
  }
}
