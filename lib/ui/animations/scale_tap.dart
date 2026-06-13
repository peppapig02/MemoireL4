import 'package:botroad/ui/animations/app_animations.dart';
import 'package:flutter/material.dart';

/// Scale 97 % au tap, retour 100 % — 100 ms.
class ScaleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  const ScaleTap({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = AppAnimations.tapScale,
  });

  @override
  State<ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<ScaleTap> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap == null ? null : (_) => _setPressed(true),
      onTapUp: widget.onTap == null ? null : (_) => _setPressed(false),
      onTapCancel: widget.onTap == null ? null : () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: AppAnimations.tapDuration,
        curve: AppAnimations.ease,
        child: widget.child,
      ),
    );
  }
}
