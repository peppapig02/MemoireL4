import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRouteRequest {
  final String? id;
  final String? userId;
  final String originalMessage;
  final String intent;
  final String? startText;
  final String? destinationText;
  final double? startLat;
  final double? startLng;
  final double? destinationLat;
  final double? destinationLng;
  final String? category;
  final int? resultCount;
  final DateTime? createdAt;

  const ChatRouteRequest({
    this.id,
    this.userId,
    required this.originalMessage,
    required this.intent,
    this.startText,
    this.destinationText,
    this.startLat,
    this.startLng,
    this.destinationLat,
    this.destinationLng,
    this.category,
    this.resultCount,
    this.createdAt,
  });

  factory ChatRouteRequest.fromJson(Map<String, dynamic> json) {
    return ChatRouteRequest(
      id: json['id'] as String?,
      userId: json['userId'] as String?,
      originalMessage: (json['originalMessage'] ?? '') as String,
      intent: (json['intent'] ?? 'unknown') as String,
      startText: json['startText'] as String?,
      destinationText: json['destinationText'] as String?,
      startLat: _toDouble(json['startLat']),
      startLng: _toDouble(json['startLng']),
      destinationLat: _toDouble(json['destinationLat']),
      destinationLng: _toDouble(json['destinationLng']),
      category: json['category'] as String?,
      resultCount: _toInt(json['resultCount']),
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'originalMessage': originalMessage,
      'intent': intent,
      'startText': startText,
      'destinationText': destinationText,
      'startLat': startLat,
      'startLng': startLng,
      'destinationLat': destinationLat,
      'destinationLng': destinationLng,
      'category': category,
      'resultCount': resultCount,
      'createdAt':
          createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  ChatRouteRequest copyWith({
    String? id,
    String? userId,
    String? originalMessage,
    String? intent,
    String? startText,
    String? destinationText,
    double? startLat,
    double? startLng,
    double? destinationLat,
    double? destinationLng,
    String? category,
    int? resultCount,
    DateTime? createdAt,
  }) {
    return ChatRouteRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      originalMessage: originalMessage ?? this.originalMessage,
      intent: intent ?? this.intent,
      startText: startText ?? this.startText,
      destinationText: destinationText ?? this.destinationText,
      startLat: startLat ?? this.startLat,
      startLng: startLng ?? this.startLng,
      destinationLat: destinationLat ?? this.destinationLat,
      destinationLng: destinationLng ?? this.destinationLng,
      category: category ?? this.category,
      resultCount: resultCount ?? this.resultCount,
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

int? _toInt(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value.toString());
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
