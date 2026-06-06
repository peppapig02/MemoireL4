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
  FlutterGooglePlacesSdk? _placesSdk;

  GeocodingService({required this.apiKey, this.countries = const ['CD']});

  Future<GeocodingResult?> geocodePlace(String placeName) async {
    try {
      final query = placeName.trim();
      if (query.isEmpty) {
        return null;
      }

      final placesSdk = _getSdk();
      final predictions = await placesSdk.findAutocompletePredictions(
        query,
        countries: countries,
      );

      if (predictions.predictions.isEmpty) {
        return null;
      }

      final firstPrediction = predictions.predictions.first;
      final details = await placesSdk.fetchPlace(
        firstPrediction.placeId,
        fields: [PlaceField.Name, PlaceField.Address, PlaceField.Location],
      );

      final place = details.place;
      final latLng = place?.latLng;
      if (place == null || latLng == null) {
        return null;
      }

      return GeocodingResult(
        placeId: firstPrediction.placeId,
        label: place.name ?? query,
        address: place.address,
        latitude: latLng.lat,
        longitude: latLng.lng,
      );
    } catch (_) {
      return null;
    }
  }

  FlutterGooglePlacesSdk _getSdk() {
    _placesSdk ??= FlutterGooglePlacesSdk(apiKey);
    return _placesSdk!;
  }
}
