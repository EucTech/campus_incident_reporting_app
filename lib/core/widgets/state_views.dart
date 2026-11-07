import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_palette.dart';
import '../theme/app_theme.dart';
import 'pulse_rings.dart';
import 'pill_button.dart';

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.title, required this.message, this.action});

  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PulseRings(
            size: 110,
            color: p.faint,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: p.muted, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(height: 16),
          Text(title, style: context.text.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(message, style: context.text.bodyMedium, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    ).animate().fadeIn(duration: 350.ms);
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyView(
      title: 'Could not load this',
      message: message,
      action: PillButton(label: 'Try again', onPressed: onRetry, compact: true),
    );
  }
}

class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 4, this.height = 104});

  final int count;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      children: [
        for (var i = 0; i < count; i++)
          Container(
            height: height,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 1400.ms, color: p.raised),
      ],
    );
  }
}

final messengerKey = GlobalKey<ScaffoldMessengerState>();

void showAppMessage(String message) {
  messengerKey.currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
