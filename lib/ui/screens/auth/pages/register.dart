import 'package:botroad/ui/screens/auth/pages/login.dart';
import 'package:botroad/ui/screens/home/home.dart';
import 'package:botroad/ui/screens/splash/introduction/presentation.dart';
import 'package:botroad/ui/widgets/boutton.dart';
import 'package:botroad/ui/widgets/textfield.dart';
import 'package:botroad/utils/Setting.dart';
import 'package:botroad/utils/const/colors.dart';
import 'package:botroad/utils/const/images.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_utils/src/get_utils/get_utils.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
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

  @override
  Widget build(BuildContext context) {
    double heigth = Setting.getHeight(context);
    double spacing = heigth / 70;
    // double width = Setting.getHeight(context);
    return Container(
      padding: const EdgeInsets.all(4.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: spacing),
            TextFieldCustum(hintText: "Nom", controller: _nameController),

            SizedBox(height: spacing),

            TextFieldCustum(hintText: "Email", controller: _emailController),
            SizedBox(height: spacing),

            TextFieldCustum(
              hintText: "Mot de passe",
              obscureText: true,
              controller: _passwordController,
            ),
            SizedBox(height: spacing),

            TextFieldCustum(
              hintText: "Confirmation mot de passe",
              obscureText: true,
              controller: _confirmPasswordController,
            ),
            SizedBox(height: spacing),
            Obx(
              () => Boutton(
                text: "S'inscrire",
                onPressed:
                    _userCtrl.loading.value
                        ? () {}
                        : () async {
                          if (_nameController.text.isEmpty ||
                              _emailController.text.isEmpty ||
                              _passwordController.text.isEmpty ||
                              _confirmPasswordController.text.isEmpty) {
                            Setting.showMessage(
                              "Erreur",
                              "Veuillez remplir tous les champs",
                              Colors.red,
                            );
                            return;
                          }
                          if (_passwordController.text !=
                              _confirmPasswordController.text) {
                            Setting.showMessage(
                              "Erreur",
                              "Les mots de passe ne correspondent pas",
                              Colors.red,
                            );
                            return;
                          }
                          _userCtrl.user.value = _userCtrl.user.value.copyWith(
                            nom: _nameController.text,
                            is_active: true,
                            is_admin: false,
                            credits: "5",

                            email: _emailController.text,
                            password: _passwordController.text,
                          );
                          final success = await _userCtrl.createUser();
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
  //       appBar: AppBar(title: const Text('Créer un compte')),
  //       body: SafeArea(
  //         child: SingleChildScrollView(
  //           padding: const EdgeInsets.all(24.0),
  //           child: Form(
  //             key: _formKey,
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.stretch,
  //               children: [
  //                 // Nom
  //                 TextFormField(
  //                   controller: _nameController,
  //                   decoration: const InputDecoration(
  //                     labelText: 'Nom',
  //                     prefixIcon: Icon(Icons.person_outline),
  //                   ),
  //                   validator: (value) {
  //                     if (value == null || value.isEmpty) {
  //                       return 'Veuillez entrer votre nom';
  //                     }
  //                     return null;
  //                   },
  //                 ),
  //                 const SizedBox(height: 16),
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
  //                       return 'Veuillez entrer un mot de passe';
  //                     }
  //                     if (value.length < 6) {
  //                       return 'Le mot de passe doit contenir au moins 6 caractères';
  //                     }
  //                     return null;
  //                   },
  //                 ),
  //                 const SizedBox(height: 16),
  //                 // Confirmation du mot de passe
  //                 TextFormField(
  //                   controller: _confirmPasswordController,
  //                   decoration: const InputDecoration(
  //                     labelText: 'Confirmer le mot de passe',
  //                     prefixIcon: Icon(Icons.lock_outline),
  //                   ),
  //                   obscureText: true,
  //                   validator: (value) {
  //                     if (value == null || value.isEmpty) {
  //                       return 'Veuillez confirmer votre mot de passe';
  //                     }
  //                     if (value != _passwordController.text) {
  //                       return 'Les mots de passe ne correspondent pas';
  //                     }
  //                     return null;
  //                   },
  //                 ),
  //                 const SizedBox(height: 24),
  //                 // Bouton d'inscription
  //                 Obx(
  //                   () => ElevatedButton(
  //                     onPressed:
  //                         _userCtrl.loading.value
  //                             ? null
  //                             : () async {
  //                               if (_formKey.currentState!.validate()) {
  //                                 _userCtrl.user.value = _userCtrl.user.value
  //                                     .copyWith(
  //                                       nom: _nameController.text,
  //                                       email: _emailController.text,
  //                                       password: _passwordController.text,
  //                                     );
  //                                 final success = await _userCtrl.createUser();
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
  //                             : const Text('Créer un compte'),
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
  //                   icon: Image.asset(Assets.google, height: 24),
  //                   label: const Text('Continuer avec Google'),
  //                 ),
  //                 const SizedBox(height: 24),
  //                 // Lien Se connecter
  //                 Row(
  //                   mainAxisAlignment: MainAxisAlignment.center,
  //                   children: [
  //                     Text(
  //                       'Déjà un compte ?',
  //                       style: TextStyle(color: AppColors.textSecondary),
  //                     ),
  //                     TextButton(
  //                       onPressed: () => Get.to(() => const LoginScreen()),
  //                       child: const Text('Se connecter'),
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
