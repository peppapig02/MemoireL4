import 'dart:async';
import 'dart:math' as math;

import 'package:botroad/core/config/app_secrets.dart';
import 'package:botroad/core/models/route_result.dart';
import 'package:botroad/core/services/road_report_service.dart';
import 'package:botroad/core/services/network_status_service.dart';
import 'package:botroad/core/services/nearby_places_service.dart';
import 'package:botroad/core/services/route_risk_service.dart';
import 'package:botroad/core/services/routing_service.dart';
import 'package:botroad/models/routes_model.dart';
import 'package:botroad/ui/screens/main/main_nav_controller.dart';
import 'package:botroad/ui/widgets/network_status_banner.dart';
import 'package:botroad/utils/Setting.dart';
import 'package:botroad/utils/const/colors.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const String _botRoadMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#121218"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#B6B6C5"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#0B0B0F"}]},
  {"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"color":"#20202A"}]},
  {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#0B0B0F"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#181820"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#808095"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#3A3A4A"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#20202A"}]},
  {"featureType":"road","elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3A3A4A"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#20202A"}]},
  {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#181820"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#101027"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#808095"}]}
]
''';

class Iteneraire extends StatefulWidget {
  final RoutesModel? route;
  final bool embedded;

  const Iteneraire({super.key, this.route, this.embedded = false});

  @override
  State<Iteneraire> createState() => _IteneraireState();
}

class _IteneraireState extends State<Iteneraire> {
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  LatLngBounds? bounds;
  bool isNavigating = false;
  String? routeErrorMessage;
  late final NetworkStatusService networkStatusService;
  late final RoadReportService roadReportService;
  late final NearbyPlacesService nearbyPlacesService;
  late final RouteRiskService routeRiskService;
  late final RoutingService routingService;
  Position? currentPosition;
  Timer? navigationTimer;
  bool isReporting = false;
  bool isLoadingAlternative = false;
  bool isLoadingRouteMode = false;
  bool isMapInitializing = true;
  bool _trafficEnabled = false;
  bool _alertsEnabled = false;
  late final FlutterTts _tts;
  int _navSegmentIndex = 0;
  int? _lastAnnounceBucket;
  bool _ttsReady = false;

  @override
  void initState() {
    super.initState();
    networkStatusService =
        Get.isRegistered<NetworkStatusService>()
            ? Get.find<NetworkStatusService>()
            : Get.put(NetworkStatusService(), permanent: true);
    roadReportService = RoadReportService(collection: Setting.fRoadReports);
    nearbyPlacesService = NearbyPlacesService(
      apiKey: AppSecrets.googleMapsApiKey,
    );
    routeRiskService = RouteRiskService(collection: Setting.fRoadReports);
    routingService = RoutingService(googleApiKey: AppSecrets.googleMapsApiKey);
    _tts = FlutterTts();
    _configureTts();
    _initializeMap();
  }

  @override
  void dispose() {
    navigationTimer?.cancel();
    _tts.stop();
    super.dispose();
  }

  Future<void> _configureTts() async {
    try {
      await _tts.setLanguage('fr-FR');
      await _tts.setSpeechRate(0.48);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      _ttsReady = true;
    } catch (_) {
      _ttsReady = false;
    }
  }

  Future<void> _speak(String message) async {
    if (!_ttsReady) return;
    final text = message.trim();
    if (text.isEmpty) return;
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  List<Map<String, dynamic>> _routeSegmentsNormalized() {
    final segments = widget.route?.segments;
    if (segments == null) return const [];
    return segments
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  String _segmentInstruction(Map<String, dynamic> segment) {
    final raw = segment['instruction']?.toString().trim();
    if (raw == null || raw.isEmpty) {
      return 'Continuez tout droit';
    }
    return raw;
  }

  double? _segmentEndDistanceMeters(
    Position position,
    Map<String, dynamic> segment,
  ) {
    final endLat = _toDouble(segment['endLat']);
    final endLng = _toDouble(segment['endLng']);
    if (endLat == null || endLng == null) return null;
    return Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      endLat,
      endLng,
    );
  }

  int? _closestUpcomingSegmentIndex(Position position) {
    final segments = _routeSegmentsNormalized();
    if (segments.isEmpty) return null;
    final startIndex = _navSegmentIndex.clamp(0, segments.length - 1);
    var bestIndex = startIndex;
    var bestDist = double.infinity;
    for (var i = startIndex; i < segments.length; i++) {
      final d = _segmentEndDistanceMeters(position, segments[i]);
      if (d == null) continue;
      if (d < bestDist) {
        bestDist = d;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  int? _announceBucketForMeters(double meters) {
    if (meters <= 0) return null;
    if (meters <= 60) return 50;
    if (meters <= 120) return 100;
    if (meters <= 230) return 200;
    if (meters <= 360) return 300;
    return null;
  }

  Future<void> _maybeSpeakNextInstruction(Position position) async {
    final segments = _routeSegmentsNormalized();
    if (segments.isEmpty || !isNavigating) return;

    final idx = _closestUpcomingSegmentIndex(position);
    if (idx == null) return;
    _navSegmentIndex = idx;

    final distanceMeters = _segmentEndDistanceMeters(position, segments[idx]);
    if (distanceMeters == null) return;

    if (distanceMeters < 25 && idx + 1 < segments.length) {
      _navSegmentIndex = idx + 1;
      _lastAnnounceBucket = null;
      return;
    }

    final bucket = _announceBucketForMeters(distanceMeters);
    if (bucket == null || bucket == _lastAnnounceBucket) return;
    _lastAnnounceBucket = bucket;

    await _speak('Dans $bucket mètres, ${_segmentInstruction(segments[idx])}');
  }

  Future<void> _initializeMap() async {
    if (widget.route?.points == null || widget.route!.points!.trim().isEmpty) {
      _finishMapInitializationWithError('itinerary_route_unavailable'.tr);
      return;
    }

    try {
      var points = _parseRoutePoints(widget.route!.points);

      if (points.length < 2) {
        _finishMapInitializationWithError('itinerary_route_unavailable'.tr);
        return;
      }

      markers.clear();
      polylines.clear();

      if (points.length <= 2 || widget.route?.segments?.isEmpty != false) {
        final detailedRoute = await routingService.calculateRoute(
          userId: Setting.userCtrl.user.value.key,
          startLat: points.first.latitude,
          startLng: points.first.longitude,
          destinationLat: points.last.latitude,
          destinationLng: points.last.longitude,
        );

        final detailedPoints =
            detailedRoute?.geometry
                .map(
                  (point) => LatLng(
                    _toDouble(point['latitude']) ?? 0,
                    _toDouble(point['longitude']) ?? 0,
                  ),
                )
                .where((point) => point.latitude != 0 || point.longitude != 0)
                .toList() ??
            const <LatLng>[];

        if (detailedRoute != null && detailedPoints.length >= 2) {
          if (detailedPoints.length > points.length) {
            points = detailedPoints;
          }
          widget.route!
            ..points = points
                .map((point) => '${point.latitude},${point.longitude}')
                .join('|')
            ..segments =
                detailedRoute.segments
                    .map((segment) => segment.toJson())
                    .toList()
            ..warnings = detailedRoute.warnings
            ..risk_score = detailedRoute.riskScore;

          if (widget.route!.key != null) {
            await Setting.routesCtrl.updateRoutes(
              key: widget.route!.key!,
              map: {
                'points': widget.route!.points,
                'segments': widget.route!.segments,
                'warnings': widget.route!.warnings,
                'risk_score': widget.route!.risk_score,
              },
            );
          }
        }
      }

      markers.add(
        Marker(
          markerId: const MarkerId('depart'),
          position: points.first,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(title: 'itinerary_depart'.tr),
        ),
      );

      markers.add(
        Marker(
          markerId: const MarkerId('arrivee'),
          position: points.last,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: 'itinerary_arrival'.tr),
        ),
      );

      if (widget.route?.waypoints != null) {
        for (var i = 0; i < widget.route!.waypoints!.length; i++) {
          final waypoint = widget.route!.waypoints![i];
          markers.add(
            Marker(
              markerId: MarkerId('etape_$i'),
              position: LatLng(
                waypoint['latitude'] as double,
                waypoint['longitude'] as double,
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueBlue,
              ),
              infoWindow: InfoWindow(
                title: 'itinerary_step'.trParams({'index': '${i + 1}'}),
                snippet: waypoint['name'] as String?,
              ),
            ),
          );
        }
      }

      if (widget.route?.warnings != null) {
        for (var i = 0; i < widget.route!.warnings!.length; i++) {
          final warning = widget.route!.warnings![i];
          final lat = _toDouble(warning['latitude']);
          final lng = _toDouble(warning['longitude']);
          if (lat == null || lng == null) {
            continue;
          }

          markers.add(
            Marker(
              markerId: MarkerId('warning_$i'),
              position: LatLng(lat, lng),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange,
              ),
              infoWindow: InfoWindow(
                title: 'Alerte route',
                snippet:
                    '${warning['type'] ?? 'anomalie'} - ${warning['severity'] ?? 'moyen'}',
              ),
            ),
          );
        }
      }

      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: points,
          color: AppColors.primary,
          width: 6,
          jointType: JointType.round,
          geodesic: true,
        ),
      );

      if (widget.route?.segments != null) {
        for (var i = 0; i < widget.route!.segments!.length; i++) {
          final segment = widget.route!.segments![i];
          final riskLevel = segment['riskLevel']?.toString();
          if (riskLevel == null ||
              riskLevel == 'unknown' ||
              riskLevel == 'low') {
            continue;
          }

          final startLat = _toDouble(segment['startLat']);
          final startLng = _toDouble(segment['startLng']);
          final endLat = _toDouble(segment['endLat']);
          final endLng = _toDouble(segment['endLng']);
          if (startLat == null ||
              startLng == null ||
              endLat == null ||
              endLng == null) {
            continue;
          }

          polylines.add(
            Polyline(
              polylineId: PolylineId('risk_segment_$i'),
              points: [LatLng(startLat, startLng), LatLng(endLat, endLng)],
              color: riskLevel == 'high' ? AppColors.error : AppColors.warning,
              width: 7,
              jointType: JointType.round,
            ),
          );
        }
      }

      bounds = LatLngBounds(
        southwest: LatLng(
          points.map((p) => p.latitude).reduce((a, b) => a < b ? a : b),
          points.map((p) => p.longitude).reduce((a, b) => a < b ? a : b),
        ),
        northeast: LatLng(
          points.map((p) => p.latitude).reduce((a, b) => a > b ? a : b),
          points.map((p) => p.longitude).reduce((a, b) => a > b ? a : b),
        ),
      );
      networkStatusService.markOnline();
    } catch (e) {
      routeErrorMessage = 'itinerary_route_unavailable'.tr;
      networkStatusService.markOffline();
      printDebug('Erreur lors de l initialisation de la carte: $e');
    } finally {
      isMapInitializing = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  List<LatLng> _parseRoutePoints(String? routePoints) {
    if (routePoints == null || routePoints.trim().isEmpty) {
      return const [];
    }

    final points = <LatLng>[];
    for (final point in routePoints.split('|')) {
      final coords = point.split(',');
      if (coords.length < 2) {
        continue;
      }

      final latitude = double.tryParse(coords[0].trim());
      final longitude = double.tryParse(coords[1].trim());
      if (latitude == null || longitude == null) {
        continue;
      }

      points.add(LatLng(latitude, longitude));
    }
    return points;
  }

  void _finishMapInitializationWithError(String message) {
    routeErrorMessage = message;
    networkStatusService.markOffline();
    isMapInitializing = false;
    if (mounted) {
      setState(() {});
    }
  }

  void _recenterMap() {
    if (mapController != null && bounds != null) {
      mapController!
          .animateCamera(CameraUpdate.newLatLngBounds(bounds!, 50))
          .catchError((error) {
            networkStatusService.markOffline();
            Setting.showMessage('login_error'.tr, 'itinerary_map_error'.tr);
            printDebug('Erreur lors du recentrage de la carte: $error');
          });
    }
  }

  void _startNavigation() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Setting.showMessage(
          'login_error'.tr,
          'itinerary_location_permission_error'.tr,
        );
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      Setting.showMessage(
        'login_error'.tr,
        'itinerary_location_permission_error'.tr,
      );
      return;
    }

    setState(() {
      isNavigating = true;
      _navSegmentIndex = 0;
      _lastAnnounceBucket = null;
    });

    await _speak('Navigation démarrée.');

    navigationTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );

        setState(() {
          currentPosition = position;
          mapController?.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(position.latitude, position.longitude),
            ),
          );
        });
        networkStatusService.markOnline();
        await _maybeSpeakNextInstruction(position);

        if (widget.route?.points != null) {
          final points = widget.route!.points!.split('|');
          final destination = points.last.split(',');
          final destLat = double.parse(destination[0]);
          final destLng = double.parse(destination[1]);

          final distance = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            destLat,
            destLng,
          );

          if (distance < 100) {
            navigationTimer?.cancel();
            setState(() {
              isNavigating = false;
            });
            await _speak('Vous êtes arrivé à destination.');
            Setting.showMessage(
              'itinerary_arrived_title'.tr,
              'itinerary_arrived_message'.tr,
            );
          }
        }
      } catch (e) {
        final normalized = e.toString().toLowerCase();
        final message =
            normalized.contains('unable to resolve host') ||
                    normalized.contains('socketexception') ||
                    normalized.contains('ioexception')
                ? 'itinerary_navigation_network_error'.tr
                : 'itinerary_location_permission_error'.tr;
        if (normalized.contains('unable to resolve host') ||
            normalized.contains('socketexception') ||
            normalized.contains('ioexception')) {
          networkStatusService.markOffline();
        }
        Setting.showMessage('login_error'.tr, message);
        navigationTimer?.cancel();
        setState(() {
          isNavigating = false;
        });
        printDebug('Erreur lors de la mise a jour de la position: $e');
      }
    });
  }

  void _stopNavigation() {
    navigationTimer?.cancel();
    setState(() {
      isNavigating = false;
    });
    _tts.stop();
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

  double _toRadians(double degree) {
    return degree * (math.pi / 180);
  }

  Future<Position?> _getAllowedCurrentPosition() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      Setting.showMessage(
        'login_error'.tr,
        'itinerary_location_permission_error'.tr,
      );
      return null;
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Map<String, dynamic>? _nearestSegment(double latitude, double longitude) {
    final segments = widget.route?.segments ?? const [];
    if (segments.isEmpty) {
      return null;
    }

    Map<String, dynamic>? nearestSegment;
    var nearestDistance = double.infinity;
    for (final segment in segments) {
      final startLat = _toDouble(segment['startLat']);
      final startLng = _toDouble(segment['startLng']);
      final endLat = _toDouble(segment['endLat']);
      final endLng = _toDouble(segment['endLng']);
      if (startLat == null ||
          startLng == null ||
          endLat == null ||
          endLng == null) {
        continue;
      }

      final distance = _distancePointToSegmentKm(
        latitude,
        longitude,
        startLat,
        startLng,
        endLat,
        endLng,
      );
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestSegment = Map<String, dynamic>.from(segment);
      }
    }

    return nearestSegment;
  }

  Future<void> _showReportSheet() async {
    const types = <String, String>{
      'mauvaise_route': 'Route deconseillee',
      'trou': 'Trou / route abimee',
      'accident': 'Accident',
      'embouteillage': 'Embouteillage',
      'inondation': 'Inondation',
      'danger': 'Danger',
    };
    const severities = <String, String>{
      'faible': 'Faible',
      'moyen': 'Moyen',
      'eleve': 'Eleve',
    };

    var selectedType = 'mauvaise_route';
    var selectedSeverity = 'moyen';
    final commentController = TextEditingController();

    final result = await Get.bottomSheet<Map<String, String?>>(
      StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Signaler une anomalie',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Type de probleme',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        types.entries
                            .map(
                              (entry) => DropdownMenuItem(
                                value: entry.key,
                                child: Text(entry.value),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setSheetState(() => selectedType = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedSeverity,
                    decoration: const InputDecoration(
                      labelText: 'Gravite',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        severities.entries
                            .map(
                              (entry) => DropdownMenuItem(
                                value: entry.key,
                                child: Text(entry.value),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setSheetState(() => selectedSeverity = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: commentController,
                    minLines: 2,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Commentaire optionnel',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.report_problem_outlined),
                      label: const Text('Envoyer le signalement'),
                      onPressed:
                          isReporting
                              ? null
                              : () {
                                final type = selectedType;
                                final severity = selectedSeverity;
                                final comment = commentController.text.trim();
                                Navigator.of(context).pop({
                                  'type': type,
                                  'severity': severity,
                                  'comment': comment,
                                });
                              },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    commentController.dispose();

    if (result == null || !mounted) {
      return;
    }

    await _submitRoadReport(
      type: result['type'] ?? 'mauvaise_route',
      severity: result['severity'] ?? 'moyen',
      comment: result['comment'],
    );
  }

  Future<void> _submitRoadReport({
    required String type,
    required String severity,
    String? comment,
  }) async {
    if (isReporting) {
      return;
    }

    if (!mounted) return;

    setState(() {
      isReporting = true;
    });

    try {
      final position = currentPosition ?? await _getAllowedCurrentPosition();
      if (position == null) {
        return;
      }
      if (!mounted) {
        return;
      }

      final locationReference = await nearbyPlacesService.findNearestReference(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      final preciseAddress =
          locationReference?.address ??
          await nearbyPlacesService.reverseGeocodeAddress(
            latitude: position.latitude,
            longitude: position.longitude,
          );
      if (!mounted) {
        return;
      }

      final nearestSegment = _nearestSegment(
        position.latitude,
        position.longitude,
      );
      final segmentInstruction =
          nearestSegment?['instruction']?.toString().trim();
      final report = roadReportService.buildUserReport(
        userId: Setting.userCtrl.user.value.key,
        latitude: position.latitude,
        longitude: position.longitude,
        locationLabel: locationReference?.name,
        locationAddress:
            preciseAddress ??
            (segmentInstruction?.isNotEmpty == true
                ? 'Etape: $segmentInstruction'
                : null),
        segmentId: nearestSegment?['id']?.toString(),
        routeId: widget.route?.key,
        type: type,
        severity: severity,
        comment: comment?.trim().isNotEmpty == true ? comment : null,
      );

      final reportId = await roadReportService.saveRoadReport(report);
      if (!mounted) {
        return;
      }
      if (reportId == null) {
        Setting.showMessage(
          'login_error'.tr,
          'Le signalement n a pas pu etre enregistre.',
          Colors.red,
        );
        return;
      }

      setState(() {
        markers.add(
          Marker(
            markerId: MarkerId('my_report_$reportId'),
            position: LatLng(position.latitude, position.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange,
            ),
            infoWindow: InfoWindow(title: 'Signalement envoye', snippet: type),
          ),
        );
      });

      Setting.showMessage(
        'login_verification'.tr,
        'Signalement enregistre pour 48h. Retrouvez-le dans Alertes route.',
        Colors.green,
      );
      if (widget.embedded) {
        switchMainTab(2);
      } else {
        Get.back();
        switchMainTab(2);
      }
    } finally {
      if (mounted) {
        setState(() {
          isReporting = false;
        });
      }
    }
  }

  Future<void> _showSaferAlternative() async {
    await _showRouteForMode('alternative');
  }

  void _showRouteModeSheet() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choisir le mode d itineraire',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _RouteModeOption(
                icon: Icons.flash_on_outlined,
                title: 'Rapide',
                description: 'Priorite a la duree du trajet.',
                onTap: () {
                  Get.back();
                  _showRouteForMode('fast');
                },
              ),
              _RouteModeOption(
                icon: Icons.verified_user_outlined,
                title: 'Sur',
                description: 'Evite au maximum les alertes et zones a risque.',
                onTap: () {
                  Get.back();
                  _showRouteForMode('safe');
                },
              ),
              _RouteModeOption(
                icon: Icons.balance_outlined,
                title: 'Equilibre',
                description: 'Compromis entre securite, distance et duree.',
                onTap: () {
                  Get.back();
                  _showRouteForMode('balanced');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showRouteForMode(String mode) async {
    if (isLoadingAlternative || widget.route?.points == null) {
      return;
    }

    final routePoints = widget.route!.points!.split('|');
    if (routePoints.length < 2) {
      return;
    }

    setState(() {
      isLoadingAlternative = true;
      isLoadingRouteMode = true;
    });

    try {
      final start = routePoints.first.split(',');
      final end = routePoints.last.split(',');
      final alternatives = await routingService.calculateRoutes(
        userId: Setting.userCtrl.user.value.key,
        startLat: double.parse(start[0]),
        startLng: double.parse(start[1]),
        destinationLat: double.parse(end[0]),
        destinationLng: double.parse(end[1]),
        startLabel: 'position actuelle',
        destinationLabel: 'destination',
        alternatives: true,
      );

      if (alternatives.isEmpty) {
        Setting.showMessage(
          'login_info'.tr,
          'Aucun itineraire alternatif disponible pour le moment.',
        );
        return;
      }

      final checked = await routeRiskService.attachWarningsToRoutes(
        alternatives,
      );
      if (mode == 'alternative' && !_hasDifferentRoute(checked)) {
        Setting.showMessage(
          'login_info'.tr,
          'Aucun itineraire alternatif different disponible pour le moment.',
        );
        return;
      }

      final best =
          mode == 'alternative'
              ? _chooseDifferentRoute(checked)
              : routeRiskService.chooseBestRoute(checked, mode);
      final route = _routeResultToModel(best, mode);
      Setting.routesCtrl.routes.value = route;
      final key = await Setting.routesCtrl.addRoutes();
      if (key != null) {
        route.key = key;
      }

      Setting.showMessage(
        'login_verification'.tr,
        'Itineraire ${_routeModeLabel(mode).toLowerCase()} selectionne.',
        Colors.green,
      );
      await _applyRoute(route);
    } finally {
      if (mounted) {
        setState(() {
          isLoadingAlternative = false;
          isLoadingRouteMode = false;
        });
      }
    }
  }

  Future<void> _applyRoute(RoutesModel route) async {
    widget.route!
      ..key = route.key
      ..nom = route.nom
      ..points = route.points
      ..waypoints = route.waypoints
      ..warnings = route.warnings
      ..segments = route.segments
      ..mode = route.mode
      ..risk_score = route.risk_score
      ..date_create = route.date_create;

    setState(() {
      markers.clear();
      polylines.clear();
      bounds = null;
      routeErrorMessage = null;
      isMapInitializing = true;
    });

    await _initializeMap();
    WidgetsBinding.instance.addPostFrameCallback((_) => _recenterMap());
  }

  String _routeModeLabel(String mode) {
    return switch (mode) {
      'safe' => 'Sur',
      'balanced' => 'Equilibre',
      'alternative' => 'Alternative',
      _ => 'Rapide',
    };
  }

  RouteResult _chooseDifferentRoute(List<RouteResult> routes) {
    if (routes.isEmpty) {
      throw ArgumentError('routes must not be empty');
    }

    final currentSignature = _routeSignatureFromPoints(widget.route?.points);
    final ranked =
        routes.toList()..sort((a, b) => a.duration.compareTo(b.duration));

    for (final route in ranked) {
      final signature = _routeSignatureFromGeometry(route.geometry);
      if (signature != currentSignature) {
        return route.copyWith(mode: 'alternative');
      }
    }

    return ranked.first.copyWith(mode: 'alternative');
  }

  bool _hasDifferentRoute(List<RouteResult> routes) {
    final currentSignature = _routeSignatureFromPoints(widget.route?.points);
    return routes.any(
      (route) =>
          _routeSignatureFromGeometry(route.geometry) != currentSignature,
    );
  }

  String _routeSignatureFromPoints(String? points) {
    final parsed = _parseRoutePoints(points);
    if (parsed.isEmpty) {
      return '';
    }

    final step = math.max(1, parsed.length ~/ 8);
    return [
      for (var i = 0; i < parsed.length; i += step)
        '${parsed[i].latitude.toStringAsFixed(4)},${parsed[i].longitude.toStringAsFixed(4)}',
    ].join('|');
  }

  String _routeSignatureFromGeometry(List<Map<String, dynamic>> geometry) {
    if (geometry.isEmpty) {
      return '';
    }

    final step = math.max(1, geometry.length ~/ 8);
    return [
      for (var i = 0; i < geometry.length; i += step)
        '${_toDouble(geometry[i]['latitude'])?.toStringAsFixed(4)},${_toDouble(geometry[i]['longitude'])?.toStringAsFixed(4)}',
    ].join('|');
  }

  RoutesModel _routeResultToModel(RouteResult routeResult, String mode) {
    final points = routeResult.geometry
        .map((point) => '${point['latitude']},${point['longitude']}')
        .join('|');

    return RoutesModel(
      id_user: routeResult.userId,
      nom:
          'Itineraire ${_routeModeLabel(mode).toLowerCase()} vers ${routeResult.destinationLabel ?? 'destination'}',
      points: points,
      waypoints: const [],
      warnings: routeResult.warnings,
      segments:
          routeResult.segments.map((segment) => segment.toJson()).toList(),
      mode: mode,
      risk_score: routeResult.riskScore,
      date_create: DateTime.now().toString(),
    );
  }

  double _distancePointToSegmentKm(
    double pointLat,
    double pointLng,
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    const earthRadiusKm = 6371.0;
    final latReference = _toRadians((pointLat + startLat + endLat) / 3);

    final px = _toRadians(pointLng) * math.cos(latReference) * earthRadiusKm;
    final py = _toRadians(pointLat) * earthRadiusKm;
    final sx = _toRadians(startLng) * math.cos(latReference) * earthRadiusKm;
    final sy = _toRadians(startLat) * earthRadiusKm;
    final ex = _toRadians(endLng) * math.cos(latReference) * earthRadiusKm;
    final ey = _toRadians(endLat) * earthRadiusKm;

    final dx = ex - sx;
    final dy = ey - sy;
    if (dx == 0 && dy == 0) {
      return Geolocator.distanceBetween(
            pointLat,
            pointLng,
            startLat,
            startLng,
          ) /
          1000;
    }

    final t = (((px - sx) * dx) + ((py - sy) * dy)) / ((dx * dx) + (dy * dy));
    final clampedT = t.clamp(0.0, 1.0);
    final closestX = sx + (clampedT * dx);
    final closestY = sy + (clampedT * dy);
    final xDistance = px - closestX;
    final yDistance = py - closestY;
    return math.sqrt((xDistance * xDistance) + (yDistance * yDistance));
  }

  double _mapControlsTopInset(BuildContext context) {
    if (!widget.embedded) return 16;
    return MediaQuery.of(context).padding.top + 84;
  }

  void _openFullscreenMap() {
    Get.to(() => Iteneraire(route: widget.route, embedded: false));
  }

  void _toggleTraffic() {
    setState(() => _trafficEnabled = !_trafficEnabled);
    Setting.showMessage(
      'Trafic',
      _trafficEnabled
          ? 'Couche des embouteillages activee.'
          : 'Couche des embouteillages masquee.',
    );
  }

  Future<void> _toggleAlerts() async {
    final enabled = !_alertsEnabled;
    if (!enabled) {
      setState(() {
        _alertsEnabled = false;
        markers.removeWhere(
          (marker) => marker.markerId.value.startsWith('global_alert_'),
        );
      });
      return;
    }

    final reports = await roadReportService.getActiveRoadReports(limit: 100);
    if (!mounted) return;
    setState(() {
      _alertsEnabled = true;
      markers.removeWhere(
        (marker) => marker.markerId.value.startsWith('global_alert_'),
      );
      for (final report in reports) {
        if (report.latitude == 0 || report.longitude == 0) continue;
        markers.add(
          Marker(
            markerId: MarkerId(
              'global_alert_${report.id ?? '${report.latitude}_${report.longitude}'}',
            ),
            position: LatLng(report.latitude, report.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange,
            ),
            infoWindow: InfoWindow(
              title: _reportTypeLabel(report.type),
              snippet:
                  report.locationAddress ??
                  report.locationLabel ??
                  'Signalement actif',
            ),
          ),
        );
      }
    });
  }

  String _reportTypeLabel(String type) {
    return switch (type) {
      'embouteillage' => 'Embouteillage',
      'accident' => 'Accident',
      'trou' => 'Route abimee',
      'inondation' => 'Inondation',
      'danger' => 'Danger',
      _ => 'Route deconseillee',
    };
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final controlsTop = _mapControlsTopInset(context);
    printDebug('route name : ${widget.route?.nom}');

    var center = const LatLng(-4.322447, 15.307045);
    if (bounds != null) {
      center = LatLng(
        (bounds!.northeast.latitude + bounds!.southwest.latitude) / 2,
        (bounds!.northeast.longitude + bounds!.southwest.longitude) / 2,
      );
    }

    final body =
        isMapInitializing
            ? const Column(
              children: [
                NetworkStatusBanner(),
                Expanded(child: Center(child: CircularProgressIndicator())),
              ],
            )
            : routeErrorMessage != null
            ? Column(
              children: [
                const NetworkStatusBanner(),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        routeErrorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            )
            : Column(
              children: [
                if (!widget.embedded) const NetworkStatusBanner(),
                Expanded(
                  child: SizedBox(
                    height: height,
                    width: width,
                    child: Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: center,
                            zoom: 12,
                          ),
                          style: _botRoadMapStyle,
                          onMapCreated: (controller) {
                            mapController = controller;
                            if (bounds != null) {
                              controller
                                  .animateCamera(
                                    CameraUpdate.newLatLngBounds(bounds!, 50),
                                  )
                                  .then((_) {
                                    networkStatusService.markOnline();
                                  })
                                  .catchError((error) {
                                    networkStatusService.markOffline();
                                    Setting.showMessage(
                                      'login_error'.tr,
                                      'itinerary_map_error'.tr,
                                    );
                                    printDebug(
                                      'Erreur lors du cadrage initial de la carte: $error',
                                    );
                                  });
                            }
                          },
                          markers: markers,
                          polylines: polylines,
                          trafficEnabled: _trafficEnabled,
                          myLocationEnabled: currentPosition != null,
                          myLocationButtonEnabled: !widget.embedded,
                          zoomControlsEnabled: true,
                          zoomGesturesEnabled: true,
                          scrollGesturesEnabled: true,
                          rotateGesturesEnabled: true,
                          tiltGesturesEnabled: true,
                          mapToolbarEnabled: false,
                          mapType: MapType.normal,
                          padding: EdgeInsets.only(
                            top: widget.embedded ? controlsTop : 0,
                            bottom:
                                widget.embedded ? height * 0.32 : height * 0.24,
                          ),
                        ),
                        Positioned(
                          right: 16,
                          bottom: height * 0.32,
                          child: Column(
                            children: [
                              if (widget.embedded) ...[
                                FloatingActionButton.small(
                                  heroTag: 'fullscreen_route',
                                  onPressed: _openFullscreenMap,
                                  backgroundColor: AppColors.primary,
                                  elevation: 0,
                                  child: const Icon(
                                    LucideIcons.maximize2,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                              FloatingActionButton.small(
                                heroTag:
                                    widget.embedded
                                        ? 'traffic_embedded'
                                        : 'traffic_fullscreen',
                                onPressed: _toggleTraffic,
                                backgroundColor:
                                    _trafficEnabled
                                        ? AppColors.warning
                                        : AppColors.surfaceElevated,
                                elevation: 0,
                                child: Icon(
                                  LucideIcons.trafficCone,
                                  color:
                                      _trafficEnabled
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              FloatingActionButton.small(
                                heroTag:
                                    widget.embedded
                                        ? 'alerts_embedded'
                                        : 'alerts_fullscreen',
                                onPressed: _toggleAlerts,
                                backgroundColor:
                                    _alertsEnabled
                                        ? AppColors.error
                                        : AppColors.surfaceElevated,
                                elevation: 0,
                                child: Icon(
                                  LucideIcons.triangleAlert,
                                  color:
                                      _alertsEnabled
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              FloatingActionButton.small(
                                heroTag:
                                    widget.embedded
                                        ? 'recenter_embedded'
                                        : 'recenter_fullscreen',
                                onPressed: _recenterMap,
                                backgroundColor: AppColors.surfaceElevated,
                                elevation: 0,
                                child: const Icon(
                                  LucideIcons.locateFixed,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: controlsTop,
                          left: 16,
                          child: ElevatedButton.icon(
                            onPressed:
                                isLoadingRouteMode ? null : _showRouteModeSheet,
                            icon: const Icon(Icons.tune),
                            label: Text(
                              isLoadingRouteMode
                                  ? 'Calcul...'
                                  : _routeModeLabel(
                                    widget.route?.mode ?? 'fast',
                                  ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.surfaceElevated,
                              foregroundColor: AppColors.textPrimary,
                              elevation: 0,
                              minimumSize: const Size(96, 44),
                              maximumSize: const Size(150, 48),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              side: const BorderSide(color: AppColors.divider),
                            ),
                          ),
                        ),
                        Positioned(
                          top: controlsTop,
                          right: 16,
                          child: ElevatedButton.icon(
                            onPressed:
                                isLoadingAlternative
                                    ? null
                                    : _showSaferAlternative,
                            icon: const Icon(Icons.alt_route),
                            label: Text(
                              isLoadingAlternative
                                  ? 'Recherche...'
                                  : 'Alternative',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              minimumSize: const Size(112, 44),
                              maximumSize: const Size(160, 48),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shadowColor: AppColors.glow,
                            ),
                          ),
                        ),
                        DraggableScrollableSheet(
                          minChildSize: 0.16,
                          initialChildSize: 0.38,
                          maxChildSize: 0.92,
                          snap: true,
                          snapSizes: const [0.16, 0.38, 0.92],
                          builder: (context, scrollController) {
                            return NavigationBottomSheet(
                              route: widget.route,
                              scrollController: scrollController,
                              onReport: _showReportSheet,
                              onStartNavigation:
                                  isNavigating
                                      ? _stopNavigation
                                      : _startNavigation,
                              isNavigating: isNavigating,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );

    if (widget.embedded) return body;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: const BackButton(color: AppColors.textPrimary),
      ),
      body: body,
    );
  }
}

class _RouteModeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _RouteModeOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class NavigationBottomSheet extends StatelessWidget {
  final RoutesModel? route;
  final ScrollController? scrollController;
  final Function()? onStartNavigation;
  final Function()? onReport;
  final bool isNavigating;

  const NavigationBottomSheet({
    super.key,
    this.route,
    this.scrollController,
    this.onStartNavigation,
    this.onReport,
    this.isNavigating = false,
  });

  String _formatDistance(String? points) {
    if (points == null || points.isEmpty) return '0 km';

    var totalDistance = 0.0;
    final routePoints = points.split('|');

    for (int i = 0; i < routePoints.length - 1; i++) {
      final point1 = routePoints[i].split(',');
      final point2 = routePoints[i + 1].split(',');

      final lat1 = double.parse(point1[0]);
      final lng1 = double.parse(point1[1]);
      final lat2 = double.parse(point2[0]);
      final lng2 = double.parse(point2[1]);

      const earthRadius = 6371.0;
      final dLat = _toRadians(lat2 - lat1);
      final dLng = _toRadians(lng2 - lng1);

      final a =
          math.sin(dLat / 2) * math.sin(dLat / 2) +
          math.cos(_toRadians(lat1)) *
              math.cos(_toRadians(lat2)) *
              math.sin(dLng / 2) *
              math.sin(dLng / 2);
      final c = 2 * math.asin(math.sqrt(a));
      totalDistance += earthRadius * c;
    }

    return '${totalDistance.toStringAsFixed(1)} km';
  }

  double _toRadians(double degree) {
    return degree * (3.141592653589793 / 180);
  }

  String _estimateDuration(String? points) {
    if (points == null || points.isEmpty) return '0 min';

    final distance = _formatDistance(points).replaceAll(' km', '');
    final hours = double.parse(distance) / 50;
    final minutes = (hours * 60).round();

    return '$minutes min';
  }

  String _buildWarningSummary(List<Map<String, dynamic>>? warnings) {
    if (warnings == null || warnings.isEmpty) return '';

    final count = warnings.length;
    final severeCount =
        warnings.where((warning) => warning['severity'] == 'eleve').length;

    if (severeCount > 0) {
      return 'itinerary_warning_summary_high'.trParams({
        'count': '$count',
        'severe': '$severeCount',
      });
    }

    return 'itinerary_warning_summary'.trParams({'count': '$count'});
  }

  List<Map<String, dynamic>> _routeSegments() {
    return route?.segments ?? const [];
  }

  String _formatSegmentDistance(dynamic distance) {
    final km =
        distance is num ? distance.toDouble() : double.tryParse('$distance');
    if (km == null || km <= 0) {
      return '';
    }
    if (km < 1) {
      return '${(km * 1000).round()} m';
    }
    return '${km.toStringAsFixed(1)} km';
  }

  Widget _buildSegmentsList(List<Map<String, dynamic>> segments) {
    if (segments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Instructions de navigation',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...segments.asMap().entries.map((entry) {
            final index = entry.key;
            final segment = entry.value;
            final instruction =
                segment['instruction']?.toString().trim().isNotEmpty == true
                    ? segment['instruction'].toString()
                    : 'Continuer sur l itineraire';
            final distance = _formatSegmentDistance(segment['distance']);
            final riskLevel = segment['riskLevel']?.toString();
            final isRisky = riskLevel == 'high' || riskLevel == 'medium';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:
                    isRisky
                        ? AppColors.warning.withValues(alpha: 0.12)
                        : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color:
                      isRisky
                          ? AppColors.warning.withValues(alpha: 0.35)
                          : AppColors.divider,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          instruction,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (distance.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            distance,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        if (isRisky) ...[
                          const SizedBox(height: 4),
                          Text(
                            riskLevel == 'high'
                                ? 'Zone a risque eleve'
                                : 'Zone a risque moyen',
                            style: const TextStyle(
                              color: AppColors.warning,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final segments = _routeSegments();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        border: const Border(top: BorderSide(color: AppColors.divider)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, -8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 12, top: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Icon(
                          LucideIcons.route,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          route?.nom ?? 'itinerary_title'.tr,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatDistance(route?.points),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            _estimateDuration(route?.points),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.only(top: 16, bottom: 4),
              child: Column(
                children: [
                  if (route?.warnings?.isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  color: AppColors.warning,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'itinerary_reported_route'.tr,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _buildWarningSummary(route?.warnings),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (route?.warnings?.isNotEmpty == true)
                    const SizedBox(height: 12),
                  _buildSegmentsList(segments),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: onReport,
                  icon: const Icon(Icons.report_problem_outlined),
                  label: const Text('Signaler'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    minimumSize: const Size(112, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onStartNavigation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isNavigating ? AppColors.error : AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: AppColors.glow,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      isNavigating
                          ? 'itinerary_stop_navigation'.tr
                          : 'itinerary_start_navigation'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
