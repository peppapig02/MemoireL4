import 'dart:math' as math;

import 'package:flutter_polyline_points/flutter_polyline_points.dart';

import '../models/route_result.dart';
import '../models/route_segment.dart';

class RoutingService {
  final String googleApiKey;
  final PolylinePoints _polylinePoints;

  RoutingService({
    required this.googleApiKey,
    PolylinePoints? polylinePoints,
  }) : _polylinePoints = polylinePoints ?? PolylinePoints();

  Future<RouteResult?> calculateRoute({
    required String? userId,
    required double startLat,
    required double startLng,
    required double destinationLat,
    required double destinationLng,
    String? startLabel,
    String? destinationLabel,
    List<Map<String, dynamic>> waypoints = const [],
  }) async {
    try {
      final result = await _polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: googleApiKey,
        request: PolylineRequest(
          origin: PointLatLng(startLat, startLng),
          destination: PointLatLng(destinationLat, destinationLng),
          mode: TravelMode.driving,
          wayPoints: waypoints
              .map(
                (wp) => PolylineWayPoint(
                  location: '${wp['latitude']},${wp['longitude']}',
                  stopOver: true,
                ),
              )
              .toList(),
        ),
      );

      if (result.points.isEmpty) {
        return null;
      }

      final geometry = result.points
          .map(
            (point) => {
              'latitude': point.latitude,
              'longitude': point.longitude,
            },
          )
          .toList();

      final distanceKm = _calculateDistanceKm(result.points);
      final durationMinutes = _estimateDurationMinutes(distanceKm);

      final segments = <RouteSegment>[
        RouteSegment(
          id: 'segment_1',
          instruction: 'Suivre l\'itineraire principal jusqu\'a destination',
          startLat: startLat,
          startLng: startLng,
          endLat: destinationLat,
          endLng: destinationLng,
          distance: distanceKm,
          duration: durationMinutes,
          riskLevel: 'unknown',
          relatedReports: const [],
        ),
      ];

      return RouteResult(
        userId: userId,
        startLat: startLat,
        startLng: startLng,
        destinationLat: destinationLat,
        destinationLng: destinationLng,
        startLabel: startLabel,
        destinationLabel: destinationLabel,
        distance: distanceKm,
        duration: durationMinutes,
        geometry: geometry,
        segments: segments,
        warnings: const [],
        createdAt: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  double _calculateDistanceKm(List<PointLatLng> points) {
    if (points.length < 2) {
      return 0;
    }

    var totalKm = 0.0;
    for (var i = 0; i < points.length - 1; i++) {
      totalKm += _haversineKm(
        points[i].latitude,
        points[i].longitude,
        points[i + 1].latitude,
        points[i + 1].longitude,
      );
    }

    return totalKm;
  }

  double _estimateDurationMinutes(double distanceKm) {
    const averageCitySpeedKmH = 30.0;
    if (distanceKm <= 0) {
      return 0;
    }

    return (distanceKm / averageCitySpeedKmH) * 60;
  }

  double _haversineKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final sinLat = math.sin(dLat / 2);
    final sinLng = math.sin(dLng / 2);

    final a = (sinLat * sinLat) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            (sinLng * sinLng);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degToRad(double degrees) {
    return degrees * (math.pi / 180);
  }
}
