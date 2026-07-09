import 'package:botroad/ui/screens/auth/pages/login.dart';
import 'package:botroad/ui/screens/auth/pages/register.dart';
import 'package:botroad/ui/theme/app_tokens.dart';
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

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  bool isLoading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
                height: height / 2.6,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(36),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Image.asset(
                              Assets.logo_mark,
                              width: 96,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Wapi',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'La bonne route, à chaque fois',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(child: SizedBox()),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: EdgeInsets.only(top: height / 2.7, bottom: 12),
              width: width / 1.2,
              height: height - height / 2.7 - 12,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(28),
                boxShadow: AppTokens.neumorphicRaised(),
              ),
              child: Column(
                children: [
                  TabBar(
                    controller: _tabController,
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
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      physics: const PageScrollPhysics(),
                      children: const [LoginScreen(), RegisterScreen()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
