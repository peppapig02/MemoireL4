class AppSecrets {
  static const googleMapsApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  static bool get hasGoogleMapsApiKey => googleMapsApiKey.isNotEmpty;
}
