import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/road_report.dart';

class RoadReportService {
  static final ValueNotifier<int> refreshRevision = ValueNotifier<int>(0);

  final CollectionReference<Map<String, dynamic>> collection;

  RoadReportService({required this.collection});

  RoadReport buildUserReport({
    required String? userId,
    required double latitude,
    required double longitude,
    String? locationLabel,
    String? locationAddress,
    String? segmentId,
    String? routeId,
    String type = 'mauvaise_route',
    String severity = 'moyen',
    String? comment,
    Duration validity = const Duration(hours: 48),
    double radiusMeters = 200,
  }) {
    final now = DateTime.now();
    return RoadReport(
      userId: userId,
      latitude: latitude,
      longitude: longitude,
      locationLabel: locationLabel,
      locationAddress: locationAddress,
      segmentId: segmentId,
      routeId: routeId,
      type: type,
      severity: severity,
      comment: comment,
      imageUrls: const [],
      sensorData: null,
      source: 'user',
      status: 'pending',
      createdAt: now,
      expiresAt: now.add(validity),
      radiusMeters: radiusMeters,
    );
  }

  RoadReport buildReportFromMessage({
    required String? userId,
    required double latitude,
    required double longitude,
    String? locationLabel,
    String? locationAddress,
    String? segmentId,
    String? routeId,
    required String message,
  }) {
    return buildUserReport(
      userId: userId,
      latitude: latitude,
      longitude: longitude,
      locationLabel: locationLabel,
      locationAddress: locationAddress,
      segmentId: segmentId,
      routeId: routeId,
      type: inferType(message),
      severity: inferSeverity(message),
      comment: message,
    );
  }

  Future<String?> saveRoadReport(RoadReport report) async {
    try {
      final doc = await collection.add(report.toJson());
      await doc.update({'id': doc.id});
      notifyReportsChanged();
      return doc.id;
    } catch (error) {
      debugPrint('saveRoadReport failed: $error');
      return null;
    }
  }

  Future<List<RoadReport>> getRoadReportsForUser(
    String userId, {
    int limit = 5,
  }) async {
    try {
      final snapshot =
          await collection
              .where('userId', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
              .limit(limit)
              .get();

      return snapshot.docs
          .map((doc) => RoadReport.fromJson(doc.data()).copyWith(id: doc.id))
          .toList();
    } catch (error) {
      debugPrint('getRoadReportsForUser ordered query failed: $error');
      try {
        final snapshot =
            await collection
                .where('userId', isEqualTo: userId)
                .limit(limit)
                .get();
        final reports = _docsToReports(snapshot.docs);
        _sortNewestFirst(reports);
        return reports;
      } catch (fallbackError) {
        debugPrint('getRoadReportsForUser fallback failed: $fallbackError');
        return const [];
      }
    }
  }

  Future<List<RoadReport>> getActiveRoadReports({int limit = 100}) async {
    try {
      final snapshot =
          await collection
              .orderBy('createdAt', descending: true)
              .limit(limit)
              .get();

      return _docsToReports(
        snapshot.docs,
      ).where((report) => report.isActive).toList();
    } catch (error) {
      debugPrint('getActiveRoadReports ordered query failed: $error');
      try {
        final snapshot = await collection.limit(limit).get();
        final reports =
            _docsToReports(
              snapshot.docs,
            ).where((report) => report.isActive).toList();
        _sortNewestFirst(reports);
        return reports;
      } catch (fallbackError) {
        debugPrint('getActiveRoadReports fallback failed: $fallbackError');
        return const [];
      }
    }
  }

  Future<List<RoadReport>> getRecentRoadReports({int limit = 100}) async {
    try {
      final snapshot =
          await collection
              .orderBy('createdAt', descending: true)
              .limit(limit)
              .get();

      return _docsToReports(snapshot.docs);
    } catch (error) {
      debugPrint('getRecentRoadReports ordered query failed: $error');
      try {
        final snapshot = await collection.limit(limit).get();
        final reports = _docsToReports(snapshot.docs);
        _sortNewestFirst(reports);
        return reports;
      } catch (fallbackError) {
        debugPrint('getRecentRoadReports fallback failed: $fallbackError');
        return const [];
      }
    }
  }

  Future<bool> markReportHandled(String reportId) async {
    try {
      await collection.doc(reportId).update({'status': 'handled'});
      notifyReportsChanged();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> confirmReport({
    required String reportId,
    required String voterId,
  }) {
    return _voteReport(reportId: reportId, voterId: voterId, confirms: true);
  }

  Future<bool> refuteReport({
    required String reportId,
    required String voterId,
  }) {
    return _voteReport(reportId: reportId, voterId: voterId, confirms: false);
  }

  Future<bool> deleteReport(String reportId) async {
    try {
      await collection.doc(reportId).delete();
      notifyReportsChanged();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _voteReport({
    required String reportId,
    required String voterId,
    required bool confirms,
  }) async {
    try {
      final docRef = collection.doc(reportId);
      await collection.firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          return;
        }

        final data = snapshot.data() ?? <String, dynamic>{};
        final confirmedBy = _toStringSet(data['confirmedBy']);
        final refutedBy = _toStringSet(data['refutedBy']);

        if (confirms) {
          if (confirmedBy.contains(voterId)) {
            confirmedBy.remove(voterId);
          } else {
            confirmedBy.add(voterId);
            refutedBy.remove(voterId);
          }
        } else {
          if (refutedBy.contains(voterId)) {
            refutedBy.remove(voterId);
          } else {
            refutedBy.add(voterId);
            confirmedBy.remove(voterId);
          }
        }

        transaction.update(docRef, {
          'confirmedBy': confirmedBy.toList(),
          'refutedBy': refutedBy.toList(),
          'confirmationCount': confirmedBy.length,
          'refutationCount': refutedBy.length,
        });
      });
      notifyReportsChanged();
      return true;
    } catch (_) {
      return false;
    }
  }

  static void notifyReportsChanged() {
    refreshRevision.value++;
  }

  String inferType(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('accident')) {
      return 'accident';
    }
    if (normalized.contains('embouteillage') ||
        normalized.contains('bouchon') ||
        normalized.contains('trafic')) {
      return 'embouteillage';
    }
    if (normalized.contains('trou') || normalized.contains('nid')) {
      return 'trou';
    }
    if (normalized.contains('inond') || normalized.contains('eau')) {
      return 'inondation';
    }
    if (normalized.contains('danger')) {
      return 'danger';
    }
    return 'mauvaise_route';
  }

  String inferSeverity(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('grave') ||
        normalized.contains('dangereux') ||
        normalized.contains('bloque') ||
        normalized.contains('impossible')) {
      return 'eleve';
    }
    if (normalized.contains('leger') || normalized.contains('petit')) {
      return 'faible';
    }
    return 'moyen';
  }
}

List<RoadReport> _docsToReports(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
) {
  return docs
      .map((doc) => RoadReport.fromJson(doc.data()).copyWith(id: doc.id))
      .toList();
}

void _sortNewestFirst(List<RoadReport> reports) {
  reports.sort((a, b) {
    final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bDate.compareTo(aDate);
  });
}

Set<String> _toStringSet(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).toSet();
  }
  return <String>{};
}
