import 'package:botroad/core/services/network_status_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NetworkStatusBanner extends StatelessWidget {
  const NetworkStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final service = Get.isRegistered<NetworkStatusService>()
        ? Get.find<NetworkStatusService>()
        : Get.put(NetworkStatusService(), permanent: true);

    return Obx(() {
      final state = service.state.value;
      if (state == NetworkBannerState.hidden) {
        return const SizedBox.shrink();
      }

      final isOffline = state == NetworkBannerState.offline;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: isOffline ? const Color(0xFFD35400) : const Color(0xFF1E8449),
        child: SafeArea(
          bottom: false,
          child: Text(
            isOffline ? 'network_status_offline'.tr : 'network_status_online'.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    });
  }
}
