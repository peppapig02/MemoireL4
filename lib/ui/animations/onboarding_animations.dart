import 'dart:math' as math;

import 'package:botroad/ui/animations/app_animations.dart';
import 'package:botroad/utils/const/colors.dart';
import 'package:flutter/material.dart';

/// Slide 1 : trajectoire en forme de cœur qui se dessine progressivement.
class RouteDrawAnimation extends StatefulWidget {
  const RouteDrawAnimation({super.key});

  @override
  State<RouteDrawAnimation> createState() => _RouteDrawAnimationState();
}

class _RouteDrawAnimationState extends State<RouteDrawAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => CustomPaint(
        size: const Size(220, 140),
        painter: _RoutePainter(progress: _controller.value),
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  final double progress;

  _RoutePainter({required this.progress});

  static Path _heartPath(Size size) {
    final path = Path();
    final center = Offset(size.width / 2, size.height * 0.52);
    const scale = 4.2;

    Offset heartPoint(double t) {
      final x = 16 * math.pow(math.sin(t), 3);
      final y =
          13 * math.cos(t) -
          5 * math.cos(2 * t) -
          2 * math.cos(3 * t) -
          math.cos(4 * t);
      return Offset(center.dx + x * scale, center.dy - y * scale);
    }

    const steps = 120;
    path.moveTo(heartPoint(0).dx, heartPoint(0).dy);
    for (var i = 1; i <= steps; i++) {
      final t = (i / steps) * 2 * math.pi;
      final p = heartPoint(t);
      path.lineTo(p.dx, p.dy);
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _heartPath(size);
    final metrics = path.computeMetrics().first;
    final len = metrics.length * progress.clamp(0.05, 1);

    final routePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(metrics.extractPath(0, len), routePaint);

    final start = Offset(size.width / 2, size.height * 0.52 + 13 * 4.2);
    canvas.drawCircle(
      start,
      8,
      Paint()..color = AppColors.primary.withValues(alpha: 0.25),
    );
    canvas.drawCircle(start, 4, Paint()..color = AppColors.primary);
  }

  @override
  bool shouldRepaint(covariant _RoutePainter old) => old.progress != progress;
}

/// Slide 2 : points lumineux disposés en forme de « C » sur une carte abstraite.
class MapGlowAnimation extends StatefulWidget {
  const MapGlowAnimation({super.key});

  @override
  State<MapGlowAnimation> createState() => _MapGlowAnimationState();
}

class _MapGlowAnimationState extends State<MapGlowAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => CustomPaint(
        size: const Size(220, 140),
        painter: _GlowPainter(t: _controller.value),
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  final double t;

  _GlowPainter({required this.t});

  static const _points = [
    Offset(158, 38),
    Offset(72, 48),
    Offset(52, 70),
    Offset(72, 92),
    Offset(158, 102),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(10, 20, 200, 100),
        const Radius.circular(16),
      ),
      Paint()..color = AppColors.surface,
    );

    for (var i = 0; i < _points.length; i++) {
      final phase = ((t + i * 0.18) % 1.0);
      final opacity = math.sin(phase * math.pi).clamp(0.0, 1.0);
      final p = _points[i];

      canvas.drawCircle(
        p,
        14,
        Paint()..color = AppColors.primary.withValues(alpha: opacity * 0.2),
      );
      canvas.drawCircle(
        p,
        4,
        Paint()..color = AppColors.primary.withValues(alpha: 0.4 + opacity * 0.6),
      );
    }

    final cPath = Path()
      ..moveTo(_points[0].dx, _points[0].dy)
      ..cubicTo(95, 30, 35, 55, 35, 70)
      ..cubicTo(35, 85, 95, 110, _points[4].dx, _points[4].dy);
    canvas.drawPath(
      cPath,
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.12)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _GlowPainter old) => old.t != t;
}

/// Slide 3 : trajectoire → coche de validation.
class RouteCheckAnimation extends StatefulWidget {
  const RouteCheckAnimation({super.key});

  @override
  State<RouteCheckAnimation> createState() => _RouteCheckAnimationState();
}

class _RouteCheckAnimationState extends State<RouteCheckAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => CustomPaint(
        size: const Size(220, 140),
        painter: _CheckPainter(t: _controller.value),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  final double t;

  _CheckPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    if (t < 0.55) {
      final progress = (t / 0.55).clamp(0.0, 1.0);
      final path = Path()
        ..moveTo(60, 90)
        ..quadraticBezierTo(110, 30, 160, 70);
      final metrics = path.computeMetrics().first;
      canvas.drawPath(
        metrics.extractPath(0, metrics.length * progress),
        Paint()
          ..color = AppColors.primary
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    } else {
      final morph = ((t - 0.55) / 0.45).clamp(0.0, 1.0);
      final radius = 28 * morph;
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = AppColors.success.withValues(alpha: 0.15 * morph),
      );

      if (morph > 0.4) {
        final check = Paint()
          ..color = AppColors.success
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        final p = Path()
          ..moveTo(center.dx - 12, center.dy)
          ..lineTo(center.dx - 2, center.dy + 10)
          ..lineTo(center.dx + 14, center.dy - 10);
        canvas.drawPath(p, check);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CheckPainter old) => old.t != t;
}

/// Transition fade entre pages.
class FadeSlideTransition extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;

  const FadeSlideTransition({
    super.key,
    required this.child,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.03, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: AppAnimations.ease)),
        child: child,
      ),
    );
  }
}
