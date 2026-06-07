import 'package:flutter/material.dart';

import 'viral_design_tokens.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ViralTokens.black,
      colorScheme: const ColorScheme.dark(
        surface: ViralTokens.surface,
        primary: Color(0xFF8B5CF6),
        secondary: Color(0xFFD946EF),
        onSurface: ViralTokens.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: ViralTokens.textPrimary,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: ViralTokens.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(color: ViralTokens.textSecondary),
        bodyMedium: TextStyle(color: ViralTokens.textSecondary),
      ),
      cardTheme: CardThemeData(
        color: ViralTokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ViralTokens.radiusLg),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ViralTokens.surfaceElevated,
        hintStyle: const TextStyle(color: ViralTokens.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ViralTokens.radiusSm),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
