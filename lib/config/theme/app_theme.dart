import 'package:flutter/material.dart';



class AppTheme {
  // Premium Black & Red Palette
  static const Color primaryRed = Color(0xFFE50914); // Netflix-like Red
  static const Color accentRed = Color(0xFFFF1E1E);
  static const Color darkRed = Color(0xFF8B0000);
  
  static const Color backgroundBlack = Color(0xFF000000);
  static const Color surfaceDark = Color(0xFF121212);
  static const Color surfaceLight = Color(0xFF282828);
  static const Color cardColor = Color(0xFF1E1E1E);
  
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryRed,
      scaffoldBackgroundColor: backgroundBlack,
      cardColor: cardColor,
      
      colorScheme: const ColorScheme.dark(
        primary: primaryRed,
        secondary: accentRed,
        surface: surfaceDark,
        background: backgroundBlack,
        onPrimary: Colors.white,
        onSurface: textPrimary,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent, // For glassmorphism
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xCC000000), // Semi-transparent
        selectedItemColor: primaryRed,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: primaryRed,
        inactiveTrackColor: Colors.grey[800],
        thumbColor: primaryRed,
        overlayColor: primaryRed.withOpacity(0.2),
        trackShape: const RoundedRectSliderTrackShape(),
        trackHeight: 4.0,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
      ),

      /*
      cardTheme: CardTheme(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      */

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryRed,
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRed,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }
}
