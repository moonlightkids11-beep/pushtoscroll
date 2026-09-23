import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/app_theme_mode.dart';
import 'onboarding_controller.dart';
import 'theme_controller.dart';

class ThemeSelectionScreen extends ConsumerStatefulWidget {
  const ThemeSelectionScreen({super.key});

  @override
  ConsumerState<ThemeSelectionScreen> createState() => _ThemeSelectionScreenState();
}

class _ThemeSelectionScreenState extends ConsumerState<ThemeSelectionScreen> {
  AppThemeMode? _selectedTheme;

  @override
  void initState() {
    super.initState();
    _selectedTheme = ref.read(themeControllerProvider);
  }

  void _onThemeSelected(AppThemeMode theme) {
    setState(() {
      _selectedTheme = theme;
    });
    ref.read(onboardingControllerProvider.notifier).selectTheme(theme);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Text(
                'EARN YOUR SCROLL',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  letterSpacing: 4.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Choose Your Theme',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'A quiet, focused interface built for intentional scrolling.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white60,
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: ListView(
                  children: [
                    _ThemeCard(
                      title: 'DEFAULT THEME',
                      subtitle: 'Standard Android Material interface with modern styling',
                      isSelected: _selectedTheme == AppThemeMode.defaultTheme,
                      onTap: () => _onThemeSelected(AppThemeMode.defaultTheme),
                      previewWidget: _buildDefaultPreview(),
                    ),
                    const SizedBox(height: 20),
                    _ThemeCard(
                      title: 'OUR THEME',
                      badgeText: 'BLACK & WHITE',
                      subtitle: 'Minimalist Samsung-lock-screen-inspired composition for maximum discipline',
                      isSelected: _selectedTheme == AppThemeMode.blackAndWhite,
                      onTap: () => _onThemeSelected(AppThemeMode.blackAndWhite),
                      previewWidget: _buildBWPreview(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _selectedTheme != null
                    ? () {
                        context.push('/permissions');
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child: const Text('CONTINUE'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('00:15:00', style: TextStyle(color: Colors.black, fontSize: 11)),
          ),
          const Icon(Icons.fitness_center_outlined, color: Colors.white, size: 18),
          const Icon(Icons.shield, color: Colors.white70, size: 18),
        ],
      ),
    );
  }

  Widget _buildBWPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.white30, width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '00:15:00',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Text(
            'PUSH-UPS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final String title;
  final String? badgeText;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget previewWidget;

  const _ThemeCard({
    required this.title,
    this.badgeText,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    required this.previewWidget,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.06) : Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      if (badgeText != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badgeText!,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isSelected ? Colors.white : Colors.white38,
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            previewWidget,
          ],
        ),
      ),
    );
  }
}
