import 'package:botroad/ui/animations/app_animations.dart';
import 'package:botroad/ui/animations/scale_tap.dart';
import 'package:flutter/material.dart';

import 'package:botroad/ui/theme/app_tokens.dart';
import 'package:botroad/utils/const/colors.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool glowing;
  final IconData? icon;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.glowing = true,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: isLoading ? null : onPressed,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppTokens.borderRadiusButton,
          boxShadow: onPressed != null && !isLoading
              ? [
                  ...AppTokens.neumorphicRaised(),
                  if (glowing) ...AppTokens.glowAccent(),
                ]
              : null,
        ),
        child: SizedBox(
          width: double.infinity,
          height: AppTokens.buttonHeight,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: AppTokens.borderRadiusButton,
              ),
            ),
            child: AnimatedSwitcher(
              duration: AppAnimations.fast,
              child: isLoading
                  ? const SizedBox(
                      key: ValueKey('loader'),
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      key: const ValueKey('label'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Text(label),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
