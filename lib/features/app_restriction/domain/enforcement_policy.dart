class EnforcementPolicy {
  const EnforcementPolicy();

  bool shouldConsumeTime({
    required String? foregroundPackage,
    required Set<String> restrictedPackages,
    required int remainingSeconds,
  }) {
    if (foregroundPackage == null) return false;
    if (!restrictedPackages.contains(foregroundPackage)) return false;
    return remainingSeconds > 0;
  }

  bool shouldShowBlockedScreen({
    required String? foregroundPackage,
    required Set<String> restrictedPackages,
    required int remainingSeconds,
  }) {
    if (foregroundPackage == null) return false;
    if (!restrictedPackages.contains(foregroundPackage)) return false;
    return remainingSeconds <= 0;
  }

  bool shouldRunService({
    required Iterable<String> restrictedPackages,
    required bool hasUsageAccess,
  }) {
    return restrictedPackages.isNotEmpty && hasUsageAccess;
  }
}
