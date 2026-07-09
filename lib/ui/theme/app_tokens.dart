import 'package:flutter/material.dart';

import 'package:botroad/utils/const/colors.dart';

/// Design tokens Wapi V2 — radii, ombres, glow, bordures.
abstract final class AppTokens {
  // Coins arrondis
  static const double radiusButton = 100; // pill complet
  static const double radiusInput = 14;
  static const double radiusCard = 20;
  static const double radiusBottomSheet = 28;
  static const double radiusAiCard = 20;
  static const double radiusNav = 28;
  static const double radiusIconBox = 12; // icône dans carré arrondi

  // Dimensions
  static const double buttonHeight = 56;
  static const double inputHeight = 54;
  static const double cardPadding = 20;

  // Bordures
  static Border get borderSubtle => Border.all(
        color: AppColors.divider,
        width: 1,
      );

  static BorderRadius get borderRadiusButton =>
      BorderRadius.circular(radiusButton);
  static BorderRadius get borderRadiusInput =>
      BorderRadius.circular(radiusInput);
  static BorderRadius get borderRadiusCard => BorderRadius.circular(radiusCard);
  static BorderRadius get borderRadiusBottomSheet =>
      BorderRadius.circular(radiusBottomSheet);
  static BorderRadius get borderRadiusAiCard =>
      BorderRadius.circular(radiusAiCard);
  static BorderRadius get borderRadiusNav => BorderRadius.circular(radiusNav);
  static BorderRadius get borderRadiusIconBox =>
      BorderRadius.circular(radiusIconBox);

  // Ombres neumorphiques — double ombre douce (reflet clair + ombre),
  // même teinte que le fond : le relief vient d'ici, pas d'une bordure.
  static List<BoxShadow> neumorphicRaised({double intensity = 1.0}) => [
        BoxShadow(
          color: AppColors.neuHighlight,
          blurRadius: 14 * intensity,
          offset: Offset(-6 * intensity, -6 * intensity),
        ),
        BoxShadow(
          color: AppColors.neuShadow,
          blurRadius: 14 * intensity,
          offset: Offset(6 * intensity, 6 * intensity),
        ),
      ];

  // Variante "enfoncée" — utilisée pour l'état actif/sélectionné/focus.
  // Flutter n'a pas d'ombre interne native : on simule l'effet en
  // inversant le sens des ombres et en réduisant leur portée.
  static List<BoxShadow> neumorphicPressed({double intensity = 1.0}) => [
        BoxShadow(
          color: AppColors.neuShadow,
          blurRadius: 8 * intensity,
          offset: Offset(-3 * intensity, -3 * intensity),
        ),
        BoxShadow(
          color: AppColors.neuHighlight,
          blurRadius: 8 * intensity,
          offset: Offset(3 * intensity, 3 * intensity),
        ),
      ];

  // Alias legacy — conservés pour les widgets existants.
  static List<BoxShadow> get shadowSoft => neumorphicRaised();
  static List<BoxShadow> get shadowCard => neumorphicRaised(intensity: 0.85);

  // Glow corail — boutons actifs, route, micro, agent IA
  static List<BoxShadow> glowAccent({double opacity = 0.2}) => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: opacity),
          blurRadius: 20,
          spreadRadius: 0,
        ),
      ];

  static BoxDecoration neumorphicDecoration({
    bool pressed = false,
    bool glowing = false,
    BorderRadius? borderRadius,
    Color? color,
  }) =>
      BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: borderRadius ?? borderRadiusCard,
        boxShadow: [
          ...(pressed ? neumorphicPressed() : neumorphicRaised()),
          if (glowing) ...glowAccent(),
        ],
      );

  static BoxDecoration cardDecoration({bool glowing = false, bool pressed = false}) =>
      neumorphicDecoration(glowing: glowing, pressed: pressed);
}
