import 'package:flutter/material.dart';

/// Class that provides the app theme data
class AppTheme {
  /// Private constructor to prevent instantiation
  const AppTheme._();

  /// Primary color based on the app's design (pink/red color seen in buttons)
  static const Color _primaryColor = Color(0xFFFF4D6D);

  /// Background color for the app (light color in the mockups)
  static const Color _backgroundColor = Color(0xFFFCFCFC);

  /// Secondary background color (light pink color seen in some backgrounds)
  static const Color secondaryBackgroundColor = Color(0xFFFFF0F3);

  /// Text color for main headings and important text
  static const Color _textPrimaryColor = Color(0xFF1A1A2C);

  /// Text color for secondary text like descriptions
  static const Color _textSecondaryColor = Color(0xFF8A8A8F);

  /// Get the light theme for the app
  static ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        primary: _primaryColor,
        onPrimary: Colors.white,
        secondary: _primaryColor.withOpacity(0.8),
        onSecondary: Colors.white,
        background: _backgroundColor,
        onBackground: _textPrimaryColor,
        surface: Colors.white,
        onSurface: _textPrimaryColor,
        error: Colors.red,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: _backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: _textPrimaryColor),
        titleTextStyle: TextStyle(
          color: _textPrimaryColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: _textPrimaryColor,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: _textPrimaryColor,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: _textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(color: _textPrimaryColor, fontSize: 16),
        bodyMedium: TextStyle(color: _textSecondaryColor, fontSize: 14),
        bodySmall: TextStyle(color: _textSecondaryColor, fontSize: 12),
        titleLarge: TextStyle(
          color: _textPrimaryColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          color: _textPrimaryColor,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: _textPrimaryColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryColor,
          minimumSize: const Size(double.infinity, 56),
          side: const BorderSide(color: _primaryColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryColor,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _primaryColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        hintStyle: const TextStyle(color: _textSecondaryColor, fontSize: 14),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: _primaryColor,
        unselectedItemColor: _textSecondaryColor,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFEEEEEE),
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// Primary text color
  static Color get textPrimaryColor => _textPrimaryColor;

  /// Secondary text color
  static Color get textSecondaryColor => _textSecondaryColor;
}
