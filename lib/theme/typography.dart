import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static TextStyle h1(BuildContext context) {
    return GoogleFonts.poppins(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.onSurface,
      letterSpacing: -0.5,
    );
  }
  
  static TextStyle h2(BuildContext context) {
    return GoogleFonts.poppins(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurface,
      letterSpacing: -0.3,
    );
  }
  
  static TextStyle h3(BuildContext context) {
    return GoogleFonts.poppins(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }
  
  static TextStyle body1(BuildContext context) {
    return GoogleFonts.nunito(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }
  
  static TextStyle body2(BuildContext context) {
    return GoogleFonts.nunito(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
    );
  }
  
  static TextStyle caption(BuildContext context) {
    return GoogleFonts.nunito(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
    );
  }
  
  static TextStyle button(BuildContext context) {
    return GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      letterSpacing: 0.5,
    );
  }
}

