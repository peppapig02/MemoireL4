import 'package:flutter/material.dart';

/// Palette Wapi — accent corail + système adaptatif light/dark.
/// Les couleurs marquées `const` restent identiques dans les deux modes.
/// Les getters s'adaptent à [AppColors.setMode].
class AppColors {
  static bool _dark = false;

  /// Appelé par [ThemeController] avant chaque rebuild.
  static void setMode(bool dark) => _dark = dark;
  static bool get isDark => _dark;

  // ── Accent corail — identique dans les deux modes ──────────────────
  static const Color primary = Color(0xFFF56B6F);
  static const Color primaryLight = Color(0xFFFF8D92);
  static const Color primaryDark = Color(0xFFE85A5F);

  // Alias legacy
  static const Color accent = Color(0xFFFF8D92);
  static const Color accentLight = Color(0xFFFFB3B6);
  static const Color accentDark = Color(0xFFE85A5F);

  // ── Système — identique dans les deux modes ─────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3498DB);

  // ── Fonds ───────────────────────────────────────────────────────────
  static Color get background =>
      _dark ? const Color(0xFF111111) : const Color(0xFFF8F6F4);
  static Color get backgroundSecondary =>
      _dark ? const Color(0xFF181818) : const Color(0xFFF0EEEC);

  // Surface neumorphique — même ton que le fond : le relief vient des
  // ombres (neuHighlight/neuShadow), pas d'un contraste de couleur.
  static Color get surface => background;

  // Surfaces qui doivent réellement se détacher (bottom sheet, dropdown,
  // snackbar) — ex-couleur `surface`, gardée distincte du fond.
  static Color get surfaceElevated =>
      _dark ? const Color(0xFF1C1C1C) : const Color(0xFFFFFFFF);

  // ── Ombres neumorphiques — reflet clair + ombre douce, même teinte
  // que le fond de chaque mode ─────────────────────────────────────────
  static Color get neuHighlight => _dark
      ? const Color(0xFF2C2C2C).withValues(alpha: 0.55)
      : const Color(0xFFFFFFFF).withValues(alpha: 0.9);
  static Color get neuShadow => _dark
      ? Colors.black.withValues(alpha: 0.6)
      : const Color(0xFFD8D3CE).withValues(alpha: 0.65);

  // ── Texte ────────────────────────────────────────────────────────────
  static Color get textPrimary =>
      _dark ? const Color(0xFFECECEB) : const Color(0xFF1A1A1A);
  static Color get textSecondary =>
      _dark ? const Color(0xFF9A9A9A) : const Color(0xFF666666);
  static Color get textMuted =>
      _dark ? const Color(0xFF5E5E5E) : const Color(0xFF999999);

  // ── Neutres ──────────────────────────────────────────────────────────
  static Color get neutral =>
      _dark ? const Color(0xFF5E5E5E) : const Color(0xFF999999);
  static Color get neutralLight =>
      _dark ? const Color(0xFF2A2A2A) : const Color(0xFFEAEAEA);
  static Color get neutralDark =>
      _dark ? const Color(0xFFCCCCCC) : const Color(0xFF444444);

  // ── Bordures & effets ────────────────────────────────────────────────
  static Color get divider =>
      _dark ? const Color(0xFF272727) : const Color(0xFFEAEAEA);
  static Color get accentSoft =>
      _dark ? const Color(0xFF3A1C1D) : const Color(0xFFFFE7E8);
  static Color get glow => primary.withValues(alpha: _dark ? 0.20 : 0.15);
}
