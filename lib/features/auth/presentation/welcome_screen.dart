import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/pulse_rings.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/pressable.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ClipRect(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  OverflowBox(
                    maxWidth: 620,
                    maxHeight: 620,
                    child: PulseRings(
                      size: 600,
                      color: p.signalText,
                      rings: 5,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(color: p.signal, shape: BoxShape.circle),
                      ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + 18,
                    left: 24,
                    child: Text('Pulse', style: context.text.titleLarge),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, 32, 24, MediaQuery.paddingOf(context).bottom + 24),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.card + 10)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('See it.\nFlag it.\nFixed.', style: context.text.displayLarge),
                const SizedBox(height: 14),
                Text(
                  'Report campus issues in seconds and follow every one until it is resolved.',
                  style: context.text.bodyLarge?.copyWith(color: p.muted),
                ),
                const SizedBox(height: 26),
                PillButton(label: 'Create account', onPressed: () => context.push('/register')),
                const SizedBox(height: 10),
                PillButton(label: 'Log in', style: PillStyle.outline, onPressed: () => context.push('/login')),
                const SizedBox(height: 6),
                Pressable(
                  onTap: () => context.push('/register-school'),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      'Run a school? Register it on Pulse',
                      textAlign: TextAlign.center,
                      style: context.text.labelMedium?.copyWith(color: p.muted),
                    ),
                  ),
                ),
              ],
            ),
          ).animate().slideY(begin: 0.25, duration: 550.ms, curve: Curves.easeOutCubic).fadeIn(),
        ],
      ),
    );
  }
}
