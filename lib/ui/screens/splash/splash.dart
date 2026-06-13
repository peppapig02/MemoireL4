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
  late Animation<double> _logoGlow;
  late Animation<double> _nameFade;

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
        curve: const Interval(0, 0.35, curve: AppAnimations.ease),
      ),
    );

    _logoGlow = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.55, curve: AppAnimations.ease),
      ),
    );

    _nameFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.7, curve: AppAnimations.ease),
      ),
    );

    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) _navigate();
    });
  }

  void _navigate() {
    if (Setting.userCtrl.getUserLocal()) {
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary
                            .withValues(alpha: 0.15 * _logoGlow.value),
                        blurRadius: 30 + 20 * _logoGlow.value,
                        spreadRadius: 2 * _logoGlow.value,
                      ),
                    ],
                  ),
                  child: FadeTransition(opacity: _logoFade, child: child),
                );
              },
              child: Image.asset(
                Assets.logo_white,
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
            FadeTransition(
              opacity: _nameFade,
              child: Text(
                'BotRoad',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 32,
                      letterSpacing: -0.5,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
