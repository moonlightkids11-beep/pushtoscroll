import 'dart:convert';
import '../../domain/user_settings.dart';

class UserSettingsModel extends UserSettings {
  const UserSettingsModel({
    required super.selectedTheme,
    required super.selectedRestrictedApps,
    required super.rewardRate,
  });

  factory UserSettingsModel.fromMap(Map<String, dynamic> map) {
    List<String> apps = const [];
    final rawApps = map['selected_restricted_apps'];
    try {
      if (rawApps is String) {
        final decoded = json.decode(rawApps);
        if (decoded is List) {
          apps = decoded.map((e) => e.toString()).toList();
        }
      } else if (rawApps is List) {
        apps = rawApps.map((e) => e.toString()).toList();
      }
    } catch (_) {
      apps = const [];
    }

    final rate = map['reward_rate'];
    int rewardRate = 15;
    if (rate is int) {
      rewardRate = rate;
    } else if (rate is num) {
      rewardRate = rate.toInt();
    } else if (rate is String) {
      rewardRate = int.tryParse(rate) ?? 15;
    }

    return UserSettingsModel(
      selectedTheme: map['selected_theme']?.toString() ?? 'default',
      selectedRestrictedApps: apps,
      rewardRate: rewardRate <= 0 ? 15 : rewardRate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': 1,
      'selected_theme': selectedTheme,
      'selected_restricted_apps': json.encode(selectedRestrictedApps),
      'reward_rate': rewardRate,
    };
  }

  factory UserSettingsModel.fromEntity(UserSettings entity) {
    return UserSettingsModel(
      selectedTheme: entity.selectedTheme,
      selectedRestrictedApps: entity.selectedRestrictedApps,
      rewardRate: entity.rewardRate,
    );
  }
}
