import 'package:botroad/ui/animations/app_animations.dart';
import 'package:botroad/ui/screens/chat/ai_chat_screen.dart';
import 'package:botroad/ui/screens/alerts/alerts_screen.dart';
import 'package:botroad/ui/screens/history/history_screen.dart';
import 'package:botroad/ui/screens/main/main_nav_controller.dart';
import 'package:botroad/ui/screens/map/map_tab_screen.dart';
import 'package:botroad/ui/screens/profile/profile_screen.dart';
import 'package:botroad/controllers/theme_controller.dart';
import 'package:botroad/ui/widgets/v2/floating_bottom_nav.dart';
import 'package:botroad/utils/const/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Coque principale — 5 onglets, Assistant par défaut.
class MainShell extends StatelessWidget {
  const MainShell({super.key, this.initialIndex = 0});

  /// 0=Assistant, 1=Carte, 2=Alertes, 3=Historique, 4=Profil
  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    final nav = Get.put(MainNavController(), permanent: true);
    nav.currentIndex.value = initialIndex;
    final themeCtrl = Get.find<ThemeController>();

    return Obx(
      () {
        // Lu explicitement pour que ce Obx (et donc tout l'IndexedStack en
        // dessous) se reconstruise dès le bascule du thème, pas seulement au
        // changement d'onglet. Les enfants ne doivent plus être `const` :
        // un widget const est canonicalisé par Dart, donc Flutter le
        // considère comme strictement identique à chaque rebuild et saute
        // carrément l'appel à build() dessus — c'est ce qui empêchait
        // AppColors.* de se rafraîchir dans ces écrans.
        themeCtrl.isDark.value;
        return Scaffold(
          backgroundColor: AppColors.background,
          extendBody: false,
          body: _FadeIndexedStack(
            index: nav.currentIndex.value,
            children: [
              AIChatScreen(embedded: true),
              MapTabScreen(),
              AlertsScreen(isVisible: nav.currentIndex.value == 2),
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
        );
      },
    );
  }
}

/// IndexedStack avec fondu d'entrée à chaque changement d'onglet.
class _FadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const _FadeIndexedStack({required this.index, required this.children});

  @override
  State<_FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<_FadeIndexedStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: AppAnimations.fast);
    _fade = CurvedAnimation(parent: _ctrl, curve: AppAnimations.enter);
    _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant _FadeIndexedStack old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: IndexedStack(
        index: widget.index,
        children: widget.children,
      ),
    );
  }
}
