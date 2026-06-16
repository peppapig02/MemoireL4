import 'package:get/get.dart';

/// Contrôleur de l'onglet actif dans [MainShell].
class MainNavController extends GetxController {
  final RxInt currentIndex = 0.obs; // Assistant par défaut

  void switchTo(int index) {
    if (index >= 0 && index <= 4) {
      currentIndex.value = index;
    }
  }
}

void switchMainTab(int index) {
  if (Get.isRegistered<MainNavController>()) {
    Get.find<MainNavController>().switchTo(index);
  }
}
