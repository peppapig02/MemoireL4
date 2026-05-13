import 'package:botroad/ui/screens/auth/auth.dart';
import 'package:botroad/ui/screens/home/home.dart';
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
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _pinAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _pinAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Redirection après l'animation
    Future.delayed(const Duration(seconds: 3), () {
      if (Setting.userCtrl.getUserLocal()) {
        Get.offAll(() => HomeScreen());
      } else {
        Get.offAll(() => IntroductionScreens());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo avec animation de fondu
            FadeTransition(
              opacity: _fadeAnimation,
              child: Image.asset(
                Assets.logo_white,
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 40),
            // Animation de l'épingle
            SlideTransition(
              position: _pinAnimation,
              child: const Icon(
                Icons.location_on,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            // Indicateur de chargement
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SizedBox(
        height: 150,
        width: double.infinity,
        child: Image.asset(Assets.grateciels, fit: BoxFit.cover),
      ),
    );
  }
}
