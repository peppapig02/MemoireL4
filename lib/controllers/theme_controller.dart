import 'package:botroad/utils/const/colors.dart';
import 'package:botroad/utils/Setting.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController {
  static const _key = 'theme_dark';

  late final RxBool isDark;

  @override
  void onInit() {
    super.onInit();
    final saved = GetStorage(Setting.storageName).read<bool>(_key) ?? false;
    isDark = saved.obs;
  }

  void toggle() {
    isDark.value = !isDark.value;
    AppColors.setMode(isDark.value);
    GetStorage(Setting.storageName).write(_key, isDark.value);
    Get.changeThemeMode(isDark.value ? ThemeMode.dark : ThemeMode.light);
  }
}
