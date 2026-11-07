import 'package:flutter/material.dart';

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.canvas,
    required this.surface,
    required this.raised,
    required this.line,
    required this.ink,
    required this.muted,
    required this.faint,
    required this.signal,
    required this.signalInk,
    required this.signalText,
    required this.amber,
    required this.sky,
    required this.danger,
  });

  final Color canvas;
  final Color surface;
  final Color raised;
  final Color line;
  final Color ink;
  final Color muted;
  final Color faint;
  final Color signal;
  final Color signalInk;
  final Color signalText;
  final Color amber;
  final Color sky;
  final Color danger;

  static const dark = AppPalette(
    canvas: Color(0xFF0A0A0B),
    surface: Color(0xFF141416),
    raised: Color(0xFF1E1E21),
    line: Color(0xFF2B2B2F),
    ink: Color(0xFFF6F6F3),
    muted: Color(0xFFA0A0A6),
    faint: Color(0xFF66666D),
    signal: Color(0xFFC6F135),
    signalInk: Color(0xFF0A0A0B),
    signalText: Color(0xFFC6F135),
    amber: Color(0xFFF2B84B),
    sky: Color(0xFF7FB8FF),
    danger: Color(0xFFFF6B5E),
  );

  static const light = AppPalette(
    canvas: Color(0xFFF3F3EF),
    surface: Color(0xFFFFFFFF),
    raised: Color(0xFFE9E9E4),
    line: Color(0xFFDCDCD6),
    ink: Color(0xFF0B0B0C),
    muted: Color(0xFF5C5C62),
    faint: Color(0xFF8F8F96),
    signal: Color(0xFFC6F135),
    signalInk: Color(0xFF0A0A0B),
    signalText: Color(0xFF4F6500),
    amber: Color(0xFF9A6500),
    sky: Color(0xFF1F5FB0),
    danger: Color(0xFFC8331F),
  );

  @override
  AppPalette copyWith({Color? canvas, Color? surface, Color? ink}) => AppPalette(
    canvas: canvas ?? this.canvas,
    surface: surface ?? this.surface,
    raised: raised,
    line: line,
    ink: ink ?? this.ink,
    muted: muted,
    faint: faint,
    signal: signal,
    signalInk: signalInk,
    signalText: signalText,
    amber: amber,
    sky: sky,
    danger: danger,
  );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      canvas: mix(canvas, other.canvas),
      surface: mix(surface, other.surface),
      raised: mix(raised, other.raised),
      line: mix(line, other.line),
      ink: mix(ink, other.ink),
      muted: mix(muted, other.muted),
      faint: mix(faint, other.faint),
      signal: mix(signal, other.signal),
      signalInk: mix(signalInk, other.signalInk),
      signalText: mix(signalText, other.signalText),
      amber: mix(amber, other.amber),
      sky: mix(sky, other.sky),
      danger: mix(danger, other.danger),
    );
  }
}

extension PaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
  TextTheme get text => Theme.of(this).textTheme;
}
