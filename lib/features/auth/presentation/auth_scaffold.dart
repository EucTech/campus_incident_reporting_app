import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/pill_button.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.title, required this.subtitle, required this.children});

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: RoundIconButton(
                  icon: Icons.arrow_back_rounded,
                  label: 'Back',
                  onTap: () => context.canPop() ? context.pop() : context.go('/welcome'),
                ),
              ),
              const SizedBox(height: 32),
              Text(title, style: context.text.displayMedium)
                  .animate()
                  .fadeIn(duration: 350.ms)
                  .slideY(begin: 0.2, curve: Curves.easeOutCubic),
              const SizedBox(height: 10),
              Text(subtitle, style: context.text.bodyLarge?.copyWith(color: context.palette.muted))
                  .animate()
                  .fadeIn(delay: 80.ms, duration: 350.ms),
              const SizedBox(height: 32),
              ...children
                  .animate(interval: 60.ms, delay: 120.ms)
                  .fadeIn(duration: 320.ms)
                  .slideY(begin: 0.12, curve: Curves.easeOutCubic),
            ],
          ),
        ),
      ),
    );
  }
}
