import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../di/providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerManager = ref.watch(timerManagerProvider);
    
    return ListenableBuilder(
      listenable: timerManager,
      builder: (context, child) {
        final remainingSeconds = timerManager.remainingSeconds;
        
        // Format mm:ss
        final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
        final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');
        final remainingTime = '$minutes:$seconds';
        
        const timeRemainingLabel = 'TIME REMAINING';
        final progressRatio = remainingSeconds > 0 ? 1.0 : 0.0; // Dynamic based on max possible time in future

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarColor: Colors.black,
            systemNavigationBarIconBrightness: Brightness.light,
          ),
          child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Top bar with Restricted Apps shortcut
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const SizedBox(width: 48),
                              IconButton(
                                icon: const Icon(Icons.shield_outlined, color: Colors.white70, size: 24),
                                tooltip: 'Restricted Apps',
                                onPressed: () => context.push('/restricted-apps'),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // TOP / MIDDLE: Large remaining time
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            transitionBuilder: (child, animation) =>
                                FadeTransition(opacity: animation, child: child),
                            child: Text(
                              remainingTime,
                              key: ValueKey(remainingTime),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: constraints.maxWidth < 380 ? 70 : 88,
                                fontWeight: FontWeight.w200,
                                letterSpacing: -3,
                                height: 1.0,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Below: TIME REMAINING
                          const Text(
                            timeRemainingLabel,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 4.0,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Horizontal time / progress bar
                          SizedBox(
                            width: 196,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: progressRatio,
                                minHeight: 3.5,
                                backgroundColor: Colors.white12,
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ),

                          const Spacer(),

                          // CENTER: Large PUSH-UPS button
                          _PushUpsActionButton(
                            onPressed: () => context.push('/exercise'),
                          ),

                          const SizedBox(height: 14),

                          // Below: EARN TIME
                          const Text(
                            'EARN TIME',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 3.0,
                            ),
                          ),

                          const Spacer(),

                          // BOTTOM SHORTCUTS (Samsung lock screen inspired)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Bottom-left: Camera / exercise shortcut
                              _LockScreenShortcut(
                                icon: Icons.camera_alt_outlined,
                                semanticLabel: 'Camera exercise shortcut',
                                onTap: () => context.push('/exercise'),
                              ),

                              // Bottom-right: Navigation / progress shortcut
                              _LockScreenShortcut(
                                icon: Icons.bar_chart_rounded,
                                semanticLabel: 'Progress and statistics shortcut',
                                onTap: () => context.push('/progress'),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
      },
    );
  }
}

class _PushUpsActionButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _PushUpsActionButton({required this.onPressed});

  @override
  State<_PushUpsActionButton> createState() => _PushUpsActionButtonState();
}

class _PushUpsActionButtonState extends State<_PushUpsActionButton> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    widget.onPressed();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Push-ups action button',
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
          child: Container(
            width: 230,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Text(
              'PUSH-UPS',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LockScreenShortcut extends StatefulWidget {
  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  const _LockScreenShortcut({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  @override
  State<_LockScreenShortcut> createState() => _LockScreenShortcutState();
}

class _LockScreenShortcutState extends State<_LockScreenShortcut> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.90 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.08),
              border: Border.all(
                color: Colors.white24,
                width: 1.0,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              widget.icon,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
