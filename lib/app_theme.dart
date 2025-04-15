import 'package:flutter/material.dart';

class AppTheme {
  static const Color seed1 = Color(0xFF122640);
  static const Color seed2 = Color(0xFFBF8641);
  static const Color seed3 = Color(0xFF1B3659);
  static const Color seed4 = Color(0xFF593E25);

  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.light(
        primary: seed1,
        secondary: seed2,
        surface: Colors.white,
        background: Colors.grey.shade200,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: seed3,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
        ),
        iconTheme: IconThemeData(color: Colors.white), // Back arrow (and other icons) are white
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: seed2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: seed1,
          foregroundColor: Colors.white, // Button text will be white for better readability
        ),
      ),
    );
  }
}
