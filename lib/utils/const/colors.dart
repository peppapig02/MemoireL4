import 'package:flutter/material.dart';

/// Palette BotRoad V2 — copilote IA de mobilité.
class AppColors {
  // Accent principal — Rose BotRoad
  static const Color primary = Color(0xFFFF4FA3);

  // Variantes accent
  static const Color primaryLight = Color(0xFFFF7FBC);
  static const Color primaryDark = Color(0xFFE03D8F);

  // Alias legacy (migration progressive)
  static const Color accent = Color(0xFFFF7ABB);
  static const Color accentLight = Color(0xFFFF9BCD);
  static const Color accentDark = Color(0xFFFF2B91);

  // Fonds
  static const Color background = Color(0xFF0B0B0F);
  static const Color backgroundSecondary = Color(0xFF121218);
  static const Color surface = Color(0xFF17171D);
  static const Color surfaceElevated = Color(0xFF20202A);

  // Texte
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB5B5C2);
  static const Color textMuted = Color(0xFF747480);

  // Système
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3498DB);

  // Neutres (legacy)
  static const Color neutral = Color(0xFF747480);
  static const Color neutralLight = Color(0xFF2A2A32);
  static const Color neutralDark = Color(0xFF3A3A4A);

  // Bordures & effets
  static const Color divider = Color(0x0FFFFFFF);
  static const Color glow = Color(0x26FF4FA3);
}
