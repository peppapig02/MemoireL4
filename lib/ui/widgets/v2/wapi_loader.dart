import 'package:botroad/utils/const/images.dart';
import 'package:flutter/material.dart';

class WapiLoader extends StatefulWidget {
  final double size;
  const WapiLoader({super.key, this.size = 48});

  @override
  State<WapiLoader> createState() => _WapiLoaderState();
}

class _WapiLoaderState extends State<WapiLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _ctrl,
      child: Image.asset(
        Assets.logo_symbol,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
      ),
    );
  }
}
