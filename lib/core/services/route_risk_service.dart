import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/road_report.dart';
import '../models/route_result.dart';
import '../models/route_segment.dart';

class RouteRiskService {
  final CollectionReference<Map<String, dynamic>> collection;

  RouteRiskService({
    required this.collection,
  });

  Future<RouteResult> attachWarnings(RouteResult routeResult) async {
    try {
      final reports = await _getCandidateReports(routeResult);
      if (reports.isEmpty) {
        return routeResult;
      }

      final matchedReports = reports
          .where((report) => _isReportNearRoute(report, routeResult.geometry))
          .toList();

      if (matchedReports.isEmpty) {
        return routeResult;
      }

      final warnings = matchedReports
          .map(
            (report) => {
              'reportId': report.id,
              'type': report.type,
              'severity': report.severity,
              'latitude': report.latitude,
              'longitude': report.longitude,
              'status': report.status,
              'createdAt': report.createdAt?.toIso8601String(),
            },
          )
          .toList();

      final updatedSegments = routeResult.segments.isEmpty
          ? routeResult.segments
          : <RouteSegment>[
              routeResult.segments.first.copyWith(
                riskLevel: _buildRiskLevel(matchedReports),
                relatedReports: matchedReports
                    .map((report) => report.id)
                    .whereType<String>()
                    .toList(),
              ),
              ...routeResult.segments.skip(1),
            ];

      return routeResult.copyWith(
        warnings: warnings,
        segments: updatedSegments,
      );
    } catch (_) {
      return routeResult;
    }
  }

  Future<List<RoadReport>> _getCandidateReports(RouteResult routeResult) async {
    final latitudes = routeResult.geometry
        .map((point) => (point['latitude'] as num?)?.toDouble())
        .whereType<double>()
        .toList();
    final longitudes = routeResult.geometry
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

    final snapshot = await collection
        .where('latitude', isGreaterThanOrEqualTo: minLat)
        .where('latitude', isLessThanOrEqualTo: maxLat)
        .limit(50)
        .get();

    return snapshot.docs
        .map((doc) {
          final report = RoadReport.fromJson(doc.data());
          return report.copyWith(id: doc.id);
        })
        .where((report) => report.longitude >= minLng && report.longitude <= maxLng)
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
      if (distance <= 0.2) {
        return true;
      }
    }

    return false;
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

  double _distanceKm(
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
