import 'package:flutter_test/flutter_test.dart';
import 'package:earn_your_scroll/features/app_restriction/domain/enforcement_policy.dart';

void main() {
  const policy = EnforcementPolicy();
  const restricted = {'com.instagram.android', 'com.zhiliaoapp.musically'};

  group('EnforcementPolicy', () {
    test('consumes time only for selected apps with remaining time', () {
      expect(
        policy.shouldConsumeTime(
          foregroundPackage: 'com.instagram.android',
          restrictedPackages: restricted,
          remainingSeconds: 30,
        ),
        isTrue,
      );
    });

    test('does not consume time for unselected apps', () {
      expect(
        policy.shouldConsumeTime(
          foregroundPackage: 'com.whatsapp',
          restrictedPackages: restricted,
          remainingSeconds: 30,
        ),
        isFalse,
      );
    });

    test('does not consume time when remaining is zero', () {
      expect(
        policy.shouldConsumeTime(
          foregroundPackage: 'com.instagram.android',
          restrictedPackages: restricted,
          remainingSeconds: 0,
        ),
        isFalse,
      );
    });

    test('shows blocked screen for selected apps at zero time', () {
      expect(
        policy.shouldShowBlockedScreen(
          foregroundPackage: 'com.instagram.android',
          restrictedPackages: restricted,
          remainingSeconds: 0,
        ),
        isTrue,
      );
    });

    test('does not block unselected apps at zero time', () {
      expect(
        policy.shouldShowBlockedScreen(
          foregroundPackage: 'com.whatsapp',
          restrictedPackages: restricted,
          remainingSeconds: 0,
        ),
        isFalse,
      );
    });

    test('does not block selected apps while time remains', () {
      expect(
        policy.shouldShowBlockedScreen(
          foregroundPackage: 'com.instagram.android',
          restrictedPackages: restricted,
          remainingSeconds: 15,
        ),
        isFalse,
      );
    });

    test('runs service only when apps are selected and usage access is granted', () {
      expect(
        policy.shouldRunService(
          restrictedPackages: restricted,
          hasUsageAccess: true,
        ),
        isTrue,
      );
      expect(
        policy.shouldRunService(
          restrictedPackages: restricted,
          hasUsageAccess: false,
        ),
        isFalse,
      );
      expect(
        policy.shouldRunService(
          restrictedPackages: const [],
          hasUsageAccess: true,
        ),
        isFalse,
      );
    });
  });
}
