import 'dart:async';

import 'package:get/get.dart';

enum NetworkBannerState { hidden, offline, online }

class NetworkStatusService extends GetxService {
  final Rx<NetworkBannerState> state = NetworkBannerState.hidden.obs;

  Timer? _hideTimer;

  bool get isOffline => state.value == NetworkBannerState.offline;

  void markOffline() {
    _hideTimer?.cancel();
    state.value = NetworkBannerState.offline;
  }

  void markOnline() {
    if (state.value == NetworkBannerState.hidden) {
      return;
    }

    _hideTimer?.cancel();
    state.value = NetworkBannerState.online;
    _hideTimer = Timer(const Duration(seconds: 3), () {
      state.value = NetworkBannerState.hidden;
    });
  }

  @override
  void onClose() {
    _hideTimer?.cancel();
    super.onClose();
  }
}
