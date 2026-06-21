import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/road_report.dart';
import '../models/route_result.dart';
import '../models/route_segment.dart';

class RouteRiskService {
  final CollectionReference<Map<String, dynamic>> collection;

  RouteRiskService({required this.collection});

  Future<List<RouteResult>> attachWarningsToRoutes(
    List<RouteResult> routes,
  ) async {
    final checkedRoutes = <RouteResult>[];
    for (final route in routes) {
      checkedRoutes.add(await attachWarnings(route));
    }
    return checkedRoutes;
  }

  RouteResult chooseBestRoute(List<RouteResult> routes, String mode) {
    if (routes.isEmpty) {
      throw ArgumentError('routes must not be empty');
    }

    final normalizedMode = _normalizeMode(mode);
    final ranked =
        routes
            .map(
              (route) => route.copyWith(
                mode: normalizedMode,
                riskScore: calculateRiskScore(route),
              ),
            )
            .toList();

    ranked.sort((a, b) {
      final scoreComparison = _modeScore(
        a,
        normalizedMode,
      ).compareTo(_modeScore(b, normalizedMode));
      if (scoreComparison != 0) {
        return scoreComparison;
      }
      return a.distance.compareTo(b.distance);
    });

    return ranked.first;
  }

  double calculateRiskScore(RouteResult route) {
    var score = 0.0;
    for (final warning in route.warnings) {
      final severity = warning['severity']?.toString();
      final confirmations =
          (warning['confirmationCount'] as num?)?.toDouble() ?? 0;
      final refutations = (warning['refutationCount'] as num?)?.toDouble() ?? 0;
      final confidenceFactor =
          (1 + (confirmations * 0.25) - (refutations * 0.2)).clamp(0.35, 2.0);
      score += _severityWeight(severity) * confidenceFactor;
    }
    return score;
  }

  Future<RouteResult> attachWarnings(RouteResult routeResult) async {
    try {
      final reports = await _getCandidateReports(routeResult);
      if (reports.isEmpty) {
        return routeResult.copyWith(riskScore: 0);
      }

      final matchedReports =
          reports
              .where(
                (report) => _isReportNearRoute(report, routeResult.geometry),
              )
              .toList();

      if (matchedReports.isEmpty) {
        return routeResult.copyWith(riskScore: 0);
      }

      final warnings =
          matchedReports
              .map(
                (report) => {
                  'reportId': report.id,
                  'type': report.type,
                  'severity': report.severity,
                  'latitude': report.latitude,
                  'longitude': report.longitude,
                  'locationLabel': report.locationLabel,
                  'locationAddress': report.locationAddress,
                  'segmentId': report.segmentId,
                  'routeId': report.routeId,
                  'status': report.status,
                  'createdAt': report.createdAt?.toIso8601String(),
                  'expiresAt': report.expiresAt?.toIso8601String(),
                  'radiusMeters': report.radiusMeters,
                  'confirmationCount': report.confirmationCount,
                  'refutationCount': report.refutationCount,
                },
              )
              .toList();

      final updatedSegments =
          routeResult.segments.isEmpty
              ? routeResult.segments
              : routeResult.segments.map((segment) {
                final reportsForSegment =
                    matchedReports
                        .where(
                          (report) => _isReportNearSegment(report, segment),
                        )
                        .toList();

                if (reportsForSegment.isEmpty) {
                  return segment;
                }

                return segment.copyWith(
                  riskLevel: _buildRiskLevel(reportsForSegment),
                  relatedReports:
                      reportsForSegment
                          .map((report) => report.id)
                          .whereType<String>()
                          .toList(),
                );
              }).toList();

      final updatedRoute = routeResult.copyWith(
        warnings: warnings,
        segments: updatedSegments,
      );
      return updatedRoute.copyWith(riskScore: calculateRiskScore(updatedRoute));
    } catch (_) {
      return routeResult;
    }
  }

  String _normalizeMode(String mode) {
    return switch (mode) {
      'safe' => 'safe',
      'balanced' => 'balanced',
      _ => 'fast',
    };
  }

  double _modeScore(RouteResult route, String mode) {
    final risk =
        route.riskScore > 0 ? route.riskScore : calculateRiskScore(route);
    return switch (mode) {
      'safe' => (risk * 1000) + (route.duration * 1.5) + route.distance,
      'balanced' =>
        (risk * 450) + (route.duration * 2.5) + (route.distance * 4),
      _ =>
        route.duration +
            (route.distance * 0.2) +
            _trafficAndBlockagePenalty(route),
    };
  }

  double _trafficAndBlockagePenalty(RouteResult route) {
    var penaltyMinutes = 0.0;
    for (final warning in route.warnings) {
      final type = warning['type']?.toString();
      final severity = warning['severity']?.toString();
      final confirmations =
          (warning['confirmationCount'] as num?)?.toDouble() ?? 0;
      final refutations = (warning['refutationCount'] as num?)?.toDouble() ?? 0;
      final confidence = (1 + confirmations * 0.2 - refutations * 0.15).clamp(
        0.4,
        2.0,
      );

      final basePenalty = switch (type) {
        'embouteillage' => switch (severity) {
          'eleve' => 25.0,
          'moyen' => 12.0,
          _ => 5.0,
        },
        'accident' || 'inondation' => switch (severity) {
          'eleve' => 20.0,
          'moyen' => 9.0,
          _ => 4.0,
        },
        'danger' || 'trou' || 'mauvaise_route' => switch (severity) {
          'eleve' => 8.0,
          'moyen' => 3.0,
          _ => 1.0,
        },
        _ => 0.0,
      };
      penaltyMinutes += basePenalty * confidence;
    }
    return penaltyMinutes;
  }

  double _severityWeight(String? severity) {
    return switch (severity) {
      'eleve' => 100,
      'moyen' => 35,
      _ => 12,
    };
  }

  Future<List<RoadReport>> _getCandidateReports(RouteResult routeResult) async {
    final latitudes =
        routeResult.geometry
            .map((point) => (point['latitude'] as num?)?.toDouble())
            .whereType<double>()
            .toList();
    final longitudes =
        routeResult.geometry
            .map((point) => (point['longitude'] as num?)?.toDouble())
            .whereType<double>()
            .toList();

    if (latitudes.isEmpty || longitudes.isEmpty) {
      return const [];
    }

    final minLat = latitudes.reduce(math.min) - 0.02;
    final maxLat = latitudes.reduce(math.max) + 0.02;
    final minLng = longitudes.reduce(math.min) - 0.02;
    final maxLng = longitudes.reduce(math.max) + 0.02;

    final snapshot =
        await collection
            .where('latitude', isGreaterThanOrEqualTo: minLat)
            .where('latitude', isLessThanOrEqualTo: maxLat)
            .limit(50)
            .get();

    return snapshot.docs
        .map((doc) {
          final report = RoadReport.fromJson(doc.data());
          return report.copyWith(id: doc.id);
        })
        .where(
          (report) =>
              report.longitude >= minLng &&
              report.longitude <= maxLng &&
              report.isActive,
        )
        .toList();
  }

  bool _isReportNearRoute(
    RoadReport report,
    List<Map<String, dynamic>> geometry,
  ) {
    for (final point in geometry) {
      final pointLat = (point['latitude'] as num?)?.toDouble();
      final pointLng = (point['longitude'] as num?)?.toDouble();
      if (pointLat == null || pointLng == null) {
        continue;
      }

      final distance = _distanceKm(
        report.latitude,
        report.longitude,
        pointLat,
        pointLng,
      );
      if (distance <= report.radiusMeters / 1000) {
        return true;
      }
    }

    return false;
  }

  bool _isReportNearSegment(RoadReport report, RouteSegment segment) {
    final distance = _distancePointToSegmentKm(
      report.latitude,
      report.longitude,
      segment.startLat,
      segment.startLng,
      segment.endLat,
      segment.endLng,
    );
    return distance <= report.radiusMeters / 1000;
  }

  String _buildRiskLevel(List<RoadReport> reports) {
    if (reports.any((report) => report.severity == 'eleve')) {
      return 'high';
    }
    if (reports.any((report) => report.severity == 'moyen')) {
      return 'medium';
    }
    return 'low';
  }

  double _distanceKm(double lat1, double lng1, double lat2, double lng2) {
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

  double _distancePointToSegmentKm(
    double pointLat,
    double pointLng,
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    const earthRadiusKm = 6371.0;
    final latReference = _degToRad((pointLat + startLat + endLat) / 3);

    final px = _degToRad(pointLng) * math.cos(latReference) * earthRadiusKm;
    final py = _degToRad(pointLat) * earthRadiusKm;
    final sx = _degToRad(startLng) * math.cos(latReference) * earthRadiusKm;
    final sy = _degToRad(startLat) * earthRadiusKm;
    final ex = _degToRad(endLng) * math.cos(latReference) * earthRadiusKm;
    final ey = _degToRad(endLat) * earthRadiusKm;

    final dx = ex - sx;
    final dy = ey - sy;
    if (dx == 0 && dy == 0) {
      return _distanceKm(pointLat, pointLng, startLat, startLng);
    }

    final t = (((px - sx) * dx) + ((py - sy) * dy)) / ((dx * dx) + (dy * dy));
    final clampedT = t.clamp(0.0, 1.0);
    final closestX = sx + (clampedT * dx);
    final closestY = sy + (clampedT * dy);

    final xDistance = px - closestX;
    final yDistance = py - closestY;
    return math.sqrt((xDistance * xDistance) + (yDistance * yDistance));
  }
}
