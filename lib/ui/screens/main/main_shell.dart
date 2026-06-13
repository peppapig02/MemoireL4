import 'package:botroad/ui/screens/chat/ai_chat_screen.dart';
import 'package:botroad/ui/screens/history/history_screen.dart';
import 'package:botroad/ui/screens/main/main_nav_controller.dart';
import 'package:botroad/ui/screens/map/map_tab_screen.dart';
import 'package:botroad/ui/screens/profile/profile_screen.dart';
import 'package:botroad/ui/widgets/v2/floating_bottom_nav.dart';
import 'package:botroad/utils/const/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Coque principale — 4 onglets, Assistant par défaut.
class MainShell extends StatelessWidget {
  const MainShell({super.key, this.initialIndex = 0});

  /// 0=Assistant, 1=Carte, 2=Historique, 3=Profil
  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    final nav = Get.put(MainNavController(), permanent: true);
    nav.currentIndex.value = initialIndex;

    return Obx(
      () => Scaffold(
        backgroundColor: AppColors.background,
        extendBody: true,
        body: IndexedStack(
          index: nav.currentIndex.value,
          children: const [
            AIChatScreen(embedded: true),
            MapTabScreen(),
            HistoryScreen(embedded: true),
            ProfileScreen(embedded: true),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: FloatingBottomNav(
            currentIndex: nav.currentIndex.value,
            onTap: nav.switchTo,
          ),
        ),
      ),
    );
  }
}
