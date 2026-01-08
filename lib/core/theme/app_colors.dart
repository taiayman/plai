import 'package:flutter/material.dart';

/// Plai "Social Dark" color palette
/// Same friendly Clubhouse-inspired design, but in dark mode
class AppColors {
  AppColors._();

  // Backgrounds - Deep Dark tones
  static const Color background = Color(0xFF121212); // True dark
  static const Color surfaceLight = Color(0xFF1E1E1E); // Card backgrounds
  static const Color surfaceDark = Color(0xFF0A0A0A); // Deeper surfaces
  static const Color cardBackground = Color(0xFF1E1E1E);

  // Text colors - Light on dark
  static const Color textPrimary = Color(0xFFFFFFFF); // Pure white
  static const Color textSecondary = Color(0xFFB3B3B3); // Light grey
  static const Color textMuted = Color(0xFF666666); // Muted grey

  // Primary accent - Clubhouse Blue (kept the same)
  static const Color accentPrimary = Color(0xFF5576F8);
  static const Color accentPrimaryDark = Color(0xFF445ED0);

  // Secondary accent - Success Green
  static const Color accentSecondary = Color(0xFF5DAE64);

  // Tertiary accent - Alert/Notification Red
  static const Color accentTertiary = Color(0xFFE94F37);
  static const Color error = accentTertiary;

  static const Color accentGold = Color(0xFFFFC107);

  // Verified badge - Blue
  static const Color verifiedColor = Color(0xFF5576F8);

  // Like color - Heart Red
  static const Color likeRed = Color(0xFFFF4D4D);

  // Gradients
  static const LinearGradient createButtonGradient = LinearGradient(
    colors: [Color(0xFF5576F8), Color(0xFF5576F8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Overlay colors
  static const Color overlayLight = Color(0x33FFFFFF);
  static const Color overlayDark = Color(0x66000000);

  // Border colors
  static const Color borderLight = Color(0xFF2A2A2A);
  static const Color borderMedium = Color(0xFF3A3A3A);

  // Shadows
  static Color shadowColor = Colors.black.withOpacity(0.3);
}
