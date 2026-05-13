import 'package:botroad/utils/Setting.dart';
import 'package:botroad/utils/const/colors.dart';
import 'package:botroad/utils/const/images.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:botroad/models/routes_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'dart:async';

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
  Position? currentPosition;
  Timer? navigationTimer;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    navigationTimer?.cancel();
    super.dispose();
  }

  void _initializeMap() {
    if (widget.route?.points != null) {
      // Convertir les points de la route en LatLng
      final points =
          widget.route!.points!.split('|').map((point) {
            final coords = point.split(',');
            return LatLng(double.parse(coords[0]), double.parse(coords[1]));
          }).toList();

      // Créer les marqueurs pour le départ et l'arrivée
      markers.add(
        Marker(
          markerId: const MarkerId('depart'),
          position: points.first,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: const InfoWindow(title: 'Départ'),
        ),
      );

      markers.add(
        Marker(
          markerId: const MarkerId('arrivee'),
          position: points.last,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Arrivée'),
        ),
      );

      // Ajouter les marqueurs pour les étapes intermédiaires
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
                title: 'Étape ${i + 1}',
                snippet: waypoint['name'] as String?,
              ),
            ),
          );
        }
      }

      // Créer la polyligne pour l'itinéraire
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: points,
          color: AppColors.primary,
          width: 5,
        ),
      );

      // Calculer les limites de la carte pour inclure tous les points
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
    }
  }

  void _recenterMap() {
    if (mapController != null && bounds != null) {
      mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds!, 50));
    }
  }

  void _startNavigation() async {
    // Vérifier les permissions de localisation
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Setting.showMessage(
          "Erreur",
          "La permission de localisation est nécessaire pour la navigation",
        );
        return;
      }
    }

    setState(() {
      isNavigating = true;
    });

    // Mettre à jour la position toutes les 5 secondes
    navigationTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        setState(() {
          currentPosition = position;
          // Mettre à jour la position sur la carte
          mapController?.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(position.latitude, position.longitude),
            ),
          );
        });

        // Vérifier si on est proche de la destination
        if (widget.route?.points != null) {
          final points = widget.route!.points!.split('|');
          final destination = points.last.split(',');
          final destLat = double.parse(destination[0]);
          final destLng = double.parse(destination[1]);

          double distance = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            destLat,
            destLng,
          );

          // Si on est à moins de 100 mètres de la destination
          if (distance < 100) {
            navigationTimer?.cancel();
            setState(() {
              isNavigating = false;
            });
            Setting.showMessage("Arrivée", "Vous êtes arrivé à destination !");
          }
        }
      } catch (e) {
        printDebug("Erreur lors de la mise à jour de la position: $e");
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
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    printDebug("route name : ${widget.route?.nom}");

    // Calculer le centre de la carte
    LatLng center = const LatLng(-4.322447, 15.307045); // Kinshasa par défaut
    if (bounds != null) {
      center = LatLng(
        (bounds!.northeast.latitude + bounds!.southwest.latitude) / 2,
        (bounds!.northeast.longitude + bounds!.southwest.longitude) / 2,
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: BackButton(color: Colors.black),
      ),
      body: Container(
        height: height,
        width: width,
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(target: center, zoom: 12),
              onMapCreated: (controller) {
                mapController = controller;
                if (bounds != null) {
                  controller.animateCamera(
                    CameraUpdate.newLatLngBounds(bounds!, 50),
                  );
                }
              },
              markers: markers,
              polylines: polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
              mapToolbarEnabled: false,
            ),
            // Bouton pour recentrer la carte
            Positioned(
              right: 16,
              bottom: height * 0.45, // Au-dessus de la NavigationBottomSheet
              child: FloatingActionButton(
                heroTag: 'recenter',
                onPressed: _recenterMap,
                backgroundColor: Colors.white,
                child: Icon(LucideIcons.maximize2, color: AppColors.primary),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: NavigationBottomSheet(
                route: widget.route,
                onStartNavigation:
                    isNavigating ? _stopNavigation : _startNavigation,
                isNavigating: isNavigating,
              ),
            ),
          ],
        ),
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

    // Calculer la distance totale en utilisant les points de la route
    double totalDistance = 0;
    final routePoints = points.split('|');

    for (int i = 0; i < routePoints.length - 1; i++) {
      final point1 = routePoints[i].split(',');
      final point2 = routePoints[i + 1].split(',');

      final lat1 = double.parse(point1[0]);
      final lng1 = double.parse(point1[1]);
      final lat2 = double.parse(point2[0]);
      final lng2 = double.parse(point2[1]);

      // Calculer la distance entre deux points (formule de Haversine)
      const double earthRadius = 6371; // Rayon de la Terre en km
      final dLat = _toRadians(lat2 - lat1);
      final dLng = _toRadians(lng2 - lng1);

      final a =
          math.sin(dLat / 2) * math.sin(dLat / 2) +
          math.cos(_toRadians(lat1)) *
              math.cos(_toRadians(lat2)) *
              math.sin(dLng / 2) *
              math.sin(dLng / 2);
      final c = 2 * math.asin(math.sqrt(a));
      final distance = earthRadius * c;

      totalDistance += distance;
    }

    return '${totalDistance.toStringAsFixed(1)} km';
  }

  double _toRadians(double degree) {
    return degree * (3.141592653589793 / 180);
  }

  String _estimateDuration(String? points) {
    if (points == null || points.isEmpty) return '0 min';

    // Estimation basée sur une vitesse moyenne de 50 km/h
    final distance = _formatDistance(points).replaceAll(' km', '');
    final hours = double.parse(distance) / 50;
    final minutes = (hours * 60).round();

    return '$minutes min';
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    return Container(
      height: height * 0.3, // Réduit la hauteur
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
          // Handle bar
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

                // Route info
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      // Route icon
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

                      // Route name
                      Expanded(
                        child: Text(
                          route?.nom ?? 'Itinéraire',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),

                      // Distance and time
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

          // Start/Stop navigation button
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
                    ? 'Arrêter la navigation'
                    : 'Démarrer la navigation',
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
