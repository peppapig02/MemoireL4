import '../models/chat_route_request.dart';

class ChatIntentService {
  static const String calculateRouteIntent = 'calculate_route';
  static const String findNearbyPlaceIntent = 'find_nearby_place';
  static const String reportBadRoadIntent = 'report_bad_road';
  static const String showTripHistoryIntent = 'show_trip_history';
  static const String unknownIntent = 'unknown';

  ChatRouteRequest parseMessage({
    required String message,
    String? userId,
  }) {
    final normalized = _normalize(message);
    final intent = _detectIntent(normalized);

    return ChatRouteRequest(
      userId: userId,
      originalMessage: message.trim(),
      intent: intent,
      startText: _extractStartText(message, normalized, intent),
      destinationText: _extractDestinationText(message, normalized, intent),
      category: _extractCategory(normalized, intent),
      resultCount: _extractResultCount(normalized, intent),
      createdAt: DateTime.now(),
    );
  }

  String _detectIntent(String normalizedMessage) {
    if (_isHistoryRequest(normalizedMessage)) {
      return showTripHistoryIntent;
    }

    if (_isRoadReportRequest(normalizedMessage)) {
      return reportBadRoadIntent;
    }

    if (_isNearbySearchRequest(normalizedMessage)) {
      return findNearbyPlaceIntent;
    }

    if (_isRouteRequest(normalizedMessage)) {
      return calculateRouteIntent;
    }

    return unknownIntent;
  }

  bool _isHistoryRequest(String message) {
    return message.contains('historique') ||
        message.contains('trajets precedents') ||
        message.contains('mes trajets') ||
        message.contains('mes voyages');
  }

  bool _isRoadReportRequest(String message) {
    return message.contains('signaler') ||
        message.contains('mauvaise route') ||
        message.contains('nid de poule') ||
        message.contains('nid-de-poule') ||
        message.contains('impraticable') ||
        message.contains('accident') ||
        message.contains('embouteillage') ||
        message.contains('danger');
  }

  bool _isNearbySearchRequest(String message) {
    return message.contains('plus proche') ||
        message.contains('plus proches') ||
        message.contains('proche') ||
        message.contains('pres de moi') ||
        message.contains('autour de moi');
  }

  bool _isRouteRequest(String message) {
    return message.contains('je veux aller') ||
        message.contains('aller a') ||
        message.contains('aller de') ||
        message.contains('itineraire') ||
        message.contains('route vers') ||
        message.contains('conduis moi') ||
        message.contains('conduis-moi') ||
        message.contains('emmene moi') ||
        message.contains('emmene-moi');
  }

  String? _extractStartText(
    String originalMessage,
    String normalizedMessage,
    String intent,
  ) {
    if (intent != calculateRouteIntent) {
      return null;
    }

    final fromPattern = RegExp(
      r'\b(?:je suis a|je suis au|je suis aux|depart de)\s+([^,.]+)',
      caseSensitive: false,
    );
    final fromMatch = fromPattern.firstMatch(normalizedMessage);
    if (fromMatch != null) {
      return _sliceFromOriginal(
        originalMessage,
        fromMatch.start,
        fromMatch.end,
      ).replaceFirst(
        RegExp(
          r'^\s*(je suis a|je suis au|je suis aux|depart de)\s+',
          caseSensitive: false,
        ),
        '',
      ).trim();
    }

    final routePattern = RegExp(
      r'\baller de\s+(.+?)\s+a\s+(.+)',
      caseSensitive: false,
    );
    final routeMatch = routePattern.firstMatch(normalizedMessage);
    if (routeMatch != null) {
      return _sliceFromOriginal(
        originalMessage,
        routeMatch.start + (routeMatch.group(0)?.indexOf(routeMatch.group(1) ?? '') ?? 0),
        routeMatch.start +
            (routeMatch.group(0)?.indexOf(routeMatch.group(1) ?? '') ?? 0) +
            (routeMatch.group(1)?.length ?? 0),
      ).trim();
    }

    return null;
  }

  String? _extractDestinationText(
    String originalMessage,
    String normalizedMessage,
    String intent,
  ) {
    if (intent != calculateRouteIntent) {
      return null;
    }

    final routePattern = RegExp(
      r'\baller de\s+(.+?)\s+a\s+(.+)',
      caseSensitive: false,
    );
    final routeMatch = routePattern.firstMatch(normalizedMessage);
    if (routeMatch != null) {
      final fullMatch = routeMatch.group(0) ?? '';
      final destinationMatch = routeMatch.group(2) ?? '';
      final destinationOffset = fullMatch.lastIndexOf(destinationMatch);
      return _cleanExtractedPlace(
        _sliceFromOriginal(
          originalMessage,
          routeMatch.start + (destinationOffset < 0 ? 0 : destinationOffset),
          routeMatch.start +
              (destinationOffset < 0 ? 0 : destinationOffset) +
              destinationMatch.length,
        ),
      );
    }

    final destinationPatterns = [
      RegExp(r'\bje veux aller a\s+(.+)', caseSensitive: false),
      RegExp(r'\bitineraire vers\s+(.+)', caseSensitive: false),
      RegExp(r'\broute vers\s+(.+)', caseSensitive: false),
      RegExp(r'\bvers\s+(.+)', caseSensitive: false),
    ];

    for (final pattern in destinationPatterns) {
      final match = pattern.firstMatch(normalizedMessage);
      if (match != null) {
        final fullMatch = match.group(0) ?? '';
        final destinationMatch = match.group(1) ?? '';
        final destinationOffset = fullMatch.lastIndexOf(destinationMatch);
        return _cleanExtractedPlace(
          _sliceFromOriginal(
            originalMessage,
            match.start + (destinationOffset < 0 ? 0 : destinationOffset),
            match.start +
                (destinationOffset < 0 ? 0 : destinationOffset) +
                destinationMatch.length,
          ),
        );
      }
    }

    return null;
  }

  String? _extractCategory(String normalizedMessage, String intent) {
    if (intent != findNearbyPlaceIntent) {
      return null;
    }

    const categoryAliases = <String, String>{
      'supermarches': 'supermarche',
      'supermarche': 'supermarche',
      'hopitaux': 'hopital',
      'hopital': 'hopital',
      'restaurants': 'restaurant',
      'restaurant': 'restaurant',
      'jardins': 'jardin',
      'jardin': 'jardin',
      'ecoles': 'ecole',
      'ecole': 'ecole',
      'stations-service': 'station service',
      'station-service': 'station service',
      'stations service': 'station service',
      'station service': 'station service',
      'pharmacies': 'pharmacie',
      'pharmacie': 'pharmacie',
      'universites': 'universite',
      'universite': 'universite',
      'banques': 'banque',
      'banque': 'banque',
    };

    for (final entry in categoryAliases.entries) {
      if (normalizedMessage.contains(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  int? _extractResultCount(String normalizedMessage, String intent) {
    if (intent != findNearbyPlaceIntent) {
      return null;
    }

    final match = RegExp(r'\b(\d+)\b').firstMatch(normalizedMessage);
    if (match == null) {
      return normalizedMessage.contains('plus proches') ? 5 : 1;
    }

    return int.tryParse(match.group(1)!);
  }

  String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll('\u00E0', 'a')
        .replaceAll('\u00E2', 'a')
        .replaceAll('\u00E4', 'a')
        .replaceAll('\u00E9', 'e')
        .replaceAll('\u00E8', 'e')
        .replaceAll('\u00EA', 'e')
        .replaceAll('\u00EB', 'e')
        .replaceAll('\u00EE', 'i')
        .replaceAll('\u00EF', 'i')
        .replaceAll('\u00F4', 'o')
        .replaceAll('\u00F6', 'o')
        .replaceAll('\u00F9', 'u')
        .replaceAll('\u00FB', 'u')
        .replaceAll('\u00FC', 'u')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _sliceFromOriginal(String original, int start, int end) {
    if (start < 0 || end > original.length || start >= end) {
      return '';
    }

    return original.substring(start, end);
  }

  String _cleanExtractedPlace(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'^[,:;\- ]+'), '')
        .replaceAll(RegExp(r'[.!?]+$'), '')
        .trim();
  }
}
