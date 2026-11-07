import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_palette.dart';

abstract final class AppRadius {
  static const card = 26.0;
  static const tile = 18.0;
  static const pill = 100.0;
}

abstract final class AppTheme {
  static ThemeData dark() => _build(AppPalette.dark, Brightness.dark);
  static ThemeData light() => _build(AppPalette.light, Brightness.light);

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final display = GoogleFonts.bricolageGrotesque(color: p.ink);
    final body = GoogleFonts.manrope(color: p.ink);

    final textTheme = TextTheme(
      displayLarge: display.copyWith(fontSize: 52, height: 1, fontWeight: FontWeight.w800, letterSpacing: -2),
      displayMedium: display.copyWith(fontSize: 38, height: 1.05, fontWeight: FontWeight.w800, letterSpacing: -1.4),
      headlineMedium: display.copyWith(fontSize: 28, height: 1.1, fontWeight: FontWeight.w700, letterSpacing: -0.8),
      titleLarge: display.copyWith(fontSize: 21, height: 1.2, fontWeight: FontWeight.w700, letterSpacing: -0.4),
      titleMedium: body.copyWith(fontSize: 16, height: 1.3, fontWeight: FontWeight.w700),
      bodyLarge: body.copyWith(fontSize: 15, height: 1.55, fontWeight: FontWeight.w500),
      bodyMedium: body.copyWith(fontSize: 13.5, height: 1.45, fontWeight: FontWeight.w500, color: p.muted),
      labelLarge: body.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
      labelMedium: body.copyWith(fontSize: 12.5, fontWeight: FontWeight.w700),
      labelSmall: body.copyWith(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.9, color: p.muted),
    );

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: p.ink,
      onPrimary: p.canvas,
      secondary: p.signal,
      onSecondary: p.signalInk,
      error: p.danger,
      onError: p.canvas,
      surface: p.canvas,
      onSurface: p.ink,
    );

    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.tile),
      borderSide: BorderSide(color: p.line),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: p.canvas,
      textTheme: textTheme,
      extensions: [p],
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.ink,
        selectionColor: p.signal.withValues(alpha: 0.4),
        selectionHandleColor: p.ink,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: p.ink,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        hintStyle: textTheme.bodyMedium?.copyWith(color: p.faint),
        errorStyle: textTheme.labelMedium?.copyWith(color: p.danger),
        errorMaxLines: 2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(borderSide: BorderSide(color: p.ink, width: 1.4)),
        errorBorder: fieldBorder.copyWith(borderSide: BorderSide(color: p.danger)),
        focusedErrorBorder: fieldBorder.copyWith(borderSide: BorderSide(color: p.danger, width: 1.4)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.ink,
        contentTextStyle: textTheme.labelMedium?.copyWith(color: p.canvas),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.tile)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: p.line,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
