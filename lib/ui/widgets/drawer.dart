import 'package:botroad/models/user_model.dart';
import 'package:botroad/ui/screens/profile/profile_screen.dart';
import 'package:botroad/utils/Setting.dart';
import 'package:botroad/utils/const/colors.dart';
import 'package:botroad/utils/const/images.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:botroad/ui/screens/credits/buy_credits_screen.dart';
import 'package:botroad/ui/screens/about/about_screen.dart';
import 'package:botroad/ui/screens/history/conversations_history_screen.dart';

class DrawerCustom extends StatelessWidget {
  DrawerCustom({super.key});
  UserModel? user;
  @override
  Widget build(BuildContext context) {
    user = Setting.userCtrl.user.value;
    return Drawer(
      shadowColor: Colors.transparent,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            padding: EdgeInsets.all(8.0),
            decoration: BoxDecoration(color: AppColors.primary),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage(Assets.logo_white),
                  ),
                  SizedBox(height: 10),
                  Text(
                    user?.nom ?? '',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Credits: ${user?.credits ?? 0}',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Accueil'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Profil'),
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
            title: const Text('Historique de discussions'),
            onTap: () {
              Navigator.pop(context);
              Get.to(() => const ConversationsHistoryScreen());
            },
          ),
          ListTile(
            leading: const Icon(Icons.credit_card),
            title: const Text(
              'Acheter des crédits',
              style: TextStyle(color: Colors.blue),
            ),
            onTap: () {
              Navigator.pop(context);
              Get.to(() => const BuyCreditsScreen());
            },
          ),
          Divider(),
          // ListTile(
          //   leading: const Icon(Icons.settings),
          //   title: const Text('Paramètres'),
          //   onTap: () {
          //     Navigator.pop(context);
          //   },
          // ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('À propos'),
            onTap: () {
              Navigator.pop(context);
              Get.to(() => const AboutScreen());
            },
          ),

          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text(
              'Déconnexion',
              style: TextStyle(color: Colors.red),
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
