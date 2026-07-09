import 'package:flutter/animation.dart';

/// Durées et courbes standard Wapi — rapides, discrètes, 150–300 ms.
abstract final class AppAnimations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 300);
  static const Duration routeDraw = Duration(milliseconds: 650);
  static const Duration splashTotal = Duration(milliseconds: 2000);
  static const Duration successCheck = Duration(milliseconds: 1000);

  static const Curve ease = Curves.easeOutCubic;
  static const Curve enter = Curves.easeOut;
  static const Curve exit = Curves.easeIn;

  static const double tapScale = 0.97;
  static const Duration tapDuration = Duration(milliseconds: 100);
  static const double suggestionTapScale = 0.95;
}
