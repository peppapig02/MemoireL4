import 'package:botroad/controllers/theme_controller.dart';
import 'package:botroad/core/i18n/app_translations.dart';
import 'package:botroad/ui/screens/splash/splash.dart';
import 'package:botroad/ui/theme/app_theme.dart';
import 'package:botroad/utils/Setting.dart';
import 'package:botroad/utils/const/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Setting.initUser();

  // Init theme avant le premier build
  final themeCtrl = Get.put(ThemeController(), permanent: true);
  AppColors.setMode(themeCtrl.isDark.value);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.find<ThemeController>();
    return GetMaterialApp(
      title: 'Wapi',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: Setting.scaffoldKey,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeCtrl.isDark.value ? ThemeMode.dark : ThemeMode.light,
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200),
      translations: AppTranslations(),
      locale: AppTranslations.getStoredLocale(),
      fallbackLocale: AppTranslations.fallback,
      home: const SplashScreen(),
    );
  }
}
