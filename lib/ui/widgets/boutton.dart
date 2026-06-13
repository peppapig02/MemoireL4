import 'package:botroad/ui/animations/app_animations.dart';
import 'package:botroad/ui/animations/scale_tap.dart';
import 'package:botroad/ui/theme/app_tokens.dart';
import 'package:botroad/utils/const/colors.dart';
import 'package:flutter/material.dart';

class Boutton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const Boutton({
    super.key,
    required this.text,
    required this.onPressed,
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
              ? AppTokens.glowAccent(opacity: 0.15)
              : null,
        ),
        child: SizedBox(
          width: double.infinity,
          height: AppTokens.buttonHeight,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(text),
          ),
        ),
      ),
    );
  }
}
