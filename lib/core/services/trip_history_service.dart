import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/route_result.dart';
import '../models/trip_history.dart';

class TripHistoryService {
  final CollectionReference<Map<String, dynamic>> collection;

  TripHistoryService({required this.collection});

  TripHistory buildTripHistory({
    required String originalMessage,
    required RouteResult routeResult,
  }) {
    return TripHistory(
      userId: routeResult.userId,
      originalMessage: originalMessage,
      originLabel: routeResult.startLabel,
      destinationLabel: routeResult.destinationLabel,
      originLat: routeResult.startLat,
      originLng: routeResult.startLng,
      destinationLat: routeResult.destinationLat,
      destinationLng: routeResult.destinationLng,
      distance: routeResult.distance,
      duration: routeResult.duration,
      segments: routeResult.segments,
      warnings: routeResult.warnings,
      createdAt: DateTime.now(),
    );
  }

  Future<String?> saveTripHistory(TripHistory tripHistory) async {
    try {
      final doc = await collection.add(tripHistory.toJson());
      return doc.id;
    } catch (_) {
      return null;
    }
  }

  Future<List<TripHistory>> getTripHistoryForUser(
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
          .map((doc) => TripHistory.fromJson(doc.data()).copyWith(id: doc.id))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
