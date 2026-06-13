import 'package:botroad/ui/screens/auth/pages/login.dart';
import 'package:botroad/ui/screens/auth/pages/register.dart';
import 'package:botroad/ui/screens/home/home.dart';
import 'package:botroad/utils/Setting.dart';
import 'package:botroad/utils/const/colors.dart';
import 'package:botroad/utils/const/images.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLoading = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: bodyAuth(context: context),
        //   child: Padding(
        //     padding: const EdgeInsets.all(24.0),
        //     child: Column(
        //       crossAxisAlignment: CrossAxisAlignment.stretch,
        //       children: [
        //         const SizedBox(height: 40),
        //         // Logo
        //         Center(
        //           child: Image.asset(
        //             Assets.logo,
        //             width: 150,
        //             height: 150,
        //             fit: BoxFit.contain,
        //           ),
        //         ),
        //         const SizedBox(height: 40),
        //         // Titre
        //         Text(
        //           'Bienvenue sur BotRoad',
        //           style: Theme.of(context).textTheme.headlineMedium?.copyWith(
        //             color: AppColors.primary,
        //             fontWeight: FontWeight.bold,
        //           ),
        //           textAlign: TextAlign.center,
        //         ),
        //         const SizedBox(height: 8),
        //         Text(
        //           'Votre assistant de navigation intelligent',
        //           style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        //             color: AppColors.textSecondary,
        //           ),
        //           textAlign: TextAlign.center,
        //         ),
        //         const SizedBox(height: 40),
        //         // Bouton Google
        //         isLoading
        //             ? const Center(child: CircularProgressIndicator())
        //             : ElevatedButton.icon(
        //               onPressed: () async {
        //                 setState(() {
        //                   isLoading = true;
        //                 });
        //                 final success =
        //                     await Setting.userCtrl.signInWithGoogle();
        //                 setState(() {
        //                   isLoading = false;
        //                 });
        //                 if (success) {
        //                   Get.offAll(() => const HomeScreen());
        //                 } else {
        //                   Setting.showMessage(
        //                     "Erreur",
        //                     Setting.userCtrl.messageErreur,
        //                     Colors.red,
        //                   );
        //                 }
        //               },
        //               icon: Image.asset(Assets.google, height: 24),
        //               label: const Text('Continuer avec Google'),
        //               style: ElevatedButton.styleFrom(
        //                 backgroundColor: Colors.white,
        //                 foregroundColor: AppColors.textPrimary,
        //                 padding: const EdgeInsets.symmetric(vertical: 16),
        //               ),
        //             ),
        //         const SizedBox(height: 16),
        //         // Séparateur
        //         Row(
        //           children: [
        //             const Expanded(child: Divider()),
        //             Padding(
        //               padding: const EdgeInsets.symmetric(horizontal: 16),
        //               child: Text(
        //                 'ou',
        //                 style: TextStyle(color: AppColors.textSecondary),
        //               ),
        //             ),
        //             const Expanded(child: Divider()),
        //           ],
        //         ),
        //         const SizedBox(height: 16),
        //         // Bouton Email/Mot de passe
        //         OutlinedButton(
        //           onPressed: () => Get.to(() => const LoginScreen()),
        //           style: OutlinedButton.styleFrom(
        //             padding: const EdgeInsets.symmetric(vertical: 16),
        //           ),
        //           child: const Text('Se connecter avec Email'),
        //         ),
        //         const SizedBox(height: 24),
        //         // Lien Créer un compte
        //         TextButton(
        //           onPressed: () => Get.to(() => const RegisterScreen()),
        //           child: const Text('Créer un compte'),
        //         ),
        //         const SizedBox(height: 24),
        //         // Version de l'application
        //         Text(
        //           'Version ${Setting.version}',
        //           style: Theme.of(context).textTheme.bodySmall?.copyWith(
        //             color: AppColors.textSecondary,
        //           ),
        //           textAlign: TextAlign.center,
        //         ),
        //       ],
        //     ),
        //   ),
      ),
    );
  }

  bodyAuth({var context}) {
    double height = Setting.getHeight(context);
    double width = Setting.getWidth(context);
    return SizedBox(
      height: height,
      width: width,
      child: Stack(
        children: [
          Column(
            children: [
              Container(
                height: height / 2.2,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  gradient: const LinearGradient(
                    colors: [AppColors.background, AppColors.surface],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  image: DecorationImage(
                    image: AssetImage(Assets.grateciels),
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.bottomCenter,
                    opacity: 0.22,
                  ),
                ),
                child: Center(
                  child: Image.asset(
                    Assets.logo_en_gris,
                    width: width / 3,
                    height: height / 1.5,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : OutlinedButton(
                            onPressed: () async {
                              setState(() {
                                isLoading = true;
                              });
                              final success =
                                  await Setting.userCtrl.signInWithGoogle();
                              setState(() {
                                isLoading = false;
                              });
                              if (success) {
                                Get.offAll(() => const HomeScreen());
                              } else {
                                Setting.showMessage(
                                  'login_error'.tr,
                                  Setting.userCtrl.messageErreur,
                                  Colors.red,
                                );
                              }
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(Assets.google, height: 24),
                                const SizedBox(width: 10),
                                Text('auth_continue_google'.tr),
                              ],
                            ),
                          ),
                      SizedBox(height: height / 50),
                      Text(
                        'auth_version'.trParams({'version': Setting.version}),
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: EdgeInsets.symmetric(vertical: height / 7),
              width: width / 1.2,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.divider),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 28,
                  ),
                ],
              ),
              child: DefaultTabController(
                length: 2,
                child: Column(
                  mainAxisSize:
                      MainAxisSize
                          .min, // C’est ça qui permet d’adapter la hauteur
                  children: [
                    TabBar(
                      indicatorColor: AppColors.primary,
                      labelColor: AppColors.textPrimary,
                      unselectedLabelColor: AppColors.textMuted,
                      dividerColor: AppColors.divider,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                      tabs: [
                        Tab(text: 'auth_login_tab'.tr),
                        Tab(text: 'auth_register_tab'.tr),
                      ],
                    ),

                    SizedBox(
                      // donne une hauteur fixe suffisante pour les deux formulaires
                      height: height / 2.4,
                      child: TabBarView(
                        children: const [LoginScreen(), RegisterScreen()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
