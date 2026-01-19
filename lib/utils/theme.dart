import 'package:flutter/material.dart';
import 'package:facecode/utils/constants.dart';

/// App theme configuration - Clean Minimal Style
class AppTheme {
  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    return base.copyWith(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF141417), // soft dark gray

      colorScheme: base.colorScheme.copyWith(
        primary: AppConstants.primaryColor,
        secondary: AppConstants.primaryColor,
        surface: AppConstants.surfaceColor,
        onPrimary: Colors.white,
        onSurface: AppConstants.textPrimary,
      ),

      // Card Theme - simple flat cards with subtle shadow
      cardTheme: base.cardTheme.copyWith(
        color: AppConstants.surfaceColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        ),
        margin: const EdgeInsets.symmetric(vertical: AppConstants.smallPadding),
      ),

      // Elevated Button Theme - single primary color, subtle elevation
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, AppConstants.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
          ),
          elevation: 2,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      // Outlined Button Theme - subtle outline in primary
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConstants.primaryColor,
          side: BorderSide(color: AppConstants.primaryColor.withOpacity(0.9)),
          minimumSize: const Size(double.infinity, AppConstants.buttonHeight),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppConstants.primaryColor,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // Input Decoration Theme - subtle
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppConstants.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: AppConstants.textMuted),
      ),

      // App Bar Theme - minimal
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: AppConstants.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),

      // Typography - system font, clean readable sizes
      textTheme: base.textTheme.apply(
        bodyColor: AppConstants.textPrimary,
        displayColor: AppConstants.textPrimary,
      ).copyWith(
        headlineSmall: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        bodyMedium: const TextStyle(fontSize: 14),
        bodySmall: const TextStyle(fontSize: 12, color: AppConstants.textMuted),
      ),

      floatingActionButtonTheme: base.floatingActionButtonTheme.copyWith(
        backgroundColor: AppConstants.primaryColor,
        elevation: 4,
      ),

      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: AppConstants.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      snackBarTheme: base.snackBarTheme.copyWith(
        backgroundColor: AppConstants.surfaceLight,
        contentTextStyle: const TextStyle(color: AppConstants.textPrimary),
      ),

      listTileTheme: base.listTileTheme.copyWith(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      iconTheme: base.iconTheme.copyWith(color: AppConstants.textSecondary, size: 22),

      dividerTheme: base.dividerTheme.copyWith(color: AppConstants.borderColor, thickness: 1),


    );
  }
}
