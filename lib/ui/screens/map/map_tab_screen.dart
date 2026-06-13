import 'package:botroad/ui/controllers/active_route_controller.dart';
import 'package:botroad/ui/animations/app_animations.dart';
import 'package:botroad/ui/animations/skeleton.dart';
import 'package:botroad/ui/screens/home/iteneraire.dart';
import 'package:botroad/ui/screens/main/main_nav_controller.dart';
import 'package:botroad/ui/theme/app_tokens.dart';
import 'package:botroad/utils/const/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Onglet Carte — navigation plein écran, itinéraire partagé depuis l'assistant.
class MapTabScreen extends StatefulWidget {
  const MapTabScreen({super.key});

  @override
  State<MapTabScreen> createState() => _MapTabScreenState();
}

class _MapTabScreenState extends State<MapTabScreen> {
  final _searchController = TextEditingController();
  GoogleMapController? _mapController;
  LatLng? _userPosition;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _loadUserPosition();
    Get.put(ActiveRouteController(), permanent: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserPosition() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() => _userPosition = LatLng(pos.latitude, pos.longitude));
      _mapController?.animateCamera(CameraUpdate.newLatLng(_userPosition!));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final routeCtrl = Get.find<ActiveRouteController>();

    return Obx(() {
      final route = routeCtrl.activeRoute.value;

      return Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            if (route != null)
              Iteneraire(route: route, embedded: true)
            else
              _EmptyMapView(
                userPosition: _userPosition,
                onMapCreated: (c) {
                  _mapController = c;
                  setState(() => _mapReady = true);
                },
                mapReady: _mapReady,
              ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _MapTopBar(
                  searchController: _searchController,
                  onAssistantTap: () => switchMainTab(0),
                  onLocateTap: _loadUserPosition,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _MapTopBar extends StatelessWidget {
  final TextEditingController searchController;
  final VoidCallback onAssistantTap;
  final VoidCallback onLocateTap;

  const _MapTopBar({
    required this.searchController,
    required this.onAssistantTap,
    required this.onLocateTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconBtn(
          icon: CupertinoIcons.chat_bubble_2_fill,
          onTap: onAssistantTap,
          highlight: true,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              boxShadow: AppTokens.shadowSoft,
            ),
            child: TextField(
              controller: searchController,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Rechercher une destination...',
                hintStyle: Theme.of(context).textTheme.bodyMedium,
                prefixIcon: const Icon(LucideIcons.search, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onSubmitted: (_) => onAssistantTap(),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _IconBtn(icon: LucideIcons.locateFixed, onTap: onLocateTap),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool highlight;

  const _IconBtn({
    required this.icon,
    required this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: highlight
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: highlight ? AppTokens.glowAccent(opacity: 0.1) : null,
        ),
        child: Icon(
          icon,
          size: 20,
          color: highlight ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _EmptyMapView extends StatelessWidget {
  final LatLng? userPosition;
  final void Function(GoogleMapController) onMapCreated;
  final bool mapReady;

  const _EmptyMapView({
    required this.userPosition,
    required this.onMapCreated,
    this.mapReady = false,
  });

  @override
  Widget build(BuildContext context) {
    final center = userPosition ?? const LatLng(-4.322447, 15.307045);

    return Stack(
      children: [
        if (!mapReady) const MapSkeleton(),
        AnimatedOpacity(
          opacity: mapReady ? 1 : 0,
          duration: AppAnimations.slow,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(target: center, zoom: 13),
            onMapCreated: onMapCreated,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 120,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTokens.cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aucun itinéraire actif',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Demandez un trajet à l\'assistant pour afficher la route ici.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
