import 'package:botroad/ui/animations/app_animations.dart';
import 'package:botroad/ui/animations/app_feedback.dart';
import 'package:botroad/ui/screens/auth/auth.dart';
import 'package:botroad/ui/screens/main/main_shell.dart';
import 'package:botroad/ui/screens/splash/introduction/screens.dart';
import 'package:botroad/utils/Setting.dart';
import 'package:botroad/utils/const/colors.dart';
import 'package:botroad/utils/const/images.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.splashTotal,
      vsync: this,
    );

    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.6, curve: AppAnimations.ease),
      ),
    );

    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) _navigate();
    });
  }

  void _navigate() {
    final hasLocalUser = Setting.userCtrl.getUserLocal();
    // Firebase Auth persists sessions natively — if currentUser is non-null
    // the token is still valid even if GetStorage was cleared (e.g. reinstall).
    final hasFirebaseSession = Setting.user != null;

    if (hasLocalUser || hasFirebaseSession) {
      Get.offAll(
        () => const MainShell(),
        transition: Transition.fadeIn,
        duration: AppAnimations.medium,
      );
    } else if (OnboardingStorage.isCompleted()) {
      Get.offAll(
        () => const AuthScreen(),
        transition: Transition.fadeIn,
        duration: AppAnimations.medium,
      );
    } else {
      Get.offAll(
        () => const IntroductionScreens(),
        transition: Transition.fadeIn,
        duration: AppAnimations.medium,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _logoFade,
          child: Image.asset(
            Assets.logo_primary,
            width: 220,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
