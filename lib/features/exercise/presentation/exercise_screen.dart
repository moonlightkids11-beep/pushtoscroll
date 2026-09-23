import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../di/providers.dart';
import 'exercise_controller.dart';

class ExerciseScreen extends ConsumerStatefulWidget {
  const ExerciseScreen({super.key});

  @override
  ConsumerState<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends ConsumerState<ExerciseScreen> {
  late final ExerciseController _controller;
  String? _errorMessage;
  bool _isFinishing = false;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(exerciseControllerProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSession());
  }

  Future<void> _startSession() async {
    try {
      await _controller.startSession();
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Camera tracking is unavailable.');
      }
    }
  }

  Future<void> _returnHome() async {
    if (_isFinishing) return;
    _isFinishing = true;
    // End the session in the background so navigation is not blocked.
    // dispose() will ensure cleanup even if this hasn't finished yet.
    unawaited(_controller.endSession());
    if (mounted) context.go('/');
  }

  @override
  void dispose() {
    unawaited(_controller.endSession());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_returnHome());
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: 'Return Home',
            onPressed: _returnHome,
          ),
          title: const Text('PUSH-UP CAMERA', style: TextStyle(letterSpacing: 2.0, fontSize: 16)),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) => Column(
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        border: Border.all(color: Colors.white24, width: 1.0),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.white38),
                          const SizedBox(height: 16),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            transitionBuilder: (child, animation) =>
                                FadeTransition(opacity: animation, child: child),
                            child: Text(
                              '${_controller.pushUps}',
                              key: ValueKey(_controller.pushUps),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 56,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Text('PUSH-UPS', style: TextStyle(color: Colors.white70, letterSpacing: 1.5, fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage ?? 'Tracking: ${_controller.currentState.name.toUpperCase()}',
                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isFinishing ? null : _returnHome,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                      ),
                      child: const Text('FINISH & RETURN HOME', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
