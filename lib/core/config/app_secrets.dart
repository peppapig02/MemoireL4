class AppSecrets {
  static const openAiApiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const googleMapsApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  static bool get hasOpenAiApiKey => openAiApiKey.isNotEmpty;
  static bool get hasGoogleMapsApiKey => googleMapsApiKey.isNotEmpty;
}
