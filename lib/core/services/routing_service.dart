import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

import '../models/route_result.dart';
import '../models/route_segment.dart';

class RoutingService {
  final String googleApiKey;
  final PolylinePoints _polylinePoints;
  final Dio _dio;

  RoutingService({
    required this.googleApiKey,
    PolylinePoints? polylinePoints,
    Dio? dio,
  }) : _polylinePoints = polylinePoints ?? PolylinePoints(),
       _dio = dio ?? Dio();

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
      final routes = await calculateRoutes(
        userId: userId,
        startLat: startLat,
        startLng: startLng,
        destinationLat: destinationLat,
        destinationLng: destinationLng,
        startLabel: startLabel,
        destinationLabel: destinationLabel,
        waypoints: waypoints,
        alternatives: false,
      );
      return routes.isEmpty ? null : routes.first;
    } catch (_) {
      return null;
    }
  }

  Future<List<RouteResult>> calculateRoutes({
    required String? userId,
    required double startLat,
    required double startLng,
    required double destinationLat,
    required double destinationLng,
    String? startLabel,
    String? destinationLabel,
    List<Map<String, dynamic>> waypoints = const [],
    bool alternatives = true,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://maps.googleapis.com/maps/api/directions/json',
        queryParameters: {
          'origin': '$startLat,$startLng',
          'destination': '$destinationLat,$destinationLng',
          'mode': 'driving',
          'language': 'fr',
          'alternatives': alternatives ? 'true' : 'false',
          'key': googleApiKey,
          if (waypoints.isNotEmpty)
            'waypoints': waypoints
                .map((wp) => '${wp['latitude']},${wp['longitude']}')
                .join('|'),
        },
      );

      final data = response.data;
      final routes = data?['routes'];
      if (routes is! List || routes.isEmpty) {
        return const [];
      }

      final results = <RouteResult>[];
      for (final routeData in routes.whereType<Map>()) {
        final route = Map<String, dynamic>.from(routeData);
        final result = _buildRouteResult(
          route: route,
          userId: userId,
          startLat: startLat,
          startLng: startLng,
          destinationLat: destinationLat,
          destinationLng: destinationLng,
          startLabel: startLabel,
          destinationLabel: destinationLabel,
        );
        if (result != null) {
          results.add(result);
        }
      }

      if (alternatives && results.length < 2 && waypoints.isEmpty) {
        return _withFallbackAlternatives(
          currentRoutes: results,
          userId: userId,
          startLat: startLat,
          startLng: startLng,
          destinationLat: destinationLat,
          destinationLng: destinationLng,
          startLabel: startLabel,
          destinationLabel: destinationLabel,
        );
      }

      return _dedupeRoutes(results);
    } catch (_) {
      return const [];
    }
  }

  Future<List<RouteResult>> _withFallbackAlternatives({
    required List<RouteResult> currentRoutes,
    required String? userId,
    required double startLat,
    required double startLng,
    required double destinationLat,
    required double destinationLng,
    String? startLabel,
    String? destinationLabel,
  }) async {
    final routes = List<RouteResult>.from(currentRoutes);

    for (final waypoint in _buildFallbackWaypoints(
      startLat: startLat,
      startLng: startLng,
      destinationLat: destinationLat,
      destinationLng: destinationLng,
    )) {
      try {
        final response = await _dio.get<Map<String, dynamic>>(
          'https://maps.googleapis.com/maps/api/directions/json',
          queryParameters: {
            'origin': '$startLat,$startLng',
            'destination': '$destinationLat,$destinationLng',
            'mode': 'driving',
            'language': 'fr',
            'alternatives': 'false',
            'waypoints': '${waypoint['latitude']},${waypoint['longitude']}',
            'key': googleApiKey,
          },
        );

        final routeList =
            (response.data?['routes'] as List?)?.whereType<Map>().toList() ??
            const <Map>[];
        if (routeList.isEmpty) {
          continue;
        }

        final result = _buildRouteResult(
          route: Map<String, dynamic>.from(routeList.first),
          userId: userId,
          startLat: startLat,
          startLng: startLng,
          destinationLat: destinationLat,
          destinationLng: destinationLng,
          startLabel: startLabel,
          destinationLabel: destinationLabel,
        );
        if (result != null) {
          routes.add(result);
        }
      } catch (_) {
        continue;
      }

      if (_dedupeRoutes(routes).length >= 3) {
        break;
      }
    }

    return _dedupeRoutes(routes);
  }

  List<Map<String, double>> _buildFallbackWaypoints({
    required double startLat,
    required double startLng,
    required double destinationLat,
    required double destinationLng,
  }) {
    final deltaLat = destinationLat - startLat;
    final deltaLng = destinationLng - startLng;
    final length = math.sqrt((deltaLat * deltaLat) + (deltaLng * deltaLng));
    if (length == 0) {
      return const [];
    }

    final perpendicularLat = -deltaLng / length;
    final perpendicularLng = deltaLat / length;
    final offset = math.max(0.004, math.min(0.018, length * 0.35));
    final centerLat = (startLat + destinationLat) / 2;
    final centerLng = (startLng + destinationLng) / 2;

    return [
      {
        'latitude': centerLat + (perpendicularLat * offset),
        'longitude': centerLng + (perpendicularLng * offset),
      },
      {
        'latitude': centerLat - (perpendicularLat * offset),
        'longitude': centerLng - (perpendicularLng * offset),
      },
      {
        'latitude': centerLat + (perpendicularLat * offset * 1.6),
        'longitude': centerLng + (perpendicularLng * offset * 1.6),
      },
      {
        'latitude': centerLat - (perpendicularLat * offset * 1.6),
        'longitude': centerLng - (perpendicularLng * offset * 1.6),
      },
    ];
  }

  List<RouteResult> _dedupeRoutes(List<RouteResult> routes) {
    final seen = <String>{};
    final unique = <RouteResult>[];

    for (final route in routes) {
      final signature = _routeSignature(route);
      if (seen.add(signature)) {
        unique.add(route);
      }
    }

    return unique;
  }

  String _routeSignature(RouteResult route) {
    if (route.geometry.isEmpty) {
      return '${route.distance.toStringAsFixed(1)}:${route.duration.toStringAsFixed(1)}';
    }

    final step = math.max(1, route.geometry.length ~/ 8);
    return [
      route.distance.toStringAsFixed(1),
      route.duration.toStringAsFixed(1),
      for (var i = 0; i < route.geometry.length; i += step)
        '${_toDouble(route.geometry[i]['latitude'])?.toStringAsFixed(4)},${_toDouble(route.geometry[i]['longitude'])?.toStringAsFixed(4)}',
    ].join('|');
  }

  RouteResult? _buildRouteResult({
    required Map<String, dynamic> route,
    required String? userId,
    required double startLat,
    required double startLng,
    required double destinationLat,
    required double destinationLng,
    String? startLabel,
    String? destinationLabel,
  }) {
    try {
      final legs = (route['legs'] as List?)?.whereType<Map>().toList() ?? [];
      final encodedPolyline =
          (route['overview_polyline'] as Map?)?['points'] as String?;
      final points = _decodeDetailedRoutePoints(legs, encodedPolyline);

      if (points.isEmpty) {
        return null;
      }

      final geometry =
          points
              .map(
                (point) => {
                  'latitude': point.latitude,
                  'longitude': point.longitude,
                },
              )
              .toList();

      final distanceKm = _totalLegValue(legs, 'distance') / 1000;
      final durationMinutes = _totalLegValue(legs, 'duration') / 60;
      final segments = _buildSegmentsFromLegs(legs);

      return RouteResult(
        userId: userId,
        startLat: startLat,
        startLng: startLng,
        destinationLat: destinationLat,
        destinationLng: destinationLng,
        startLabel: startLabel,
        destinationLabel: destinationLabel,
        distance: distanceKm > 0 ? distanceKm : _calculateDistanceKm(points),
        duration:
            durationMinutes > 0
                ? durationMinutes
                : _estimateDurationMinutes(_calculateDistanceKm(points)),
        geometry: geometry,
        segments:
            segments.isNotEmpty
                ? segments
                : [
                  RouteSegment(
                    id: 'segment_1',
                    instruction:
                        'Suivre l itineraire principal jusqu a destination',
                    startLat: startLat,
                    startLng: startLng,
                    endLat: destinationLat,
                    endLng: destinationLng,
                    distance: distanceKm,
                    duration: durationMinutes,
                    riskLevel: 'unknown',
                    relatedReports: const [],
                  ),
                ],
        warnings: const [],
        createdAt: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  List<PointLatLng> _decodeDetailedRoutePoints(
    List<Map<dynamic, dynamic>> legs,
    String? overviewPolyline,
  ) {
    final detailedPoints = <PointLatLng>[];

    for (final leg in legs) {
      final steps = (leg['steps'] as List?)?.whereType<Map>().toList() ?? [];
      for (final step in steps) {
        final encodedStepPolyline =
            (step['polyline'] as Map?)?['points'] as String?;
        if (encodedStepPolyline == null || encodedStepPolyline.isEmpty) {
          continue;
        }

        for (final point in _polylinePoints.decodePolyline(
          encodedStepPolyline,
        )) {
          if (detailedPoints.isEmpty ||
              detailedPoints.last.latitude != point.latitude ||
              detailedPoints.last.longitude != point.longitude) {
            detailedPoints.add(point);
          }
        }
      }
    }

    if (detailedPoints.isNotEmpty) {
      return detailedPoints;
    }

    return overviewPolyline == null
        ? <PointLatLng>[]
        : _polylinePoints.decodePolyline(overviewPolyline);
  }

  double _totalLegValue(List<Map<dynamic, dynamic>> legs, String key) {
    var total = 0.0;
    for (final leg in legs) {
      final value = (leg[key] as Map?)?['value'];
      if (value is num) {
        total += value.toDouble();
      }
    }
    return total;
  }

  List<RouteSegment> _buildSegmentsFromLegs(List<Map<dynamic, dynamic>> legs) {
    final segments = <RouteSegment>[];
    var index = 1;

    for (final leg in legs) {
      final steps = (leg['steps'] as List?)?.whereType<Map>().toList() ?? [];
      for (final step in steps) {
        final start = step['start_location'] as Map?;
        final end = step['end_location'] as Map?;
        final startLat = _toDouble(start?['lat']);
        final startLng = _toDouble(start?['lng']);
        final endLat = _toDouble(end?['lat']);
        final endLng = _toDouble(end?['lng']);

        if (startLat == null ||
            startLng == null ||
            endLat == null ||
            endLng == null) {
          continue;
        }

        final distanceKm =
            (_toDouble((step['distance'] as Map?)?['value']) ?? 0) / 1000;
        final durationMin =
            (_toDouble((step['duration'] as Map?)?['value']) ?? 0) / 60;
        final instruction = _cleanInstruction(
          step['html_instructions']?.toString() ?? '',
          step['maneuver']?.toString(),
        );

        segments.add(
          RouteSegment(
            id: 'segment_$index',
            instruction: instruction,
            startLat: startLat,
            startLng: startLng,
            endLat: endLat,
            endLng: endLng,
            distance: distanceKm,
            duration: durationMin,
            riskLevel: 'unknown',
            relatedReports: const [],
          ),
        );
        index++;
      }
    }

    return segments;
  }

  String _cleanInstruction(String htmlInstruction, String? maneuver) {
    final withoutTags =
        htmlInstruction
            .replaceAll(RegExp(r'<div[^>]*>'), '. ')
            .replaceAll(RegExp(r'<[^>]+>'), '')
            .replaceAll('&nbsp;', ' ')
            .replaceAll('&amp;', '&')
            .replaceAll('&quot;', '"')
            .replaceAll('&#39;', "'")
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();

    if (withoutTags.isNotEmpty) {
      return withoutTags;
    }

    return _maneuverLabel(maneuver) ?? 'Continuer sur l itineraire';
  }

  String? _maneuverLabel(String? maneuver) {
    switch (maneuver) {
      case 'turn-left':
        return 'Tourner a gauche';
      case 'turn-right':
        return 'Tourner a droite';
      case 'turn-slight-left':
        return 'Tourner legerement a gauche';
      case 'turn-slight-right':
        return 'Tourner legerement a droite';
      case 'roundabout-left':
      case 'roundabout-right':
        return 'Prendre le rond-point';
      case 'straight':
        return 'Continuer tout droit';
    }
    return null;
  }

  double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
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

  double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final sinLat = math.sin(dLat / 2);
    final sinLng = math.sin(dLng / 2);

    final a =
        (sinLat * sinLat) +
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
