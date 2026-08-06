import 'package:flutter/material.dart';

class AppTheme {
  // Light Theme Colors
  static const Color primaryLight = Color(0xFF2563EB); // Vibrant Blue
  static const Color primaryContainerLight = Color(0xFFDBEAFE);
  static const Color secondaryLight = Color(0xFF60A5FA); // Soft Sky Blue
  static const Color backgroundLight = Color(0xFFF8FAFC); // Clean Slate Gray-White
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF0F172A); // Charcoal Slate
  static const Color textSecondaryLight = Color(0xFF64748B); // Muted Blue Gray

  // Dark Theme Colors
  static const Color primaryDark = Color(0xFF3B82F6);
  static const Color primaryContainerDark = Color(0xFF1E3A8A);
  static const Color secondaryDark = Color(0xFF60A5FA);
  static const Color backgroundDark = Color(0xFF0F172A); // Rich Navy-Charcoal
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryLight,
        primaryContainer: primaryContainerLight,
        secondary: secondaryLight,
        surface: surfaceLight,
        onPrimary: Colors.white,
        onSurface: textPrimaryLight,
      ),
      scaffoldBackgroundColor: backgroundLight,
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundLight,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimaryLight),
        titleTextStyle: TextStyle(
          color: textPrimaryLight,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(color: textPrimaryLight, fontWeight: FontWeight.bold, fontSize: 28),
        titleLarge: TextStyle(color: textPrimaryLight, fontWeight: FontWeight.w600, fontSize: 20),
        titleMedium: TextStyle(color: textPrimaryLight, fontWeight: FontWeight.w500, fontSize: 16),
        bodyLarge: TextStyle(color: textPrimaryLight, fontSize: 16),
        bodyMedium: TextStyle(color: textSecondaryLight, fontSize: 14),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryLight, width: 2),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryDark,
        primaryContainer: primaryContainerDark,
        secondary: secondaryDark,
        surface: surfaceDark,
        onPrimary: Colors.white,
        onSurface: textPrimaryDark,
      ),
      scaffoldBackgroundColor: backgroundDark,
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundDark,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimaryDark),
        titleTextStyle: TextStyle(
          color: textPrimaryDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(color: textPrimaryDark, fontWeight: FontWeight.bold, fontSize: 28),
        titleLarge: TextStyle(color: textPrimaryDark, fontWeight: FontWeight.w600, fontSize: 20),
        titleMedium: TextStyle(color: textPrimaryDark, fontWeight: FontWeight.w500, fontSize: 16),
        bodyLarge: TextStyle(color: textPrimaryDark, fontSize: 16),
        bodyMedium: TextStyle(color: textSecondaryDark, fontSize: 14),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryDark, width: 2),
        ),
      ),
    );
  }

  // Helper for premium glassmorphism styling
  static BoxDecoration glassDecoration({
    required BuildContext context,
    double opacity = 0.6,
    double borderRadius = 16,
    double blur = 10,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: (isDark ? const Color(0xFF1E293B) : Colors.white).withOpacity(opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 24,
          offset: const Offset(0, 8),
        )
      ]
    );
  }
}
