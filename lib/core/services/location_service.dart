import 'package:geolocator/geolocator.dart';

import '../models/chat_route_request.dart';

class DeviceLocation {
  final double latitude;
  final double longitude;

  const DeviceLocation({
    required this.latitude,
    required this.longitude,
  });
}

class LocationResolution {
  final String source;
  final String? label;
  final double? latitude;
  final double? longitude;

  const LocationResolution({
    required this.source,
    this.label,
    this.latitude,
    this.longitude,
  });

  bool get hasCoordinates => latitude != null && longitude != null;
}

class LocationService {
  static const String sourceUserInput = 'user_input';
  static const String sourceCurrentGps = 'current_gps';
  static const String sourceUnresolved = 'unresolved';

  Future<LocationResolution> resolveStartLocation(
    ChatRouteRequest request,
  ) async {
    final hasExplicitStart =
        request.startText != null && request.startText!.trim().isNotEmpty;

    if (hasExplicitStart) {
      return LocationResolution(
        source: sourceUserInput,
        label: request.startText!.trim(),
        latitude: request.startLat,
        longitude: request.startLng,
      );
    }

    final currentLocation = await getCurrentLocation();
    if (currentLocation == null) {
      return const LocationResolution(source: sourceUnresolved);
    }

    return LocationResolution(
      source: sourceCurrentGps,
      label: 'position_actuelle',
      latitude: currentLocation.latitude,
      longitude: currentLocation.longitude,
    );
  }

  Future<DeviceLocation?> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return DeviceLocation(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  Future<bool> canUseCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }
}
