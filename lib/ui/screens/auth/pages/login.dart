import 'package:botroad/ui/screens/auth/pages/register.dart';
import 'package:botroad/ui/screens/home/home.dart';
import 'package:botroad/ui/screens/splash/introduction/presentation.dart';
import 'package:botroad/ui/widgets/boutton.dart';
import 'package:botroad/ui/widgets/textfield.dart';
import 'package:botroad/utils/Setting.dart';
import 'package:botroad/utils/const/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _userCtrl = Setting.userCtrl;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double heigth = Setting.getHeight(context);
    // double width = Setting.getHeight(context);
    return Container(
      padding: const EdgeInsets.all(4.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: heigth / 30),
            TextFieldCustum(hintText: "Email", controller: _emailController),
            SizedBox(height: heigth / 30),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextFieldCustum(
                  hintText: "Mot de passe",
                  obscureText: true,
                  controller: _passwordController,
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Mot de passe oublié ?'),
                ),
              ],
            ),
            Obx(
              () => Boutton(
                text: "Se connecter",
                onPressed:
                    _userCtrl.loading.value
                        ? () {}
                        : () async {
                          if (_emailController.text.isEmpty ||
                              _passwordController.text.isEmpty) {
                            Setting.showMessage(
                              "Erreur",
                              "Veuillez remplir tous les champs",
                              Colors.red,
                            );
                            return;
                          }
                          final success = await _userCtrl.signin(
                            _emailController.text,
                            _passwordController.text,
                          );
                          if (success) {
                            Get.offAll(() => const Presentation());
                          } else {
                            Setting.showMessage(
                              "Erreur",
                              _userCtrl.messageErreur,
                              Colors.red,
                            );
                          }
                        },
              ),
            ),
          ],
        ),
      ),
    );
  }

  //   @override
  //   Widget build(BuildContext context) {
  //     return Scaffold(
  //       backgroundColor: AppColors.background,
  //       appBar: AppBar(title: const Text('Connexion')),
  //       body: SafeArea(
  //         child: SingleChildScrollView(
  //           padding: const EdgeInsets.all(24.0),
  //           child: Form(
  //             key: _formKey,
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.stretch,
  //               children: [
  //                 // Email
  //                 TextFormField(
  //                   controller: _emailController,
  //                   decoration: const InputDecoration(
  //                     labelText: 'Email',
  //                     prefixIcon: Icon(Icons.email_outlined),
  //                   ),
  //                   keyboardType: TextInputType.emailAddress,
  //                   validator: (value) {
  //                     if (value == null || value.isEmpty) {
  //                       return 'Veuillez entrer votre email';
  //                     }
  //                     if (!GetUtils.isEmail(value)) {
  //                       return 'Veuillez entrer un email valide';
  //                     }
  //                     return null;
  //                   },
  //                 ),
  //                 const SizedBox(height: 16),
  //                 // Mot de passe
  //                 TextFormField(
  //                   controller: _passwordController,
  //                   decoration: const InputDecoration(
  //                     labelText: 'Mot de passe',
  //                     prefixIcon: Icon(Icons.lock_outline),
  //                   ),
  //                   obscureText: true,
  //                   validator: (value) {
  //                     if (value == null || value.isEmpty) {
  //                       return 'Veuillez entrer votre mot de passe';
  //                     }
  //                     return null;
  //                   },
  //                 ),
  //                 const SizedBox(height: 8),
  //                 // Mot de passe oublié
  //                 Align(
  //                   alignment: Alignment.centerRight,
  //                   child: TextButton(
  //                     onPressed: () {
  //                       // TODO: Implémenter la réinitialisation du mot de passe
  //                     },
  //                     child: const Text('Mot de passe oublié ?'),
  //                   ),
  //                 ),
  //                 const SizedBox(height: 24),
  //                 // Bouton de connexion
  //                 Obx(
  //                   () => ElevatedButton(
  //                     onPressed:
  //                         _userCtrl.loading.value
  //                             ? null
  //                             : () async {
  //                               if (_formKey.currentState!.validate()) {
  //                                 final success = await _userCtrl.signin(
  //                                   _emailController.text,
  //                                   _passwordController.text,
  //                                 );
  //                                 if (success) {
  //                                   Get.offAll(() => const HomeScreen());
  //                                 } else {
  //                                   Setting.showMessage(
  //                                     "Erreur",
  //                                     _userCtrl.messageErreur,
  //                                     Colors.red,
  //                                   );
  //                                 }
  //                               }
  //                             },
  //                     child:
  //                         _userCtrl.loading.value
  //                             ? const SizedBox(
  //                               height: 20,
  //                               width: 20,
  //                               child: CircularProgressIndicator(
  //                                 strokeWidth: 2,
  //                                 valueColor: AlwaysStoppedAnimation<Color>(
  //                                   Colors.white,
  //                                 ),
  //                               ),
  //                             )
  //                             : const Text('Se connecter'),
  //                   ),
  //                 ),
  //                 const SizedBox(height: 16),
  //                 // Séparateur
  //                 Row(
  //                   children: [
  //                     const Expanded(child: Divider()),
  //                     Padding(
  //                       padding: const EdgeInsets.symmetric(horizontal: 16),
  //                       child: Text(
  //                         'ou',
  //                         style: TextStyle(color: AppColors.textSecondary),
  //                       ),
  //                     ),
  //                     const Expanded(child: Divider()),
  //                   ],
  //                 ),
  //                 const SizedBox(height: 16),
  //                 // Bouton Google
  //                 OutlinedButton.icon(
  //                   onPressed: () async {
  //                     final success = await _userCtrl.signInWithGoogle();
  //                     if (success) {
  //                       Get.offAll(() => const HomeScreen());
  //                     } else {
  //                       Setting.showMessage(
  //                         "Erreur",
  //                         _userCtrl.messageErreur,
  //                         Colors.red,
  //                       );
  //                     }
  //                   },
  //                   icon: Image.asset(
  //                     'assets/images/google_logo.png',
  //                     height: 24,
  //                   ),
  //                   label: const Text('Continuer avec Google'),
  //                 ),
  //                 const SizedBox(height: 24),
  //                 // Lien Créer un compte
  //                 Row(
  //                   mainAxisAlignment: MainAxisAlignment.center,
  //                   children: [
  //                     Text(
  //                       'Pas encore de compte ?',
  //                       style: TextStyle(color: AppColors.textSecondary),
  //                     ),
  //                     TextButton(
  //                       onPressed: () => Get.to(() => const RegisterScreen()),
  //                       child: const Text('Créer un compte'),
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ),
  //     );
  //   }
}
