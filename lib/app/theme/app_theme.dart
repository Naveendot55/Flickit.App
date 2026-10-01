import 'package:flutter/material.dart';

/// Premium dark sports-tech design system for Flickit.
class AppTheme {
  const AppTheme._();

  // Primary Sports Tech Palette
  static const Color background = Color(0xFF0A0D14);
  static const Color surface = Color(0xFF131824);
  static const Color surfaceCard = Color(0xFF1A2234);
  static const Color surfaceGlass = Color(0xCC131824);

  // Vibrant Accents
  static const Color neonGreen = Color(0xFF00FFA3);
  static const Color electricLime = Color(0xFF00E676);
  static const Color cyanAccent = Color(0xFF00E5FF);
  static const Color footballOrange = Color(0xFFFF9100);
  static const Color errorRed = Color(0xFFFF3366);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Gradients
  static const LinearGradient accentGradient = LinearGradient(
    colors: [neonGreen, cyanAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient fireGradient = LinearGradient(
    colors: [footballOrange, Color(0xFFFF5252)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF1A2338), Color(0xFF111728)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: neonGreen,
      colorScheme: const ColorScheme.dark(
        primary: neonGreen,
        secondary: cyanAccent,
        surface: surface,
        error: errorRed,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
