import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/permission_state.dart';
import '../domain/permission_type.dart';
import 'onboarding_controller.dart';
import 'permission_controller.dart';

class PermissionSetupScreen extends ConsumerStatefulWidget {
  const PermissionSetupScreen({super.key});

  @override
  ConsumerState<PermissionSetupScreen> createState() => _PermissionSetupScreenState();
}

class _PermissionSetupScreenState extends ConsumerState<PermissionSetupScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-query real Android permission status when user returns from settings
      ref.read(permissionControllerProvider.notifier).refreshPermissions();
    }
  }

  Future<void> _handleFinish() async {
    final state = ref.read(permissionControllerProvider);
    final allGranted = state.areAllGranted;

    if (!allGranted) {
      final shouldProceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Permissions Incomplete', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Some permissions are not yet enabled on your device. '
            'Earn Your Scroll requires Camera for push-up detection and Usage/Accessibility '
            'to restrict selected apps.\n\nYou can still configure settings later.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('STAY & SETUP', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              child: const Text('PROCEED ANYWAY'),
            ),
          ],
        ),
      );

      if (shouldProceed != true) return;
    }

    await ref.read(onboardingControllerProvider.notifier).completeOnboarding();
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final permState = ref.watch(permissionControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PERMISSIONS',
          style: TextStyle(letterSpacing: 2.0, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Status',
            onPressed: () {
              ref.read(permissionControllerProvider.notifier).refreshPermissions();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'GET READY',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Setup Permissions',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w300, letterSpacing: -0.5),
              ),
              const SizedBox(height: 8),
              const Text(
                'To detect push-ups and enforce your screen time balance, Android requires the following authorizations:',
                style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    _PermissionCard(
                      icon: Icons.camera_alt_outlined,
                      title: 'CAMERA',
                      explanation: 'Used for on-device pose detection to analyze push-up form.',
                      state: permState.permissions[AppPermissionType.camera] ??
                          PermissionState.notDetermined,
                      buttonText: 'GRANT CAMERA',
                      onRequest: () {
                        ref
                            .read(permissionControllerProvider.notifier)
                            .requestPermission(AppPermissionType.camera);
                      },
                    ),
                    const SizedBox(height: 16),
                    _PermissionCard(
                      icon: Icons.query_stats_outlined,
                      title: 'USAGE ACCESS',
                      explanation: 'Used to identify selected restricted apps and measure screen time.',
                      state: permState.permissions[AppPermissionType.usageAccess] ??
                          PermissionState.notDetermined,
                      buttonText: 'OPEN USAGE SETTINGS',
                      onRequest: () {
                        ref
                            .read(permissionControllerProvider.notifier)
                            .requestPermission(AppPermissionType.usageAccess);
                      },
                    ),
                    const SizedBox(height: 16),
                    _PermissionCard(
                      icon: Icons.accessibility_new_outlined,
                      title: 'ACCESSIBILITY',
                      explanation:
                          'Required on Android to reliably detect foreground restricted apps and display the focus intervention screen.',
                      state: permState.permissions[AppPermissionType.accessibility] ??
                          PermissionState.notDetermined,
                      buttonText: 'OPEN ACCESSIBILITY SETTINGS',
                      onRequest: () {
                        ref
                            .read(permissionControllerProvider.notifier)
                            .requestPermission(AppPermissionType.accessibility);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _handleFinish,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child: const Text('FINISH & START EARNING'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String explanation;
  final PermissionState state;
  final String buttonText;
  final VoidCallback onRequest;

  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.explanation,
    required this.state,
    required this.buttonText,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    final isGranted = state == PermissionState.granted;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(
          color: isGranted ? Colors.white70 : Colors.white24,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 24, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              _StatusBadge(isGranted: isGranted),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            explanation,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          if (!isGranted)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onRequest,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(buttonText),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isGranted;

  const _StatusBadge({required this.isGranted});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isGranted ? Colors.white : Colors.transparent,
        border: Border.all(
          color: isGranted ? Colors.white : Colors.white38,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isGranted ? Icons.check : Icons.lock_outline,
            size: 13,
            color: isGranted ? Colors.black : Colors.white70,
          ),
          const SizedBox(width: 4),
          Text(
            isGranted ? 'GRANTED' : 'NOT GRANTED',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: isGranted ? Colors.black : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
