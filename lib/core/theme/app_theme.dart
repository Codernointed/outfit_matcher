import 'package:flutter/material.dart';
import 'package:vestiq/core/theme/vestiq_soft_theme.dart';

/// Provides the app theme data for Vestiq's Soft Glass Hybrid design system.
///
/// All structural tokens (colors, radii, glass, neumorphic shadows, motion)
/// live on [VestiqSoftTheme] which is attached as a [ThemeExtension] to both
/// the light and dark [ThemeData]. Read DESIGN.md for the rationale.
class AppTheme {
  const AppTheme._();

  // ---------------------------------------------------------------------------
  // Brand color (kept here for legacy callers; prefer reading from
  // VestiqSoftTheme via `context.vestiqSoft.primary`).
  // ---------------------------------------------------------------------------
  static const Color _primaryColor = Color(0xFFFF4D6D);

  /// Soft blush -- legacy alias for [VestiqSoftTheme.surfaceVariant].
  static const Color secondaryBackgroundColor = Color(0xFFFAF0EE);

  /// Plum ink -- legacy alias for [VestiqSoftTheme.onSurface].
  static const Color _textPrimaryColor = Color(0xFF1F1B23);

  /// Mist -- legacy alias for [VestiqSoftTheme.onSurfaceVariant].
  static const Color _textSecondaryColor = Color(0xFF7A7480);

  // Public legacy getters preserved for older call-sites.
  static Color get textPrimaryColor => _textPrimaryColor;
  static Color get textSecondaryColor => _textSecondaryColor;

  // ---------------------------------------------------------------------------
  // Light theme
  // ---------------------------------------------------------------------------
  static ThemeData getLightTheme() {
    final soft = VestiqSoftTheme.light;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        primary: _primaryColor,
        onPrimary: Colors.white,
        secondary: soft.primarySoft,
        onSecondary: soft.onPrimarySoft,
        surface: soft.surface,
        onSurface: _textPrimaryColor,
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: soft.surfaceContainer,
        surfaceContainer: soft.surfaceContainer,
        surfaceContainerHigh: soft.surfaceContainerHigh,
        surfaceContainerHighest: soft.surfaceVariant,
        outline: soft.outline,
        outlineVariant: soft.outlineSoft,
        error: soft.error,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: soft.canvas,
      extensions: <ThemeExtension<dynamic>>[soft],
      appBarTheme: AppBarTheme(
        backgroundColor: soft.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _textPrimaryColor),
        titleTextStyle: const TextStyle(
          color: _textPrimaryColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
          letterSpacing: -0.01,
        ),
      ),
      textTheme: _buildTextTheme(_textPrimaryColor, _textSecondaryColor),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
            letterSpacing: 0.01,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryColor,
          minimumSize: const Size(double.infinity, 56),
          side: const BorderSide(color: _primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
            letterSpacing: 0.01,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryColor,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
            letterSpacing: 0.02,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: soft.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: soft.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: soft.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: soft.error, width: 2),
        ),
        hintStyle: const TextStyle(
          color: _textSecondaryColor,
          fontSize: 14,
          fontFamily: 'Roboto',
        ),
        labelStyle: const TextStyle(
          color: _textSecondaryColor,
          fontSize: 14,
          fontFamily: 'Roboto',
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: soft.surfaceContainer,
        selectedColor: soft.primarySoft,
        labelStyle: const TextStyle(
          color: _textPrimaryColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
          letterSpacing: 0.02,
        ),
        secondaryLabelStyle: TextStyle(
          color: soft.onPrimarySoft,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
          letterSpacing: 0.02,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        side: BorderSide.none,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: soft.surface,
        selectedItemColor: _primaryColor,
        unselectedItemColor: _textSecondaryColor,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
        modalElevation: 0,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: soft.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1F1B23),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontFamily: 'Roboto',
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: soft.outlineSoft,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: _textPrimaryColor, size: 22),
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  // ---------------------------------------------------------------------------
  // Dark theme
  // ---------------------------------------------------------------------------
  static ThemeData getDarkTheme() {
    final soft = VestiqSoftTheme.dark;
    const onDarkSurface = Color(0xFFF5F1F7);
    const onDarkSurfaceVariant = Color(0xFFB3ACBA);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: Brightness.dark,
        primary: _primaryColor,
        onPrimary: Colors.white,
        secondary: soft.primarySoft,
        onSecondary: soft.onPrimarySoft,
        surface: soft.surface,
        onSurface: onDarkSurface,
        surfaceContainerLowest: soft.canvas,
        surfaceContainerLow: soft.surfaceContainer,
        surfaceContainer: soft.surfaceContainer,
        surfaceContainerHigh: soft.surfaceContainerHigh,
        surfaceContainerHighest: soft.surfaceVariant,
        outline: soft.outline,
        outlineVariant: soft.outlineSoft,
        error: soft.error,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: soft.canvas,
      extensions: <ThemeExtension<dynamic>>[soft],
      appBarTheme: AppBarTheme(
        backgroundColor: soft.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: onDarkSurface),
        titleTextStyle: const TextStyle(
          color: onDarkSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
          letterSpacing: -0.01,
        ),
      ),
      textTheme: _buildTextTheme(onDarkSurface, onDarkSurfaceVariant),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
            letterSpacing: 0.01,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryColor,
          minimumSize: const Size(double.infinity, 56),
          side: const BorderSide(color: _primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
            letterSpacing: 0.01,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryColor,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
            letterSpacing: 0.02,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: soft.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: soft.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: soft.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: soft.error, width: 2),
        ),
        hintStyle: const TextStyle(
          color: onDarkSurfaceVariant,
          fontSize: 14,
          fontFamily: 'Roboto',
        ),
        labelStyle: const TextStyle(
          color: onDarkSurfaceVariant,
          fontSize: 14,
          fontFamily: 'Roboto',
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: soft.surfaceContainer,
        selectedColor: soft.primarySoft,
        labelStyle: const TextStyle(
          color: onDarkSurface,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
          letterSpacing: 0.02,
        ),
        secondaryLabelStyle: TextStyle(
          color: soft.onPrimarySoft,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
          letterSpacing: 0.02,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        side: BorderSide.none,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: soft.surface,
        selectedItemColor: _primaryColor,
        unselectedItemColor: onDarkSurfaceVariant,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
        modalElevation: 0,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: soft.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: soft.surface,
        contentTextStyle: const TextStyle(
          color: onDarkSurface,
          fontSize: 14,
          fontFamily: 'Roboto',
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: soft.outlineSoft,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: onDarkSurface, size: 22),
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: TextStyle(
        color: primary,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        fontFamily: 'Poppins',
        letterSpacing: -0.03 * 32,
        height: 1.1,
      ),
      displayMedium: TextStyle(
        color: primary,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        fontFamily: 'Poppins',
        letterSpacing: -0.02 * 28,
        height: 1.15,
      ),
      displaySmall: TextStyle(
        color: primary,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        fontFamily: 'Poppins',
        letterSpacing: -0.02 * 24,
        height: 1.15,
      ),
      headlineLarge: TextStyle(
        color: primary,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        fontFamily: 'Poppins',
        letterSpacing: -0.015 * 22,
        height: 1.2,
      ),
      headlineMedium: TextStyle(
        color: primary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        fontFamily: 'Poppins',
        letterSpacing: -0.01 * 20,
        height: 1.2,
      ),
      headlineSmall: TextStyle(
        color: primary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
        height: 1.25,
      ),
      titleLarge: TextStyle(
        color: primary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
        height: 1.3,
      ),
      titleMedium: TextStyle(
        color: primary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
        height: 1.3,
      ),
      titleSmall: TextStyle(
        color: primary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
        letterSpacing: 0.01 * 14,
        height: 1.3,
      ),
      labelLarge: TextStyle(
        color: primary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
        letterSpacing: 0.01 * 16,
      ),
      labelMedium: TextStyle(
        color: primary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
        letterSpacing: 0.02 * 14,
      ),
      labelSmall: TextStyle(
        color: secondary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        fontFamily: 'Poppins',
        letterSpacing: 0.04 * 12,
      ),
      bodyLarge: TextStyle(
        color: primary,
        fontSize: 16,
        fontFamily: 'Roboto',
        height: 1.55,
      ),
      bodyMedium: TextStyle(
        color: secondary,
        fontSize: 14,
        fontFamily: 'Roboto',
        height: 1.5,
      ),
      bodySmall: TextStyle(
        color: secondary,
        fontSize: 12,
        fontFamily: 'Roboto',
        height: 1.45,
      ),
    );
  }
}
