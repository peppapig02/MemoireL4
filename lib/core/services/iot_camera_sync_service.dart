import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';

import '../models/road_report.dart';
import 'road_report_service.dart';

class IotCameraSyncResult {
  final int imported;
  final int skipped;
  final int failed;

  const IotCameraSyncResult({
    required this.imported,
    required this.skipped,
    required this.failed,
  });

  bool get hasChanges => imported > 0;
}

class IotCameraSyncService {
  final CollectionReference<Map<String, dynamic>> collection;
  final Dio dio;
  final String cameraBaseUrl;
  final String deviceId;

  IotCameraSyncService({
    required this.collection,
    Dio? dio,
    this.cameraBaseUrl = 'http://192.168.4.1',
    this.deviceId = 'esp32cam-001',
  }) : dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 8),
               receiveTimeout: const Duration(seconds: 10),
               responseType: ResponseType.plain,
             ),
           );

  Future<IotCameraSyncResult> syncEvents() async {
    final csvText = await _downloadEventsCsv();
    final events = _parseEventsCsv(csvText);

    var imported = 0;
    var skipped = 0;
    var failed = 0;

    for (final event in events) {
      try {
        if (!event.hasUsableGps) {
          skipped++;
          continue;
        }

        final exists = await _eventAlreadyImported(event.eventId);
        if (exists) {
          skipped++;
          continue;
        }

        await collection.add(_buildReport(event).toJson());
        imported++;
      } catch (_) {
        failed++;
      }
    }

    if (imported > 0) {
      RoadReportService.notifyReportsChanged();
    }

    return IotCameraSyncResult(
      imported: imported,
      skipped: skipped,
      failed: failed,
    );
  }

  Future<String> _downloadEventsCsv() async {
    final url = '$cameraBaseUrl/download?file=/events.csv';
    final response = await dio.get<String>(url);
    final data = response.data;
    if (data == null || data.trim().isEmpty) {
      throw StateError('events.csv est vide ou inaccessible.');
    }
    return data;
  }

  Future<bool> _eventAlreadyImported(String eventId) async {
    final snapshot =
        await collection
            .where('deviceId', isEqualTo: deviceId)
            .where('eventId', isEqualTo: eventId)
            .limit(1)
            .get();
    return snapshot.docs.isNotEmpty;
  }

  RoadReport _buildReport(_IotCameraEvent event) {
    final prediction = _predictLabel(event);
    final now = DateTime.now();

    return RoadReport(
      userId: null,
      deviceId: deviceId,
      eventId: event.eventId,
      latitude: event.latitude,
      longitude: event.longitude,
      locationLabel: 'Signalement IoT Wapi',
      type: 'mauvaise_route',
      severity: _severityFromPrediction(prediction),
      comment: 'Signalement automatique depuis ESP32-CAM : ${event.roadState}',
      imageUrls:
          event.photo.isEmpty || event.photo == 'CAPTURE_FAILED'
              ? const []
              : ['$cameraBaseUrl/download?file=${event.photo}'],
      sensorData: event.toSensorData(),
      source: 'iot_local_sync',
      status: 'pending',
      aiPrediction: prediction,
      createdAt: now,
      expiresAt: now.add(const Duration(hours: 48)),
      radiusMeters: 200,
    );
  }

  String _predictLabel(_IotCameraEvent event) {
    final state = event.roadState.toUpperCase();
    if (state.contains('CHOC_FORT') ||
        event.shock >= 0.75 ||
        event.totalG >= 1.75) {
      return 'tres mauvais';
    }
    if (state.contains('ROUTE_DEGRADEE') ||
        event.shock >= 0.35 ||
        event.totalG >= 1.35) {
      return 'mauvais';
    }
    if (event.shock >= 0.18 || event.totalG >= 1.18) {
      return 'moyen';
    }
    return 'bon';
  }

  String _severityFromPrediction(String prediction) {
    return switch (prediction) {
      'tres mauvais' => 'eleve',
      'mauvais' => 'moyen',
      _ => 'faible',
    };
  }

  List<_IotCameraEvent> _parseEventsCsv(String csvText) {
    final lines =
        csvText
            .split(RegExp(r'\r?\n'))
            .where((line) => line.trim().isNotEmpty)
            .toList();
    if (lines.length <= 1) {
      return const [];
    }

    final headers = _splitCsvLine(lines.first);
    final events = <_IotCameraEvent>[];

    for (final line in lines.skip(1)) {
      final values = _splitCsvLine(line);
      if (values.length < headers.length) {
        continue;
      }

      final row = <String, String>{};
      for (var index = 0; index < headers.length; index++) {
        row[headers[index]] = values[index];
      }

      events.add(_IotCameraEvent.fromCsv(row));
    }

    return events;
  }

  List<String> _splitCsvLine(String line) {
    final values = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    for (var index = 0; index < line.length; index++) {
      final char = line[index];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        values.add(buffer.toString().trim());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }

    values.add(buffer.toString().trim());
    return values;
  }
}

class _IotCameraEvent {
  final String eventId;
  final int millisValue;
  final String roadState;
  final double shock;
  final double totalG;
  final double ax;
  final double ay;
  final double az;
  final double pitch;
  final double roll;
  final bool gpsValid;
  final double latitude;
  final double longitude;
  final int gpsAge;
  final int satellites;
  final String photo;

  const _IotCameraEvent({
    required this.eventId,
    required this.millisValue,
    required this.roadState,
    required this.shock,
    required this.totalG,
    required this.ax,
    required this.ay,
    required this.az,
    required this.pitch,
    required this.roll,
    required this.gpsValid,
    required this.latitude,
    required this.longitude,
    required this.gpsAge,
    required this.satellites,
    required this.photo,
  });

  bool get hasUsableGps => gpsValid && latitude != 0 && longitude != 0;

  factory _IotCameraEvent.fromCsv(Map<String, String> row) {
    return _IotCameraEvent(
      eventId: row['event_id'] ?? '',
      millisValue: _toInt(row['millis']),
      roadState: row['road_state'] ?? 'UNKNOWN',
      shock: _toDouble(row['shock']),
      totalG: _toDouble(row['total_g']),
      ax: _toDouble(row['ax']),
      ay: _toDouble(row['ay']),
      az: _toDouble(row['az']),
      pitch: _toDouble(row['pitch']),
      roll: _toDouble(row['roll']),
      gpsValid: (row['gps_valid'] ?? '0') == '1',
      latitude: _toDouble(row['latitude']),
      longitude: _toDouble(row['longitude']),
      gpsAge: _toInt(row['gps_age_ms']),
      satellites: _toInt(row['satellites']),
      photo: row['photo'] ?? '',
    );
  }

  Map<String, dynamic> toSensorData() {
    return {
      'roadState': roadState,
      'shock': shock,
      'totalG': totalG,
      'ax': ax,
      'ay': ay,
      'az': az,
      'pitch': pitch,
      'roll': roll,
      'millis': millisValue,
      'gpsValid': gpsValid,
      'gpsAge': gpsAge,
      'satellites': satellites,
      'photo': photo,
    };
  }

  static double _toDouble(String? value) {
    return double.tryParse(value ?? '') ?? 0;
  }

  static int _toInt(String? value) {
    return int.tryParse(value ?? '') ?? 0;
  }
}
