import 'package:flutter/material.dart';

import 'package:botroad/utils/const/colors.dart';

/// Design tokens BotRoad V2 — radii, ombres, glow, bordures.
abstract final class AppTokens {
  // Coins arrondis
  static const double radiusButton = 18;
  static const double radiusInput = 20;
  static const double radiusCard = 28;
  static const double radiusBottomSheet = 32;
  static const double radiusAiCard = 24;
  static const double radiusNav = 28;

  // Dimensions
  static const double buttonHeight = 56;
  static const double inputHeight = 56;
  static const double cardPadding = 20;

  // Bordures
  static Border borderSubtle = Border.all(
    color: Colors.white.withValues(alpha: 0.05),
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

  // Ombres
  static List<BoxShadow> get shadowSoft => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 30,
          offset: const Offset(0, 10),
        ),
      ];

  // Glow rose — boutons actifs, route, micro, agent IA
  static List<BoxShadow> glowAccent({double opacity = 0.2}) => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: opacity),
          blurRadius: 20,
          spreadRadius: 0,
        ),
      ];

  static BoxDecoration cardDecoration({bool glowing = false}) => BoxDecoration(
        color: AppColors.surface,
        borderRadius: borderRadiusCard,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
        boxShadow: [
          ...shadowSoft,
          if (glowing) ...glowAccent(),
        ],
      );
}
