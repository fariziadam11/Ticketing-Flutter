import 'package:flutter/material.dart';

/// Carbon-like light theme (mendekati Carbon g10) untuk Flutter.
///
/// Ini bukan implementasi resmi Carbon, tapi meniru:
/// - Warna surface, border, dan text
/// - Style button dan input
/// - Radius dan spacing
class CarbonTheme {
  // Warna utama (biru, mendekati Carbon interactive color)
  static const Color primary = Color(0xFF0F62FE);
  static const Color primaryHover = Color(0xFF0353E9);

  // Background & surface (g10)
  static const Color background = Color(0xFFF4F4F4); // ui-background
  static const Color layer = Colors.white; // layer 01

  // Teks
  static const Color textPrimary = Color(0xFF161616);
  static const Color textSecondary = Color(0xFF525252);

  // Border
  static const Color borderSubtle = Color(0xFFDDE1E6);
  static const Color borderStrong = Color(0xFF8D8D8D);

  // Support (error, success, warning, info)
  static const Color supportError = Color(0xFFDA1E28);
  static const Color supportSuccess = Color(0xFF24A148);
  static const Color supportWarning = Color(0xFFF1C21B);
  static const Color supportInfo = Color(0xFF0043CE);

  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      secondary: primaryHover,
      onSecondary: Colors.white,
      error: supportError,
      onError: Colors.white,
      surface: layer,
      onSurface: textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      visualDensity: VisualDensity.standard,
      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: layer,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      // Card
      cardTheme: const CardThemeData(
        color: layer,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          side: BorderSide(color: borderSubtle),
        ),
        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: layer,
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: textSecondary, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: supportError, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: supportError, width: 1.4),
        ),
      ),
      // Elevated button (primary)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      // Outlined / secondary buttons bisa diatur via OutlinedButtonTheme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: borderSubtle),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      // Text
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontSize: 14, color: textPrimary),
        bodySmall: TextStyle(fontSize: 12, color: textSecondary),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      dividerColor: borderSubtle,
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
