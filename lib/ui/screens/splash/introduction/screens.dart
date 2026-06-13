import 'package:botroad/ui/theme/app_tokens.dart';
import 'package:botroad/ui/animations/app_animations.dart';
import 'package:botroad/ui/animations/app_feedback.dart';
import 'package:botroad/ui/animations/onboarding_animations.dart';
import 'package:botroad/ui/screens/auth/auth.dart';
import 'package:botroad/ui/widgets/v2/primary_button.dart';
import 'package:botroad/utils/const/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class IntroductionScreens extends StatefulWidget {
  const IntroductionScreens({super.key});

  @override
  State<IntroductionScreens> createState() => _IntroductionScreensState();
}

class _IntroductionScreensState extends State<IntroductionScreens> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _slides = [
    (
      title: 'Votre copilote intelligent',
      body:
          'Discutez naturellement avec BotRoad pour trouver le meilleur itinéraire.',
      animation: 0,
    ),
    (
      title: 'Des routes analysées en temps réel',
      body:
          'BotRoad prend en compte le trafic, les signalements et l\'état des routes.',
      animation: 1,
    ),
    (
      title: 'Arrivez en confiance',
      body:
          'Recevez des recommandations fiables et naviguez plus efficacement.',
      animation: 2,
    ),
  ];

  Future<void> _finish() async {
    await OnboardingStorage.markCompleted();
    Get.offAll(
      () => const AuthScreen(),
      transition: Transition.fadeIn,
      duration: AppAnimations.medium,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(
                  'Passer',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildAnimation(slide.animation),
                        const SizedBox(height: 48),
                        Text(
                          slide.title,
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontSize: 26,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          slide.body,
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) {
                final active = i == _currentPage;
                return AnimatedContainer(
                  duration: AppAnimations.normal,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.primary
                        : AppColors.textMuted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: _currentPage == _slides.length - 1
                  ? PrimaryButton(
                      label: 'Commencer',
                      onPressed: _finish,
                    )
                  : const SizedBox(height: AppTokens.buttonHeight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimation(int type) {
    switch (type) {
      case 1:
        return const MapGlowAnimation();
      case 2:
        return const RouteCheckAnimation();
      default:
        return const RouteDrawAnimation();
    }
  }
}
