import 'package:botroad/ui/animations/app_animations.dart';
import 'package:botroad/utils/const/colors.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Skeleton discret — shimmer léger, pas de spinner.
class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
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
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
            color: Color.lerp(
              AppColors.surface,
              AppColors.neutralLight,
              _controller.value * 0.35,
            ),
          ),
        );
      },
    );
  }
}

class SkeletonList extends StatelessWidget {
  final int count;
  final double itemHeight;

  const SkeletonList({super.key, this.count = 4, this.itemHeight = 72});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => SkeletonBox(
        width: double.infinity,
        height: itemHeight,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

class MapSkeleton extends StatelessWidget {
  const MapSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        SkeletonBox(
          width: double.infinity,
          height: double.infinity,
          borderRadius: BorderRadius.zero,
        ),
        Center(
          child: AnimatedOpacity(
            opacity: 0.6,
            duration: AppAnimations.slow,
            child: Icon(
              LucideIcons.map,
              size: 48,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }
}
