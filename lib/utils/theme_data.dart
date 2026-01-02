import 'package:flutter/material.dart';

/// Pet Walk App Design System
/// Clean White & Vivid Green Theme
class AppTheme {
  // Colors
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundOffWhite = Color(0xFFF9FCF9);
  static const Color primaryGreen = Color(0xFF00C853); // Vivid Green
  static const Color primaryGreenAlt = Color(0xFF4CAF50); // Alternative Green
  static const Color secondaryMint = Color(0xFFE8F5E9); // Pale Mint
  static const Color textTitle = Color(0xFF222222);
  static const Color textBody = Color(0xFF666666);

  // Card Design
  static const double cardElevation = 4.0;
  static const double cardRadius = 20.0;
  static Color cardShadowColor = primaryGreen.withValues(alpha: 0.1);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light, // Light mode only
      fontFamily: 'Paperlogy', // 페이퍼로지 폰트
      
      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        secondary: secondaryMint,
        surface: backgroundWhite,
        error: Colors.red,
        onPrimary: Colors.white,
        onSecondary: textTitle,
        onSurface: textTitle,
        onError: Colors.white,
      ),

      // Scaffold
      scaffoldBackgroundColor: backgroundOffWhite,

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundWhite,
        foregroundColor: textTitle,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textTitle,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Paperlogy',
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        shadowColor: cardShadowColor,
        color: backgroundWhite,
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: textTitle,
          fontWeight: FontWeight.bold,
          fontFamily: 'Paperlogy',
        ),
        displayMedium: TextStyle(
          color: textTitle,
          fontWeight: FontWeight.bold,
          fontFamily: 'Paperlogy',
        ),
        displaySmall: TextStyle(
          color: textTitle,
          fontWeight: FontWeight.bold,
          fontFamily: 'Paperlogy',
        ),
        headlineLarge: TextStyle(
          color: textTitle,
          fontWeight: FontWeight.bold,
          fontFamily: 'Paperlogy',
        ),
        headlineMedium: TextStyle(
          color: textTitle,
          fontWeight: FontWeight.bold,
          fontFamily: 'Paperlogy',
        ),
        headlineSmall: TextStyle(
          color: textTitle,
          fontWeight: FontWeight.bold,
          fontFamily: 'Paperlogy',
        ),
        titleLarge: TextStyle(
          color: textTitle,
          fontWeight: FontWeight.bold,
          fontFamily: 'Paperlogy',
        ),
        titleMedium: TextStyle(
          color: textTitle,
          fontWeight: FontWeight.bold,
          fontFamily: 'Paperlogy',
        ),
        titleSmall: TextStyle(
          color: textTitle,
          fontWeight: FontWeight.w600,
          fontFamily: 'Paperlogy',
        ),
        bodyLarge: TextStyle(
          color: textBody,
          fontFamily: 'Paperlogy',
        ),
        bodyMedium: TextStyle(
          color: textBody,
          fontFamily: 'Paperlogy',
        ),
        bodySmall: TextStyle(
          color: textBody,
          fontFamily: 'Paperlogy',
        ),
        labelLarge: TextStyle(
          fontFamily: 'Paperlogy',
        ),
        labelMedium: TextStyle(
          fontFamily: 'Paperlogy',
        ),
        labelSmall: TextStyle(
          fontFamily: 'Paperlogy',
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Paperlogy',
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Paperlogy',
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
            fontFamily: 'Paperlogy',
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: const BorderSide(color: primaryGreen, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
            fontFamily: 'Paperlogy',
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(
            fontFamily: 'Paperlogy',
          ),
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: backgroundWhite,
        selectedItemColor: primaryGreen,
        unselectedItemColor: textBody,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontFamily: 'Paperlogy',
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Paperlogy',
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: textBody,
        size: 24,
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: 'Paperlogy',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textTitle,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: 'Paperlogy',
          color: textBody,
        ),
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        contentTextStyle: const TextStyle(
          fontFamily: 'Paperlogy',
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

