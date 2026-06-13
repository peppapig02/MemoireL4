import 'package:flutter/material.dart';
import 'package:botroad/utils/const/colors.dart';

class TextFieldCustum extends StatelessWidget {
  final String? hintText;
  final bool obscureText;

  const TextFieldCustum({
    super.key,
    this.hintText,
    this.obscureText = false,
    this.controller,
  });
  final TextEditingController? controller;
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
      ),
      style: const TextStyle(color: AppColors.textPrimary),
      obscureText: obscureText,
    );
  }
}
