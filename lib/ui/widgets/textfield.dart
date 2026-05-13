import 'package:flutter/material.dart';

class TextFieldCustum extends StatelessWidget {
  String? hintText;
  bool obscureText = false;

  TextFieldCustum({
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
        hintStyle: const TextStyle(color: Colors.grey),
        border: OutlineInputBorder(),
      ),
      obscureText: obscureText,
    );
  }
}
