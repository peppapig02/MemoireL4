import 'package:botroad/core/i18n/app_translations.dart';
import 'package:botroad/models/user_model.dart';
import 'package:botroad/ui/screens/about/about_screen.dart';
import 'package:botroad/ui/screens/car/my_car_screen.dart';
import 'package:botroad/ui/screens/credits/buy_credits_screen.dart';
import 'package:botroad/ui/screens/history/conversations_history_screen.dart';
import 'package:botroad/ui/screens/profile/profile_screen.dart';
import 'package:botroad/utils/Setting.dart';
import 'package:botroad/utils/const/colors.dart';
import 'package:botroad/utils/const/images.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DrawerCustom extends StatelessWidget {
  DrawerCustom({super.key});

  UserModel? user;

  void _showLanguageSheet() {
    final currentCode =
        AppTranslations.codeFromLocale(Get.locale ?? AppTranslations.fallback);

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'drawer_choose_language'.tr,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...[
              ('fr', 'language_french'.tr),
              ('en', 'language_english'.tr),
              ('ln', 'language_lingala'.tr),
              ('sw', 'language_swahili'.tr),
            ].map(
              (entry) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  currentCode == entry.$1
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: AppColors.primary,
                ),
                title: Text(entry.$2),
                onTap: () async {
                  await AppTranslations.changeLocale(entry.$1);
                  Get.back();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    user = Setting.userCtrl.user.value;
    final currentLanguageCode =
        AppTranslations.codeFromLocale(Get.locale ?? AppTranslations.fallback);

    return Drawer(
      shadowColor: Colors.transparent,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            padding: const EdgeInsets.all(8.0),
            decoration: const BoxDecoration(color: AppColors.primary),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage(Assets.logo_white),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user?.nom ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${'drawer_credits'.tr}: ${user?.credits ?? 0}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: Text('drawer_home'.tr),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: Text('drawer_profile'.tr),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: Text('drawer_history'.tr),
            onTap: () {
              Navigator.pop(context);
              Get.to(() => const ConversationsHistoryScreen());
            },
          ),
          ListTile(
            leading: const Icon(Icons.directions_car),
            title: Text('drawer_car'.tr),
            onTap: () {
              Navigator.pop(context);
              Get.to(() => const MyCarScreen());
            },
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text('drawer_language'.tr),
            subtitle: Text(AppTranslations.labelFromCode(currentLanguageCode)),
            onTap: () {
              Navigator.pop(context);
              _showLanguageSheet();
            },
          ),
          ListTile(
            leading: const Icon(Icons.credit_card),
            title: Text(
              'drawer_buy_credits'.tr,
              style: const TextStyle(color: Colors.blue),
            ),
            onTap: () {
              Navigator.pop(context);
              Get.to(() => const BuyCreditsScreen());
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: Text('drawer_about'.tr),
            onTap: () {
              Navigator.pop(context);
              Get.to(() => const AboutScreen());
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(
              'drawer_logout'.tr,
              style: const TextStyle(color: Colors.red),
            ),
            onTap: () async {
              Navigator.pop(context);
              await Setting.userCtrl.deconnectUser();
            },
          ),
        ],
      ),
    );
  }
}
