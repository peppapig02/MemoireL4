import 'package:botroad/ui/animations/app_animations.dart';
import 'package:botroad/utils/const/colors.dart';
import 'package:flutter/material.dart';

/// Coche de validation discrète — 1 s puis disparition.
class SuccessCheck extends StatefulWidget {
  final VoidCallback? onComplete;

  const SuccessCheck({super.key, this.onComplete});

  @override
  State<SuccessCheck> createState() => _SuccessCheckState();
}

class _SuccessCheckState extends State<SuccessCheck>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.successCheck,
    );
    _scale = Tween<double>(begin: 0.6, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.35, curve: AppAnimations.ease),
      ),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1, curve: AppAnimations.exit),
      ),
    );
    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
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
      builder: (context, child) {
        final fadeOut = _controller.value > 0.65
            ? 1 - ((_controller.value - 0.65) / 0.35)
            : 1.0;
        return Opacity(
          opacity: fadeOut,
          child: Transform.scale(
            scale: _scale.value,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                color: AppColors.success,
                size: 28 * _opacity.value.clamp(0.3, 1),
              ),
            ),
          ),
        );
      },
    );
  }
}

void showSuccessOverlay(BuildContext context) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => Center(
      child: SuccessCheck(
        onComplete: () => entry.remove(),
      ),
    ),
  );
  overlay.insert(entry);
}
