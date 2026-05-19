import 'package:cloud_firestore/cloud_firestore.dart';

class RouteSegment {
  final String? id;
  final String? routeId;
  final String instruction;
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;
  final double distance;
  final double duration;
  final String? riskLevel;
  final List<String> relatedReports;

  const RouteSegment({
    this.id,
    this.routeId,
    required this.instruction,
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
    required this.distance,
    required this.duration,
    this.riskLevel,
    this.relatedReports = const [],
  });

  factory RouteSegment.fromJson(Map<String, dynamic> json) {
    return RouteSegment(
      id: json['id'] as String?,
      routeId: json['routeId'] as String?,
      instruction: (json['instruction'] ?? '') as String,
      startLat: _toDouble(json['startLat']) ?? 0,
      startLng: _toDouble(json['startLng']) ?? 0,
      endLat: _toDouble(json['endLat']) ?? 0,
      endLng: _toDouble(json['endLng']) ?? 0,
      distance: _toDouble(json['distance']) ?? 0,
      duration: _toDouble(json['duration']) ?? 0,
      riskLevel: json['riskLevel'] as String?,
      relatedReports: _toStringList(json['relatedReports']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'routeId': routeId,
      'instruction': instruction,
      'startLat': startLat,
      'startLng': startLng,
      'endLat': endLat,
      'endLng': endLng,
      'distance': distance,
      'duration': duration,
      'riskLevel': riskLevel,
      'relatedReports': relatedReports,
    };
  }

  RouteSegment copyWith({
    String? id,
    String? routeId,
    String? instruction,
    double? startLat,
    double? startLng,
    double? endLat,
    double? endLng,
    double? distance,
    double? duration,
    String? riskLevel,
    List<String>? relatedReports,
  }) {
    return RouteSegment(
      id: id ?? this.id,
      routeId: routeId ?? this.routeId,
      instruction: instruction ?? this.instruction,
      startLat: startLat ?? this.startLat,
      startLng: startLng ?? this.startLng,
      endLat: endLat ?? this.endLat,
      endLng: endLng ?? this.endLng,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      riskLevel: riskLevel ?? this.riskLevel,
      relatedReports: relatedReports ?? this.relatedReports,
    );
  }
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

List<String> _toStringList(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  return const [];
}
