import 'package:flutter/material.dart';

class AdminTheme {
  static const Color primaryDark = Color(0xFF1E293B); // Slate 800
  static const Color primaryAccent = Color(0xFF2563EB); // Blue 600
  static const Color backgroundLight = Color(0xFFF8FAFC); // Slate 50
  static const Color cardLight = Colors.white;
  static const Color borderLight = Color(0xFFE2E8F0); // Slate 200

  // Status colors
  static const Color statusDraft = Color(0xFF64748B); // Slate
  static const Color statusReview = Color(0xFFD97706); // Amber
  static const Color statusVerified = Color(0xFF16A34A); // Green
  static const Color statusRejected = Color(0xFFDC2626); // Red

  // Role badge colors
  static const Color roleSuperadmin = Color(0xFF7C3AED); // Violet
  static const Color roleReviewer = Color(0xFF2563EB); // Blue
  static const Color roleEditor = Color(0xFF0D9488); // Teal

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryAccent,
        surface: cardLight,
      ),
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: borderLight),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: primaryAccent, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
