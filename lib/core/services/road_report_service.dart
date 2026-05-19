import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/road_report.dart';

class RoadReportService {
  final CollectionReference<Map<String, dynamic>> collection;

  RoadReportService({
    required this.collection,
  });

  RoadReport buildUserReport({
    required String? userId,
    required double latitude,
    required double longitude,
    String? segmentId,
    String? routeId,
    String type = 'mauvaise_route',
    String severity = 'moyen',
    String? comment,
  }) {
    return RoadReport(
      userId: userId,
      latitude: latitude,
      longitude: longitude,
      segmentId: segmentId,
      routeId: routeId,
      type: type,
      severity: severity,
      comment: comment,
      imageUrls: const [],
      sensorData: null,
      source: 'user',
      status: 'pending',
      createdAt: DateTime.now(),
    );
  }

  Future<String?> saveRoadReport(RoadReport report) async {
    try {
      final doc = await collection.add(report.toJson());
      return doc.id;
    } catch (_) {
      return null;
    }
  }

  Future<List<RoadReport>> getRoadReportsForUser(
    String userId, {
    int limit = 5,
  }) async {
    try {
      final snapshot = await collection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => RoadReport.fromJson(doc.data()))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
