import 'package:botroad/ui/controllers/active_route_controller.dart';
import 'package:botroad/core/config/app_secrets.dart';
import 'package:botroad/core/models/road_report.dart';
import 'package:botroad/core/services/geocoding_service.dart';
import 'package:botroad/core/services/road_report_service.dart';
import 'package:botroad/core/services/route_risk_service.dart';
import 'package:botroad/core/services/routing_service.dart';
import 'package:botroad/models/routes_model.dart';
import 'package:botroad/ui/animations/app_animations.dart';
import 'package:botroad/ui/animations/skeleton.dart';
import 'package:botroad/ui/screens/home/iteneraire.dart';
import 'package:botroad/ui/screens/main/main_nav_controller.dart';
import 'package:botroad/ui/theme/app_tokens.dart';
import 'package:botroad/utils/const/colors.dart';
import 'package:botroad/utils/Setting.dart';
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
  bool _isSearching = false;
  bool _trafficEnabled = false;
  bool _alertsEnabled = false;
  List<RoadReport> _activeReports = const [];

  @override
  void initState() {
    super.initState();
    _loadUserPosition();
    Get.put(ActiveRouteController(), permanent: true);
    RoadReportService.refreshRevision.addListener(_refreshVisibleReports);
  }

  @override
  void dispose() {
    RoadReportService.refreshRevision.removeListener(_refreshVisibleReports);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshVisibleReports() async {
    if (!_alertsEnabled) return;
    final reports = await RoadReportService(
      collection: Setting.fRoadReports,
    ).getActiveRoadReports(limit: 100);
    if (!mounted) return;
    setState(() => _activeReports = reports);
  }

  Future<void> _toggleAlerts() async {
    final enabled = !_alertsEnabled;
    setState(() => _alertsEnabled = enabled);
    if (enabled) {
      await _refreshVisibleReports();
    } else if (mounted) {
      setState(() => _activeReports = const []);
    }
  }

  void _toggleTraffic() {
    setState(() => _trafficEnabled = !_trafficEnabled);
  }

  Set<Marker> get _alertMarkers {
    return _activeReports
        .where((report) => report.latitude != 0 && report.longitude != 0)
        .map(
          (report) => Marker(
            markerId: MarkerId(
              'map_alert_${report.id ?? '${report.latitude}_${report.longitude}'}',
            ),
            position: LatLng(report.latitude, report.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange,
            ),
            infoWindow: InfoWindow(
              title: _reportTypeLabel(report.type),
              snippet:
                  report.locationAddress ??
                  report.locationLabel ??
                  'Signalement actif',
            ),
          ),
        )
        .toSet();
  }

  String _reportTypeLabel(String type) {
    return switch (type) {
      'embouteillage' => 'Embouteillage',
      'accident' => 'Accident',
      'trou' => 'Route abimee',
      'inondation' => 'Inondation',
      'danger' => 'Danger',
      _ => 'Route deconseillee',
    };
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

  Future<void> _searchDestination(String query) async {
    final destinationText = query.trim();
    if (destinationText.isEmpty || _isSearching) return;

    setState(() => _isSearching = true);
    try {
      if (_userPosition == null) {
        await _loadUserPosition();
      }
      final start = _userPosition;
      if (start == null) {
        Setting.showMessage(
          'Localisation',
          "Impossible d'obtenir votre position actuelle.",
          Colors.red,
        );
        return;
      }

      final destination = await GeocodingService(
        apiKey: AppSecrets.googleMapsApiKey,
      ).geocodePlace(
        destinationText,
        biasLatitude: start.latitude,
        biasLongitude: start.longitude,
      );
      if (destination == null) {
        Setting.showMessage(
          'Destination',
          'Destination introuvable. Essayez avec un nom plus precis.',
          Colors.red,
        );
        return;
      }

      final routeCandidates = await RoutingService(
        googleApiKey: AppSecrets.googleMapsApiKey,
      ).calculateRoutes(
        userId: Setting.userCtrl.user.value.key,
        startLat: start.latitude,
        startLng: start.longitude,
        destinationLat: destination.latitude,
        destinationLng: destination.longitude,
        startLabel: 'Position actuelle',
        destinationLabel: destination.label,
        alternatives: true,
      );
      if (routeCandidates.isEmpty) {
        Setting.showMessage(
          'Itineraire',
          "Aucun itineraire routier n'a ete trouve.",
          Colors.red,
        );
        return;
      }

      final riskService = RouteRiskService(collection: Setting.fRoadReports);
      final checkedRoutes = await riskService.attachWarningsToRoutes(
        routeCandidates,
      );
      final routeResult = riskService.chooseBestRoute(checkedRoutes, 'fast');
      final route = RoutesModel(
        id_user: routeResult.userId,
        nom: 'Itineraire vers ${destination.label}',
        points: routeResult.geometry
            .map((point) => '${point['latitude']},${point['longitude']}')
            .join('|'),
        waypoints: const [],
        warnings: routeResult.warnings,
        segments:
            routeResult.segments.map((segment) => segment.toJson()).toList(),
        mode: routeResult.mode,
        risk_score: routeResult.riskScore,
        date_create: DateTime.now().toIso8601String(),
      );

      final routeController = Get.find<ActiveRouteController>();
      routeController.setActiveRoute(route);
      _searchController.text = destination.label;
    } catch (error) {
      printDebug('map destination search error::$error');
      Setting.showMessage(
        'Itineraire',
        "La recherche a echoue. Verifiez votre connexion puis reessayez.",
        Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
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
                trafficEnabled: _trafficEnabled,
                markers: _alertMarkers,
              ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _MapTopBar(
                  searchController: _searchController,
                  onAssistantTap: () => switchMainTab(0),
                  onLocateTap: _loadUserPosition,
                  onSearch: _searchDestination,
                  isSearching: _isSearching,
                ),
              ),
            ),
            if (route == null)
              Positioned(
                top: MediaQuery.of(context).padding.top + 76,
                right: 16,
                child: Column(
                  children: [
                    _MapLayerButton(
                      icon: LucideIcons.trafficCone,
                      active: _trafficEnabled,
                      color: AppColors.warning,
                      tooltip: 'Embouteillages',
                      onTap: _toggleTraffic,
                    ),
                    const SizedBox(height: 10),
                    _MapLayerButton(
                      icon: LucideIcons.triangleAlert,
                      active: _alertsEnabled,
                      color: AppColors.error,
                      tooltip: 'Signalements',
                      onTap: _toggleAlerts,
                    ),
                  ],
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
  final ValueChanged<String> onSearch;
  final bool isSearching;

  const _MapTopBar({
    required this.searchController,
    required this.onAssistantTap,
    required this.onLocateTap,
    required this.onSearch,
    required this.isSearching,
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
                suffixIcon:
                    isSearching
                        ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                        : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: onSearch,
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
          color:
              highlight
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
  final bool trafficEnabled;
  final Set<Marker> markers;

  const _EmptyMapView({
    required this.userPosition,
    required this.onMapCreated,
    required this.trafficEnabled,
    required this.markers,
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
            markers: markers,
            trafficEnabled: trafficEnabled,
            myLocationEnabled: userPosition != null,
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

class _MapLayerButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _MapLayerButton({
    required this.icon,
    required this.active,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: active ? color : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox.square(
            dimension: 48,
            child: Icon(
              icon,
              color: active ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
