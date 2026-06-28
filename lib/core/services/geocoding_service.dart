import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';

class GeocodingResult {
  final String? placeId;
  final String label;
  final String? address;
  final double latitude;
  final double longitude;

  const GeocodingResult({
    this.placeId,
    required this.label,
    this.address,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'placeId': placeId,
      'label': label,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class GeocodingService {
  final String apiKey;
  final List<String> countries;
  final String defaultCityContext;
  FlutterGooglePlacesSdk? _placesSdk;

  GeocodingService({
    required this.apiKey,
    this.countries = const ['CD'],
    this.defaultCityContext = 'Kinshasa',
  });

  Future<GeocodingResult?> geocodePlace(
    String placeName, {
    double? biasLatitude,
    double? biasLongitude,
  }) async {
    final results = await geocodePlaceOptions(
      placeName,
      biasLatitude: biasLatitude,
      biasLongitude: biasLongitude,
      limit: 1,
    );
    return results.isEmpty ? null : results.first;
  }

  Future<List<GeocodingResult>> geocodePlaceOptions(
    String placeName, {
    double? biasLatitude,
    double? biasLongitude,
    int limit = 5,
  }) async {
    try {
      final query = placeName.trim();
      if (query.isEmpty) {
        return const [];
      }

      final placesSdk = _getSdk();
      await _ensureInitialized();
      final candidates = _buildSearchCandidates(query);
      final results = <GeocodingResult>[];
      final seenPlaceIds = <String>{};

      for (final candidate in candidates) {
        final predictions = await placesSdk.findAutocompletePredictions(
          candidate,
          countries: countries,
          origin:
              biasLatitude != null && biasLongitude != null
                  ? LatLng(lat: biasLatitude, lng: biasLongitude)
                  : null,
          locationBias:
              biasLatitude != null && biasLongitude != null
                  ? _buildLocationBias(biasLatitude, biasLongitude)
                  : null,
        );

        if (predictions.predictions.isEmpty) {
          continue;
        }

        final rankedPredictions =
            predictions.predictions.toList()..sort((a, b) {
              final aDistance = a.distanceMeters ?? 1 << 30;
              final bDistance = b.distanceMeters ?? 1 << 30;
              return aDistance.compareTo(bDistance);
            });

        for (final prediction in rankedPredictions) {
          if (seenPlaceIds.contains(prediction.placeId)) {
            continue;
          }

          final details = await placesSdk.fetchPlace(
            prediction.placeId,
            fields: [PlaceField.Name, PlaceField.Address, PlaceField.Location],
          );

          final place = details.place;
          final latLng = place?.latLng;
          if (place == null || latLng == null) {
            continue;
          }

          seenPlaceIds.add(prediction.placeId);
          results.add(
            GeocodingResult(
              placeId: prediction.placeId,
              label: place.name ?? candidate,
              address: place.address,
              latitude: latLng.lat,
              longitude: latLng.lng,
            ),
          );

          if (results.length >= limit) {
            return results;
          }
        }
      }

      return results;
    } catch (_) {
      return const [];
    }
  }

  FlutterGooglePlacesSdk _getSdk() {
    _placesSdk ??= FlutterGooglePlacesSdk(apiKey);
    return _placesSdk!;
  }

  Future<void> _ensureInitialized() async {
    final sdk = _getSdk();
    final isInitialized = await sdk.isInitialized();
    if (isInitialized != true) {
      await FlutterGooglePlacesSdk.platform.initialize(apiKey);
    }
  }

  List<String> _buildSearchCandidates(String query) {
    final cleaned = _cleanQuery(query);
    final spaced = _splitJoinedWords(cleaned);
    final candidates = <String>[];

    void add(String value) {
      final candidate = value.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (candidate.isNotEmpty && !candidates.contains(candidate)) {
        candidates.add(candidate);
      }
    }

    add(cleaned);
    add(spaced);

    if (!_alreadyHasCityContext(cleaned)) {
      add('$cleaned $defaultCityContext');
      add('$spaced $defaultCityContext');
      add('$cleaned RD Congo');
      add('$spaced RD Congo');
    }

    return candidates;
  }

  String _cleanQuery(String query) {
    return query
        .trim()
        .replaceAll(RegExp(r'^[,:;\- ]+'), '')
        .replaceAll(RegExp(r'[.!?]+$'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  String _splitJoinedWords(String query) {
    return query
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (match) => '${match.group(1)} ${match.group(2)}',
        )
        .replaceAllMapped(
          RegExp(r'([A-Za-z])(\d)'),
          (match) => '${match.group(1)} ${match.group(2)}',
        )
        .replaceAllMapped(
          RegExp(r'(\d)([A-Za-z])'),
          (match) => '${match.group(1)} ${match.group(2)}',
        );
  }

  bool _alreadyHasCityContext(String query) {
    final normalized = query.toLowerCase();
    return normalized.contains(defaultCityContext.toLowerCase()) ||
        normalized.contains('rd congo') ||
        normalized.contains('rdc') ||
        normalized.contains('congo') ||
        normalized.contains('drc');
  }

  LatLngBounds _buildLocationBias(double latitude, double longitude) {
    const delta = 0.06;
    return LatLngBounds(
      southwest: LatLng(lat: latitude - delta, lng: longitude - delta),
      northeast: LatLng(lat: latitude + delta, lng: longitude + delta),
    );
  }
}
