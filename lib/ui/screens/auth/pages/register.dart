import 'package:botroad/ui/screens/home/home.dart';
import 'package:botroad/ui/widgets/boutton.dart';
import 'package:botroad/ui/widgets/textfield.dart';
import 'package:botroad/utils/Setting.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _userCtrl = Setting.userCtrl;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      Setting.showMessage(
        'login_error'.tr,
        'login_fill_all_fields'.tr,
        Colors.red,
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      Setting.showMessage(
        'login_error'.tr,
        'register_password_mismatch'.tr,
        Colors.red,
      );
      return;
    }

    _userCtrl.user.value = _userCtrl.user.value.copyWith(
      nom: _nameController.text,
      is_active: true,
      is_admin: false,
      email: _emailController.text,
      password: _passwordController.text,
    );

    final success = await _userCtrl.createUser();
    if (!mounted) return;

    if (success) {
      Get.offAll(() => const HomeScreen());
    } else {
      Setting.showMessage(
        'login_error'.tr,
        _userCtrl.messageErreur,
        Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = Setting.getHeight(context);
    final spacing = height / 70;

    return Container(
      padding: const EdgeInsets.all(4.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: spacing),
            TextFieldCustum(
              hintText: 'register_name'.tr,
              controller: _nameController,
            ),
            SizedBox(height: spacing),
            TextFieldCustum(
              hintText: 'login_email'.tr,
              controller: _emailController,
            ),
            SizedBox(height: spacing),
            TextFieldCustum(
              hintText: 'login_password'.tr,
              obscureText: true,
              controller: _passwordController,
            ),
            SizedBox(height: spacing),
            TextFieldCustum(
              hintText: 'register_confirm_password'.tr,
              obscureText: true,
              controller: _confirmPasswordController,
            ),
            SizedBox(height: spacing),
            Obx(
              () => Boutton(
                text: 'register_submit'.tr,
                onPressed: _userCtrl.loading.value ? () {} : _handleRegister,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
