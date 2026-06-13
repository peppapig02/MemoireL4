import 'package:botroad/core/i18n/app_translations.dart';
import 'package:botroad/ui/screens/splash/splash.dart';
import 'package:botroad/ui/theme/app_theme.dart';
import 'package:botroad/utils/Setting.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Setting.initUser();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'BotRoad',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      translations: AppTranslations(),
      locale: AppTranslations.getStoredLocale(),
      fallbackLocale: AppTranslations.fallback,
      home: const SplashScreen(),
    );
  }
}
