import 'package:botroad/ui/animations/app_animations.dart';
import 'package:botroad/ui/theme/app_tokens.dart';
import 'package:botroad/utils/Setting.dart';
import 'package:botroad/utils/const/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

const _onboardingKey = 'onboarding_completed';

abstract final class OnboardingStorage {
  static bool isCompleted() {
    return GetStorage(Setting.storageName).read(_onboardingKey) == true;
  }

  static Future<void> markCompleted() async {
    await GetStorage(Setting.storageName).write(_onboardingKey, true);
  }
}

void showElegantSnackbar({
  required String title,
  required String message,
  bool isError = false,
}) {
  Get.snackbar(
    title,
    message,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: AppColors.surfaceElevated,
    colorText: AppColors.textPrimary,
    margin: const EdgeInsets.all(16),
    borderRadius: 16,
    duration: const Duration(seconds: 3),
    animationDuration: AppAnimations.normal,
    forwardAnimationCurve: AppAnimations.ease,
    reverseAnimationCurve: AppAnimations.exit,
    icon: Icon(
      isError ? Icons.error_outline : Icons.info_outline,
      color: isError ? AppColors.error : AppColors.primary,
    ),
    boxShadows: AppTokens.neumorphicRaised(),
  );
}
