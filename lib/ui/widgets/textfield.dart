import 'package:botroad/ui/animations/app_animations.dart';
import 'package:botroad/ui/animations/scale_tap.dart';
import 'package:botroad/ui/theme/app_tokens.dart';
import 'package:botroad/utils/const/colors.dart';
import 'package:flutter/material.dart';

class TextFieldCustum extends StatefulWidget {
  final String? hintText;
  final bool obscureText;
  final TextEditingController? controller;

  const TextFieldCustum({
    super.key,
    this.hintText,
    this.obscureText = false,
    this.controller,
  });

  @override
  State<TextFieldCustum> createState() => _TextFieldCustumState();
}

class _TextFieldCustumState extends State<TextFieldCustum> {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppAnimations.normal,
      curve: AppAnimations.ease,
      decoration: BoxDecoration(
        borderRadius: AppTokens.borderRadiusInput,
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: SizedBox(
        height: AppTokens.inputHeight,
        child: TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          obscureText: widget.obscureText,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(color: AppColors.textMuted),
          ),
        ),
      ),
    );
  }
}
