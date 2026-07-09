import 'package:flutter/material.dart';

import 'package:botroad/ui/theme/app_tokens.dart';
import 'package:botroad/utils/const/colors.dart';

class AppTextField extends StatelessWidget {
  final String? hintText;
  final String? labelText;
  final bool obscureText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final int? maxLines;

  const AppTextField({
    super.key,
    this.hintText,
    this.labelText,
    this.obscureText = false,
    this.controller,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null) ...[
          Text(
            labelText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: AppTokens.neumorphicDecoration(
            borderRadius: AppTokens.borderRadiusInput,
          ),
          child: SizedBox(
            height: maxLines == 1 ? AppTokens.inputHeight : null,
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              enabled: enabled,
              maxLines: maxLines,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: hintText,
                prefixIcon: prefixIcon,
                suffixIcon: suffixIcon,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
