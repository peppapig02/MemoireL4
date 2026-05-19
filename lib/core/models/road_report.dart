import 'package:cloud_firestore/cloud_firestore.dart';

class RoadReport {
  final String? id;
  final String? userId;
  final String? deviceId;
  final double latitude;
  final double longitude;
  final String? segmentId;
  final String? routeId;
  final String type;
  final String severity;
  final String? comment;
  final List<String> imageUrls;
  final Map<String, dynamic>? sensorData;
  final String source;
  final String status;
  final String? aiPrediction;
  final DateTime? createdAt;

  const RoadReport({
    this.id,
    this.userId,
    this.deviceId,
    required this.latitude,
    required this.longitude,
    this.segmentId,
    this.routeId,
    required this.type,
    required this.severity,
    this.comment,
    this.imageUrls = const [],
    this.sensorData,
    required this.source,
    required this.status,
    this.aiPrediction,
    this.createdAt,
  });

  factory RoadReport.fromJson(Map<String, dynamic> json) {
    return RoadReport(
      id: json['id'] as String?,
      userId: json['userId'] as String?,
      deviceId: json['deviceId'] as String?,
      latitude: _toDouble(json['latitude']) ?? 0,
      longitude: _toDouble(json['longitude']) ?? 0,
      segmentId: json['segmentId'] as String?,
      routeId: json['routeId'] as String?,
      type: (json['type'] ?? 'autre') as String,
      severity: (json['severity'] ?? 'moyen') as String,
      comment: json['comment'] as String?,
      imageUrls: _toStringList(json['imageUrls']),
      sensorData:
          json['sensorData'] is Map
              ? Map<String, dynamic>.from(json['sensorData'] as Map)
              : null,
      source: (json['source'] ?? 'user') as String,
      status: (json['status'] ?? 'pending') as String,
      aiPrediction: json['aiPrediction'] as String?,
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'deviceId': deviceId,
      'latitude': latitude,
      'longitude': longitude,
      'segmentId': segmentId,
      'routeId': routeId,
      'type': type,
      'severity': severity,
      'comment': comment,
      'imageUrls': imageUrls,
      'sensorData': sensorData,
      'source': source,
      'status': status,
      'aiPrediction': aiPrediction,
      'createdAt':
          createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  RoadReport copyWith({
    String? id,
    String? userId,
    String? deviceId,
    double? latitude,
    double? longitude,
    String? segmentId,
    String? routeId,
    String? type,
    String? severity,
    String? comment,
    List<String>? imageUrls,
    Map<String, dynamic>? sensorData,
    String? source,
    String? status,
    String? aiPrediction,
    DateTime? createdAt,
  }) {
    return RoadReport(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      segmentId: segmentId ?? this.segmentId,
      routeId: routeId ?? this.routeId,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      comment: comment ?? this.comment,
      imageUrls: imageUrls ?? this.imageUrls,
      sensorData: sensorData ?? this.sensorData,
      source: source ?? this.source,
      status: status ?? this.status,
      aiPrediction: aiPrediction ?? this.aiPrediction,
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

List<String> _toStringList(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList();
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
