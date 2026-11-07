import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_theme.dart';
import 'pressable.dart';

enum PillStyle { solid, signal, outline, danger }

class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = PillStyle.solid,
    this.icon,
    this.loading = false,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final PillStyle style;
  final IconData? icon;
  final bool loading;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (fill, foreground) = switch (style) {
      PillStyle.solid => (p.ink, p.canvas),
      PillStyle.signal => (p.signal, p.signalInk),
      PillStyle.outline => (Colors.transparent, p.ink),
      PillStyle.danger => (p.danger, p.canvas),
    };
    final enabled = onPressed != null && !loading;

    return Pressable(
      onTap: enabled ? onPressed : null,
      semanticLabel: label,
      child: AnimatedOpacity(
        opacity: onPressed == null ? 0.4 : 1,
        duration: const Duration(milliseconds: 200),
        child: Container(
          height: compact ? 44 : 58,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: style == PillStyle.outline ? Border.all(color: p.line, width: 1.4) : null,
          ),
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: loading
                ? SizedBox.square(
                    key: const ValueKey('loading'),
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: foreground),
                  )
                : Row(
                    key: const ValueKey('label'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[Icon(icon, size: 19, color: foreground), const SizedBox(width: 8)],
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.labelLarge?.copyWith(color: foreground),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({super.key, required this.icon, required this.onTap, this.label});

  final IconData icon;
  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      scale: 0.9,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: p.surface,
          shape: BoxShape.circle,
          border: Border.all(color: p.line),
        ),
        child: Icon(icon, size: 20, color: p.ink),
      ),
    );
  }
}
