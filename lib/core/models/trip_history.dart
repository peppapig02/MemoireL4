import 'package:cloud_firestore/cloud_firestore.dart';

import 'route_segment.dart';

class TripHistory {
  final String? id;
  final String? userId;
  final String originalMessage;
  final String? originLabel;
  final String? destinationLabel;
  final double originLat;
  final double originLng;
  final double destinationLat;
  final double destinationLng;
  final double distance;
  final double duration;
  final List<RouteSegment> segments;
  final List<Map<String, dynamic>> warnings;
  final DateTime? createdAt;

  const TripHistory({
    this.id,
    this.userId,
    required this.originalMessage,
    this.originLabel,
    this.destinationLabel,
    required this.originLat,
    required this.originLng,
    required this.destinationLat,
    required this.destinationLng,
    required this.distance,
    required this.duration,
    this.segments = const [],
    this.warnings = const [],
    this.createdAt,
  });

  factory TripHistory.fromJson(Map<String, dynamic> json) {
    return TripHistory(
      id: json['id'] as String?,
      userId: json['userId'] as String?,
      originalMessage: (json['originalMessage'] ?? '') as String,
      originLabel: json['originLabel'] as String?,
      destinationLabel: json['destinationLabel'] as String?,
      originLat: _toDouble(json['originLat']) ?? 0,
      originLng: _toDouble(json['originLng']) ?? 0,
      destinationLat: _toDouble(json['destinationLat']) ?? 0,
      destinationLng: _toDouble(json['destinationLng']) ?? 0,
      distance: _toDouble(json['distance']) ?? 0,
      duration: _toDouble(json['duration']) ?? 0,
      segments: _toRouteSegments(json['segments']),
      warnings: _toMapList(json['warnings']),
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'originalMessage': originalMessage,
      'originLabel': originLabel,
      'destinationLabel': destinationLabel,
      'originLat': originLat,
      'originLng': originLng,
      'destinationLat': destinationLat,
      'destinationLng': destinationLng,
      'distance': distance,
      'duration': duration,
      'segments': segments.map((segment) => segment.toJson()).toList(),
      'warnings': warnings,
      'createdAt':
          createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  TripHistory copyWith({
    String? id,
    String? userId,
    String? originalMessage,
    String? originLabel,
    String? destinationLabel,
    double? originLat,
    double? originLng,
    double? destinationLat,
    double? destinationLng,
    double? distance,
    double? duration,
    List<RouteSegment>? segments,
    List<Map<String, dynamic>>? warnings,
    DateTime? createdAt,
  }) {
    return TripHistory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      originalMessage: originalMessage ?? this.originalMessage,
      originLabel: originLabel ?? this.originLabel,
      destinationLabel: destinationLabel ?? this.destinationLabel,
      originLat: originLat ?? this.originLat,
      originLng: originLng ?? this.originLng,
      destinationLat: destinationLat ?? this.destinationLat,
      destinationLng: destinationLng ?? this.destinationLng,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
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
