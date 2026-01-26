import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppThemeMode {
  dark,
  light,
  party,
  cosmetic, // Added for shop themes
}

class AppTheme {
  static const Color _defaultPrimary = Color(0xFF7C4DFF);
  
  static ThemeData getTheme(AppThemeMode mode, {Color? accentColor, Map<String, Color>? customPalette}) {
    final primary = accentColor ?? (customPalette?['primary'] ?? _defaultPrimary);
    
    Brightness brightness;
    Color background;
    Color surface;
    Color textPrimary;

    switch (mode) {
      case AppThemeMode.light:
        brightness = Brightness.light;
        background = const Color(0xFFF5F7FA);
        surface = Colors.white;
        textPrimary = const Color(0xFF1E1E2C);
        break;
      case AppThemeMode.party:
        brightness = Brightness.dark;
        background = const Color(0xFF130022); 
        surface = const Color(0xFF2A0E45);
        textPrimary = Colors.white;
        break;
      case AppThemeMode.cosmetic:
        brightness = Brightness.dark; // Most shop themes are dark for premium feel
        background = customPalette?['background'] ?? const Color(0xFF121212);
        surface = customPalette?['surface'] ?? const Color(0xFF1E1E1E);
        textPrimary = customPalette?['text'] ?? Colors.white;
        break;
      case AppThemeMode.dark:
        brightness = Brightness.dark;
        background = const Color(0xFF121212);
        surface = const Color(0xFF1E1E1E);
        textPrimary = Colors.white;
        break;
    }

    final base = brightness == Brightness.dark ? ThemeData.dark() : ThemeData.light();

    return base.copyWith(
      brightness: brightness,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        secondary: primary, // Simplified for now
        surface: surface,
        onSurface: textPrimary,
      ),

      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),

      cardTheme: base.cardTheme.copyWith(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 8),
      ),
      
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: primary.withValues(alpha: 0.2),
        thumbColor: primary,
        trackHeight: 4,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary.withValues(alpha: 0.5);
          return Colors.grey.withValues(alpha: 0.3);
        }),
      ),
    );
  }
}
