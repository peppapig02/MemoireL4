import 'package:cloud_firestore/cloud_firestore.dart';

import 'route_segment.dart';

class RouteResult {
  final String? id;
  final String? userId;
  final double startLat;
  final double startLng;
  final double destinationLat;
  final double destinationLng;
  final String? startLabel;
  final String? destinationLabel;
  final double distance;
  final double duration;
  final List<Map<String, dynamic>> geometry;
  final List<RouteSegment> segments;
  final List<Map<String, dynamic>> warnings;
  final DateTime? createdAt;

  const RouteResult({
    this.id,
    this.userId,
    required this.startLat,
    required this.startLng,
    required this.destinationLat,
    required this.destinationLng,
    this.startLabel,
    this.destinationLabel,
    required this.distance,
    required this.duration,
    this.geometry = const [],
    this.segments = const [],
    this.warnings = const [],
    this.createdAt,
  });

  factory RouteResult.fromJson(Map<String, dynamic> json) {
    return RouteResult(
      id: json['id'] as String?,
      userId: json['userId'] as String?,
      startLat: _toDouble(json['startLat']) ?? 0,
      startLng: _toDouble(json['startLng']) ?? 0,
      destinationLat: _toDouble(json['destinationLat']) ?? 0,
      destinationLng: _toDouble(json['destinationLng']) ?? 0,
      startLabel: json['startLabel'] as String?,
      destinationLabel: json['destinationLabel'] as String?,
      distance: _toDouble(json['distance']) ?? 0,
      duration: _toDouble(json['duration']) ?? 0,
      geometry: _toMapList(json['geometry']),
      segments: _toRouteSegments(json['segments']),
      warnings: _toMapList(json['warnings']),
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'startLat': startLat,
      'startLng': startLng,
      'destinationLat': destinationLat,
      'destinationLng': destinationLng,
      'startLabel': startLabel,
      'destinationLabel': destinationLabel,
      'distance': distance,
      'duration': duration,
      'geometry': geometry,
      'segments': segments.map((segment) => segment.toJson()).toList(),
      'warnings': warnings,
      'createdAt':
          createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  RouteResult copyWith({
    String? id,
    String? userId,
    double? startLat,
    double? startLng,
    double? destinationLat,
    double? destinationLng,
    String? startLabel,
    String? destinationLabel,
    double? distance,
    double? duration,
    List<Map<String, dynamic>>? geometry,
    List<RouteSegment>? segments,
    List<Map<String, dynamic>>? warnings,
    DateTime? createdAt,
  }) {
    return RouteResult(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startLat: startLat ?? this.startLat,
      startLng: startLng ?? this.startLng,
      destinationLat: destinationLat ?? this.destinationLat,
      destinationLng: destinationLng ?? this.destinationLng,
      startLabel: startLabel ?? this.startLabel,
      destinationLabel: destinationLabel ?? this.destinationLabel,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      geometry: geometry ?? this.geometry,
      segments: segments ?? this.segments,
      warnings: warnings ?? this.warnings,
      createdAt: createdAt ?? this.createdAt,
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

List<Map<String, dynamic>> _toMapList(dynamic value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
  return const [];
}

List<RouteSegment> _toRouteSegments(dynamic value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((item) => RouteSegment.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
  return const [];
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  return null;
}
