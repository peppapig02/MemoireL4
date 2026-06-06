import '../models/chat_route_request.dart';
import 'chat_intent_service.dart';
import 'geocoding_service.dart';
import 'location_service.dart';

class ChatNavigationResult {
  final ChatRouteRequest request;
  final bool isReadyForRouting;
  final String? failureReason;

  const ChatNavigationResult({
    required this.request,
    required this.isReadyForRouting,
    this.failureReason,
  });
}

class ChatNavigationService {
  final ChatIntentService chatIntentService;
  final LocationService locationService;
  final GeocodingService geocodingService;

  const ChatNavigationService({
    required this.chatIntentService,
    required this.locationService,
    required this.geocodingService,
  });

  Future<ChatNavigationResult> processMessage({
    required String message,
    String? userId,
  }) async {
    final parsedRequest = chatIntentService.parseMessage(
      message: message,
      userId: userId,
    );

    switch (parsedRequest.intent) {
      case ChatIntentService.calculateRouteIntent:
        return _buildRouteRequest(parsedRequest);
      case ChatIntentService.findNearbyPlaceIntent:
        return _buildNearbyRequest(parsedRequest);
      default:
        return ChatNavigationResult(
          request: parsedRequest,
          isReadyForRouting: false,
          failureReason: 'intent_not_supported_yet',
        );
    }
  }

  Future<ChatNavigationResult> _buildRouteRequest(
    ChatRouteRequest request,
  ) async {
    final startResolution = await locationService.resolveStartLocation(request);
    var enrichedRequest = request;

    if (startResolution.hasCoordinates) {
      enrichedRequest = enrichedRequest.copyWith(
        startText: enrichedRequest.startText ?? startResolution.label,
        startLat: startResolution.latitude,
        startLng: startResolution.longitude,
      );
    }

    if (enrichedRequest.destinationText == null ||
        enrichedRequest.destinationText!.trim().isEmpty) {
      return ChatNavigationResult(
        request: enrichedRequest,
        isReadyForRouting: false,
        failureReason: 'missing_destination',
      );
    }

    final destinationResult = await geocodingService.geocodePlace(
      enrichedRequest.destinationText!,
      biasLatitude: enrichedRequest.startLat,
      biasLongitude: enrichedRequest.startLng,
    );
    if (destinationResult == null) {
      return ChatNavigationResult(
        request: enrichedRequest,
        isReadyForRouting: false,
        failureReason: 'destination_not_found',
      );
    }

    enrichedRequest = enrichedRequest.copyWith(
      destinationText: destinationResult.label,
      destinationLat: destinationResult.latitude,
      destinationLng: destinationResult.longitude,
    );

    if (enrichedRequest.startLat == null || enrichedRequest.startLng == null) {
      if (enrichedRequest.startText != null &&
          enrichedRequest.startText!.trim().isNotEmpty &&
          enrichedRequest.startText != 'position_actuelle') {
        final startResult = await geocodingService.geocodePlace(
          enrichedRequest.startText!,
          biasLatitude: enrichedRequest.destinationLat,
          biasLongitude: enrichedRequest.destinationLng,
        );
        if (startResult != null) {
          enrichedRequest = enrichedRequest.copyWith(
            startText: startResult.label,
            startLat: startResult.latitude,
            startLng: startResult.longitude,
          );
        }
      }
    }

    final isReady =
        enrichedRequest.startLat != null &&
        enrichedRequest.startLng != null &&
        enrichedRequest.destinationLat != null &&
        enrichedRequest.destinationLng != null;

    return ChatNavigationResult(
      request: enrichedRequest,
      isReadyForRouting: isReady,
      failureReason: isReady ? null : 'start_location_not_resolved',
    );
  }

  Future<ChatNavigationResult> _buildNearbyRequest(
    ChatRouteRequest request,
  ) async {
    final startResolution = await locationService.resolveStartLocation(request);
    final enrichedRequest = request.copyWith(
      startText: request.startText ?? startResolution.label,
      startLat: startResolution.latitude,
      startLng: startResolution.longitude,
      resultCount: request.resultCount ?? 1,
    );

    if (enrichedRequest.category == null || enrichedRequest.category!.isEmpty) {
      return ChatNavigationResult(
        request: enrichedRequest,
        isReadyForRouting: false,
        failureReason: 'missing_category',
      );
    }

    final isReady =
        enrichedRequest.startLat != null && enrichedRequest.startLng != null;

    return ChatNavigationResult(
      request: enrichedRequest,
      isReadyForRouting: isReady,
      failureReason: isReady ? null : 'reference_location_not_resolved',
    );
  }
}
