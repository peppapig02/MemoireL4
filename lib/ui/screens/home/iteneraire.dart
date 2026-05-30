import 'dart:async';
import 'dart:math' as math;

import 'package:botroad/core/services/network_status_service.dart';
import 'package:botroad/models/routes_model.dart';
import 'package:botroad/ui/widgets/network_status_banner.dart';
import 'package:botroad/utils/Setting.dart';
import 'package:botroad/utils/const/colors.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class Iteneraire extends StatefulWidget {
  final RoutesModel? route;

  const Iteneraire({super.key, this.route});

  @override
  State<Iteneraire> createState() => _IteneraireState();
}

class _IteneraireState extends State<Iteneraire> {
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  LatLngBounds? bounds;
  bool isNavigating = false;
  String? routeErrorMessage;
  late final NetworkStatusService networkStatusService;
  Position? currentPosition;
  Timer? navigationTimer;

  @override
  void initState() {
    super.initState();
    networkStatusService =
        Get.isRegistered<NetworkStatusService>()
            ? Get.find<NetworkStatusService>()
            : Get.put(NetworkStatusService(), permanent: true);
    _initializeMap();
  }

  @override
  void dispose() {
    navigationTimer?.cancel();
    super.dispose();
  }

  void _initializeMap() {
    if (widget.route?.points == null || widget.route!.points!.trim().isEmpty) {
      routeErrorMessage = 'itinerary_route_unavailable'.tr;
      networkStatusService.markOffline();
      return;
    }

    try {
      final points = widget.route!.points!.split('|').map((point) {
        final coords = point.split(',');
        return LatLng(double.parse(coords[0]), double.parse(coords[1]));
      }).toList();

      if (points.length < 2) {
        routeErrorMessage = 'itinerary_route_unavailable'.tr;
        networkStatusService.markOffline();
        return;
      }

      markers.add(
        Marker(
          markerId: const MarkerId('depart'),
          position: points.first,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(title: 'itinerary_depart'.tr),
        ),
      );

      markers.add(
        Marker(
          markerId: const MarkerId('arrivee'),
          position: points.last,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: 'itinerary_arrival'.tr),
        ),
      );

      if (widget.route?.waypoints != null) {
        for (var i = 0; i < widget.route!.waypoints!.length; i++) {
          final waypoint = widget.route!.waypoints![i];
          markers.add(
            Marker(
              markerId: MarkerId('etape_$i'),
              position: LatLng(
                waypoint['latitude'] as double,
                waypoint['longitude'] as double,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueBlue,
              ),
              infoWindow: InfoWindow(
                title: 'itinerary_step'.trParams({'index': '${i + 1}'}),
                snippet: waypoint['name'] as String?,
              ),
            ),
          );
        }
      }

      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: points,
          color: AppColors.primary,
          width: 5,
        ),
      );

      bounds = LatLngBounds(
        southwest: LatLng(
          points.map((p) => p.latitude).reduce((a, b) => a < b ? a : b),
          points.map((p) => p.longitude).reduce((a, b) => a < b ? a : b),
        ),
        northeast: LatLng(
          points.map((p) => p.latitude).reduce((a, b) => a > b ? a : b),
          points.map((p) => p.longitude).reduce((a, b) => a > b ? a : b),
        ),
      );
      networkStatusService.markOnline();
    } catch (e) {
      routeErrorMessage = 'itinerary_route_unavailable'.tr;
      networkStatusService.markOffline();
      printDebug('Erreur lors de l initialisation de la carte: $e');
    }
  }

  void _recenterMap() {
    if (mapController != null && bounds != null) {
      mapController!
          .animateCamera(CameraUpdate.newLatLngBounds(bounds!, 50))
          .catchError((error) {
            networkStatusService.markOffline();
            Setting.showMessage('login_error'.tr, 'itinerary_map_error'.tr);
            printDebug('Erreur lors du recentrage de la carte: $error');
          });
    }
  }

  void _startNavigation() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Setting.showMessage(
          'login_error'.tr,
          'itinerary_location_permission_error'.tr,
        );
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      Setting.showMessage(
        'login_error'.tr,
        'itinerary_location_permission_error'.tr,
      );
      return;
    }

    setState(() {
      isNavigating = true;
    });

    navigationTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        setState(() {
          currentPosition = position;
          mapController?.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(position.latitude, position.longitude),
            ),
          );
        });
        networkStatusService.markOnline();

        if (widget.route?.points != null) {
          final points = widget.route!.points!.split('|');
          final destination = points.last.split(',');
          final destLat = double.parse(destination[0]);
          final destLng = double.parse(destination[1]);

          final distance = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            destLat,
            destLng,
          );

          if (distance < 100) {
            navigationTimer?.cancel();
            setState(() {
              isNavigating = false;
            });
            Setting.showMessage(
              'itinerary_arrived_title'.tr,
              'itinerary_arrived_message'.tr,
            );
          }
        }
      } catch (e) {
        final normalized = e.toString().toLowerCase();
        final message =
            normalized.contains('unable to resolve host') ||
                    normalized.contains('socketexception') ||
                    normalized.contains('ioexception')
                ? 'itinerary_navigation_network_error'.tr
                : 'itinerary_location_permission_error'.tr;
        if (normalized.contains('unable to resolve host') ||
            normalized.contains('socketexception') ||
            normalized.contains('ioexception')) {
          networkStatusService.markOffline();
        }
        Setting.showMessage('login_error'.tr, message);
        navigationTimer?.cancel();
        setState(() {
          isNavigating = false;
        });
        printDebug('Erreur lors de la mise a jour de la position: $e');
      }
    });
  }

  void _stopNavigation() {
    navigationTimer?.cancel();
    setState(() {
      isNavigating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    printDebug('route name : ${widget.route?.nom}');

    var center = const LatLng(-4.322447, 15.307045);
    if (bounds != null) {
      center = LatLng(
        (bounds!.northeast.latitude + bounds!.southwest.latitude) / 2,
        (bounds!.northeast.longitude + bounds!.southwest.longitude) / 2,
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: const BackButton(color: Colors.black),
      ),
      body: routeErrorMessage != null
          ? Column(
              children: [
                const NetworkStatusBanner(),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        routeErrorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                const NetworkStatusBanner(),
                Expanded(
                  child: SizedBox(
                    height: height,
                    width: width,
                    child: Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: center,
                            zoom: 12,
                          ),
                          onMapCreated: (controller) {
                            mapController = controller;
                            if (bounds != null) {
                              controller
                                  .animateCamera(
                                    CameraUpdate.newLatLngBounds(bounds!, 50),
                                  )
                                  .then((_) {
                                    networkStatusService.markOnline();
                                  })
                                  .catchError((error) {
                                    networkStatusService.markOffline();
                                    Setting.showMessage(
                                      'login_error'.tr,
                                      'itinerary_map_error'.tr,
                                    );
                                    printDebug(
                                      'Erreur lors du cadrage initial de la carte: $error',
                                    );
                                  });
                            }
                          },
                          markers: markers,
                          polylines: polylines,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          zoomControlsEnabled: true,
                          mapToolbarEnabled: false,
                        ),
                        Positioned(
                          right: 16,
                          bottom: height * 0.45,
                          child: FloatingActionButton(
                            heroTag: 'recenter',
                            onPressed: _recenterMap,
                            backgroundColor: Colors.white,
                            child: Icon(
                              LucideIcons.maximize2,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: NavigationBottomSheet(
                            route: widget.route,
                            onStartNavigation:
                                isNavigating
                                    ? _stopNavigation
                                    : _startNavigation,
                            isNavigating: isNavigating,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class NavigationBottomSheet extends StatelessWidget {
  final RoutesModel? route;
  final Function()? onStartNavigation;
  final bool isNavigating;

  const NavigationBottomSheet({
    super.key,
    this.route,
    this.onStartNavigation,
    this.isNavigating = false,
  });

  String _formatDistance(String? points) {
    if (points == null || points.isEmpty) return '0 km';

    var totalDistance = 0.0;
    final routePoints = points.split('|');

    for (int i = 0; i < routePoints.length - 1; i++) {
      final point1 = routePoints[i].split(',');
      final point2 = routePoints[i + 1].split(',');

      final lat1 = double.parse(point1[0]);
      final lng1 = double.parse(point1[1]);
      final lat2 = double.parse(point2[0]);
      final lng2 = double.parse(point2[1]);

      const earthRadius = 6371.0;
      final dLat = _toRadians(lat2 - lat1);
      final dLng = _toRadians(lng2 - lng1);

      final a =
          math.sin(dLat / 2) * math.sin(dLat / 2) +
          math.cos(_toRadians(lat1)) *
              math.cos(_toRadians(lat2)) *
              math.sin(dLng / 2) *
              math.sin(dLng / 2);
      final c = 2 * math.asin(math.sqrt(a));
      totalDistance += earthRadius * c;
    }

    return '${totalDistance.toStringAsFixed(1)} km';
  }

  double _toRadians(double degree) {
    return degree * (3.141592653589793 / 180);
  }

  String _estimateDuration(String? points) {
    if (points == null || points.isEmpty) return '0 min';

    final distance = _formatDistance(points).replaceAll(' km', '');
    final hours = double.parse(distance) / 50;
    final minutes = (hours * 60).round();

    return '$minutes min';
  }

  String _buildWarningSummary(List<Map<String, dynamic>>? warnings) {
    if (warnings == null || warnings.isEmpty) return '';

    final count = warnings.length;
    final severeCount =
        warnings.where((warning) => warning['severity'] == 'eleve').length;

    if (severeCount > 0) {
      return 'itinerary_warning_summary_high'.trParams({
        'count': '$count',
        'severe': '$severeCount',
      });
    }

    return 'itinerary_warning_summary'.trParams({'count': '$count'});
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Container(
      height:
          route?.warnings?.isNotEmpty == true ? height * 0.38 : height * 0.3,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: const Color(0xFFF7F7F7),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 12, top: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          LucideIcons.route,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          route?.nom ?? 'itinerary_title'.tr,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatDistance(route?.points),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            _estimateDuration(route?.points),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (route?.warnings?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF4B860)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFC97A00),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'itinerary_reported_route'.tr,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8A5200),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _buildWarningSummary(route?.warnings),
                      style: const TextStyle(
                        color: Color(0xFF8A5200),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (route?.warnings?.isNotEmpty == true) const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: onStartNavigation,
              style: ElevatedButton.styleFrom(
                backgroundColor: isNavigating ? Colors.red : AppColors.primary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                isNavigating
                    ? 'itinerary_stop_navigation'.tr
                    : 'itinerary_start_navigation'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
