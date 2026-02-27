import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const primary = Color(0xFF2F80ED);
  static const secondary = Color(0xFF56CCF2);
  static const textPrimary = Color(0xFF333333);
  static const textSecondary = Color(0xFF828282);
  static const background = Color(0xFFFFFFFF);
  static const inputBackground = Color(0xFFF2F2F2);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    primaryColor: primary,
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
    ),
    textTheme: GoogleFonts.interTextTheme().copyWith(
      displayLarge: const TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
      displayMedium: const TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
      displaySmall: const TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
      bodyLarge: const TextStyle(color: textPrimary, fontSize: 16),
      bodyMedium: const TextStyle(color: textSecondary, fontSize: 14),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF5F7FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 1),
      ),
      labelStyle: const TextStyle(color: textSecondary),
      hintStyle: const TextStyle(color: textSecondary, fontSize: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}