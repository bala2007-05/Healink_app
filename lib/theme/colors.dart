import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primaryBlue = Color(0xFF007BFF);
  static const Color lightBlue = Color(0xFFE6F2FF);
  static const Color teal = Color(0xFF0BB8A8);
  
  // Status Colors
  static const Color danger = Color(0xFFE74C3C);
  static const Color warning = Color(0xFFF1C40F);
  static const Color success = Color(0xFF2ECC71);
  
  // Background Colors
  static const Color background = Color(0xFFF5FAFF);
  static const Color white = Color(0xFFFFFFFF);
  static const Color darkBackground = Color(0xFF121212);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textLight = Color(0xFFFFFFFF);
  
  // Gradient Colors
  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE8F1FF), Color(0xFFFFFFFF)],
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF007BFF), Color(0xFF0BB8A8)],
  );
  
  // Material Color
  static MaterialColor primarySwatch = MaterialColor(
    primaryBlue.value,
    <int, Color>{
      50: primaryBlue.withOpacity(0.1),
      100: primaryBlue.withOpacity(0.2),
      200: primaryBlue.withOpacity(0.3),
      300: primaryBlue.withOpacity(0.4),
      400: primaryBlue.withOpacity(0.5),
      500: primaryBlue,
      600: primaryBlue.withOpacity(0.7),
      700: primaryBlue.withOpacity(0.8),
      800: primaryBlue.withOpacity(0.9),
      900: primaryBlue,
    },
  );
  
  // Color Scheme
  static ColorScheme lightColorScheme = const ColorScheme.light(
    primary: primaryBlue,
    secondary: teal,
    error: danger,
    surface: white,
  );
  
  static ColorScheme darkColorScheme = const ColorScheme.dark(
    primary: primaryBlue,
    secondary: teal,
    error: danger,
    surface: Color(0xFF1E1E1E),
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.white,
    onError: Colors.white,
  );
}

