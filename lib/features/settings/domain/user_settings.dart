class UserSettings {
  final String selectedTheme;
  final List<String> selectedRestrictedApps;
  final int rewardRate;

  const UserSettings({
    required this.selectedTheme,
    required this.selectedRestrictedApps,
    required this.rewardRate,
  });

  UserSettings copyWith({
    String? selectedTheme,
    List<String>? selectedRestrictedApps,
    int? rewardRate,
  }) {
    return UserSettings(
      selectedTheme: selectedTheme ?? this.selectedTheme,
      selectedRestrictedApps: selectedRestrictedApps ?? this.selectedRestrictedApps,
      rewardRate: rewardRate ?? this.rewardRate,
    );
  }
}
