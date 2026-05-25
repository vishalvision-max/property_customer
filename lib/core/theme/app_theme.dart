import 'dart:ui';

import 'package:flutter/material.dart';

class AppTheme {
  static TextTheme _scaleText(TextTheme input, double factor) {
    TextStyle? scale(TextStyle? s) {
      final size = s?.fontSize;
      if (s == null || size == null) return s;
      return s.copyWith(fontSize: size * factor);
    }

    return input.copyWith(
      displayLarge: scale(input.displayLarge),
      displayMedium: scale(input.displayMedium),
      displaySmall: scale(input.displaySmall),
      headlineLarge: scale(input.headlineLarge),
      headlineMedium: scale(input.headlineMedium),
      headlineSmall: scale(input.headlineSmall),
      titleLarge: scale(input.titleLarge),
      titleMedium: scale(input.titleMedium),
      titleSmall: scale(input.titleSmall),
      bodyLarge: scale(input.bodyLarge),
      bodyMedium: scale(input.bodyMedium),
      bodySmall: scale(input.bodySmall),
      labelLarge: scale(input.labelLarge),
      labelMedium: scale(input.labelMedium),
      labelSmall: scale(input.labelSmall),
    );
  }

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7C3AED)),
    );

    return base.copyWith(
      scaffoldBackgroundColor: Colors.white,
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      textTheme: _scaleText(
        base.textTheme.apply(
          bodyColor: const Color(0xFF0F172A),
          displayColor: const Color(0xFF0F172A),
        ),
        0.94,
      ),
      visualDensity: VisualDensity.compact,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF4F6FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF7C3AED),
        brightness: Brightness.dark,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF070B14),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      textTheme: _scaleText(
        base.textTheme.apply(
          bodyColor: const Color(0xFFE7EAF2),
          displayColor: const Color(0xFFE7EAF2),
        ),
        0.94,
      ),
      visualDensity: VisualDensity.compact,
      dividerColor: const Color(0xFF1A2337),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0E1626).withValues(alpha: 0.96),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  static BoxShadow softShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxShadow(
      color: (isDark ? Colors.black : const Color(0xFF0F172A)).withValues(alpha: isDark ? 0.35 : 0.08),
      blurRadius: 28,
      offset: const Offset(0, 12),
    );
  }

  static ImageFilter glassBlur() => ImageFilter.blur(sigmaX: 14, sigmaY: 14);
}
