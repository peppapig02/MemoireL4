import 'dart:math' as math;

import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';

import '../models/nearby_place.dart';

class NearbyPlacesService {
  final String apiKey;
  final List<String> countries;
  FlutterGooglePlacesSdk? _placesSdk;

  NearbyPlacesService({
    required this.apiKey,
    this.countries = const ['CD'],
  });

  Future<List<NearbyPlace>> findNearbyPlaces({
    required double latitude,
    required double longitude,
    required String category,
    int resultCount = 5,
  }) async {
    try {
      final normalizedCategory = _normalizeCategory(category);
      final searchQuery = _mapCategoryToSearchQuery(normalizedCategory);
      if (searchQuery == null) {
        return const [];
      }

      await _ensureInitialized();
      final sdk = _getSdk();
      final response = await sdk.findAutocompletePredictions(
        searchQuery,
        countries: countries,
        origin: LatLng(lat: latitude, lng: longitude),
        locationBias: _buildLocationBias(latitude, longitude),
      );

      if (response.predictions.isEmpty) {
        return const [];
      }

      final predictions = response.predictions.take(resultCount).toList();
      final places = <NearbyPlace>[];

      for (final prediction in predictions) {
        final details = await sdk.fetchPlace(
          prediction.placeId,
          fields: const [
            PlaceField.Name,
            PlaceField.Address,
            PlaceField.Location,
            PlaceField.Rating,
            PlaceField.Types,
          ],
        );

        final place = details.place;
        final latLng = place?.latLng;
        if (place == null || latLng == null) {
          continue;
        }

        places.add(
          NearbyPlace(
            id: place.id,
            name: place.name ?? prediction.primaryText,
            category: normalizedCategory,
            latitude: latLng.lat,
            longitude: latLng.lng,
            distance: (prediction.distanceMeters != null &&
                    prediction.distanceMeters! > 0)
                ? prediction.distanceMeters! / 1000
                : _distanceKm(latitude, longitude, latLng.lat, latLng.lng),
            address: place.address,
            rating: place.rating,
            source: 'google_places',
          ),
        );
      }

      return places;
    } catch (_) {
      return const [];
    }
  }

  LatLngBounds _buildLocationBias(double latitude, double longitude) {
    const delta = 0.05;
    return LatLngBounds(
      southwest: LatLng(lat: latitude - delta, lng: longitude - delta),
      northeast: LatLng(lat: latitude + delta, lng: longitude + delta),
    );
  }

  String? _mapCategoryToSearchQuery(String category) {
    const mapping = <String, String>{
      'supermarche': 'supermarche',
      'supermarches': 'supermarche',
      'hopital': 'hopital',
      'hopitaux': 'hopital',
      'restaurant': 'restaurant',
      'restaurants': 'restaurant',
      'jardin': 'jardin',
      'jardins': 'jardin',
      'ecole': 'ecole',
      'ecoles': 'ecole',
      'station service': 'station service',
      'stations service': 'station service',
      'station-service': 'station service',
      'pharmacie': 'pharmacie',
      'pharmacies': 'pharmacie',
      'universite': 'universite',
      'universites': 'universite',
      'banque': 'banque',
      'banques': 'banque',
    };

    return mapping[category];
  }

  Future<void> _ensureInitialized() async {
    final sdk = _getSdk();
    final isInitialized = await sdk.isInitialized();
    if (isInitialized != true) {
      await FlutterGooglePlacesSdk.platform.initialize(apiKey);
    }
  }

  FlutterGooglePlacesSdk _getSdk() {
    _placesSdk ??= FlutterGooglePlacesSdk(apiKey);
    return _placesSdk!;
  }

  String _normalizeCategory(String category) {
    return category.trim().toLowerCase();
  }

  double _distanceKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final sinLat = math.sin(dLat / 2);
    final sinLng = math.sin(dLng / 2);

    final a = (sinLat * sinLat) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            (sinLng * sinLng);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degToRad(double degrees) {
    return degrees * (math.pi / 180);
  }
}
