import 'dart:math' as math;

import 'package:botroad/models/routes_model.dart';
import 'package:get/get.dart';

/// Métadonnées d'itinéraire affichées dans une carte enrichie du chat.
class RouteCardInfo {
  final RoutesModel route;
  final String departure;
  final String destination;
  final double distanceKm;
  final double durationMin;
  final int warningCount;

  const RouteCardInfo({
    required this.route,
    required this.departure,
    required this.destination,
    required this.distanceKm,
    required this.durationMin,
    this.warningCount = 0,
  });

  String get trafficStatus =>
      warningCount > 0 ? 'Trafic / route signalés' : 'Fluide';

  String get roadQuality =>
      warningCount >= 3
          ? 'Route dégradée'
          : warningCount > 0
              ? 'Qualité moyenne'
              : 'Bonne';
}

/// Partage l'itinéraire actif entre Assistant et Carte sans toucher au backend.
class ActiveRouteController extends GetxController {
  final Rx<RoutesModel?> activeRoute = Rx<RoutesModel?>(null);
  final RxMap<String, RouteCardInfo> routeCardsByMessageId =
      <String, RouteCardInfo>{}.obs;
  final RxBool isNavigating = false.obs;

  void setActiveRoute(
    RoutesModel route, {
    RouteCardInfo? cardInfo,
    String? messageId,
  }) {
    activeRoute.value = route;
    if (messageId != null && cardInfo != null) {
      routeCardsByMessageId[messageId] = cardInfo;
    }
  }

  RouteCardInfo? cardForMessage(String? messageId) {
    if (messageId == null) return null;
    return routeCardsByMessageId[messageId];
  }

  void clearRoute() {
    activeRoute.value = null;
    isNavigating.value = false;
  }
}

RouteCardInfo routeCardFromResult({
  required RoutesModel route,
  required String departure,
  required String destination,
  required double distanceKm,
  required double durationMin,
  int warningCount = 0,
}) {
  return RouteCardInfo(
    route: route,
    departure: departure,
    destination: destination,
    distanceKm: distanceKm,
    durationMin: durationMin,
    warningCount: warningCount,
  );
}

/// Estime distance (km) à partir des points pipe-séparés.
double estimateDistanceFromPoints(String? points) {
  if (points == null || points.isEmpty) return 0;

  var totalDistance = 0.0;
  final routePoints = points.split('|');

  for (int i = 0; i < routePoints.length - 1; i++) {
    final point1 = routePoints[i].split(',');
    final point2 = routePoints[i + 1].split(',');
    if (point1.length < 2 || point2.length < 2) continue;

    final lat1 = double.tryParse(point1[0]) ?? 0;
    final lng1 = double.tryParse(point1[1]) ?? 0;
    final lat2 = double.tryParse(point2[0]) ?? 0;
    final lng2 = double.tryParse(point2[1]) ?? 0;

    const earthRadius = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.asin(math.sqrt(a));
    totalDistance += earthRadius * c;
  }

  return totalDistance;
}

double estimateDurationFromDistance(double km) => (km / 50 * 60);

double _toRad(double degree) => degree * 3.141592653589793 / 180;
