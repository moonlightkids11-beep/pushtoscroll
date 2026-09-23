import '../../../core/constants/app_constants.dart';

class RewardCalculator {
  int calculateReward(int pushUps) {
    if (pushUps <= 0) return 0;
    return pushUps * AppConstants.PUSHUP_REWARD_SECONDS;
  }
}
