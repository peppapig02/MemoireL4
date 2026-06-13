import 'package:botroad/ui/animations/app_animations.dart';
import 'package:botroad/ui/screens/main/main_shell.dart';
import 'package:botroad/ui/widgets/boutton.dart';
import 'package:botroad/ui/widgets/textfield.dart';
import 'package:botroad/utils/Setting.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _userCtrl = Setting.userCtrl;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handlePasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      Setting.showMessage(
        'login_info'.tr,
        'login_enter_email_first'.tr,
        Colors.orange,
      );
      return;
    }

    final success = await _userCtrl.sendPasswordResetEmail(email);
    if (!mounted) return;

    if (success) {
      Setting.showMessage(
        'login_verification'.tr,
        'login_reset_sent'.tr,
        Colors.green,
      );
    } else {
      Setting.showMessage(
        'login_error'.tr,
        _userCtrl.messageErreur,
        Colors.red,
      );
    }
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      Setting.showMessage(
        'login_error'.tr,
        'login_fill_all_fields'.tr,
        Colors.red,
      );
      return;
    }

    final success = await _userCtrl.signin(
      _emailController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      Get.offAll(
        () => const MainShell(),
        transition: Transition.fadeIn,
        duration: AppAnimations.medium,
      );
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
    final heigth = Setting.getHeight(context);

    return Container(
      padding: const EdgeInsets.all(4.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: heigth / 30),
            TextFieldCustum(
              hintText: 'login_email'.tr,
              controller: _emailController,
            ),
            SizedBox(height: heigth / 30),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextFieldCustum(
                  hintText: 'login_password'.tr,
                  obscureText: true,
                  controller: _passwordController,
                ),
                TextButton(
                  onPressed: _handlePasswordReset,
                  child: Text('login_forgot_password'.tr),
                ),
              ],
            ),
            Obx(
              () => Boutton(
                text: 'login_submit'.tr,
                isLoading: _userCtrl.loading.value,
                onPressed: _userCtrl.loading.value ? null : _handleLogin,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
