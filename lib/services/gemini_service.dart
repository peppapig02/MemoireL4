import 'dart:async';
import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';

class GeminiService {
  GeminiService({
    List<String>? modelNames,
  }) : _modelNames =
           modelNames ??
           const <String>[
             'gemini-3.1-flash-lite',
             'gemini-2.5-flash',
           ];

  final List<String> _modelNames;

  Future<Map<String, dynamic>> generateResponse(
    String prompt, {
    String? context,
  }) async {
    final fullPrompt =
        context == null || context.trim().isEmpty
            ? prompt
            : '$context\n\nQuestion utilisateur:\n$prompt';

    Object? lastError;

    for (final modelName in _modelNames) {
      final model = FirebaseAI.googleAI().generativeModel(model: modelName);

      for (var attempt = 0; attempt < 2; attempt++) {
        try {
          final response = await model.generateContent([
            Content.text(fullPrompt),
          ]);

          final content = response.text;
          if (content == null || content.trim().isEmpty) {
            throw Exception('Gemini returned an empty response.');
          }

          return _parseContent(content);
        } catch (error) {
          lastError = error;

          if (_isTransientOverload(error) && attempt == 0) {
            await Future<void>.delayed(const Duration(seconds: 2));
            continue;
          }

          if (_isModelNotAvailable(error)) {
            break;
          }

          if (!_isTransientOverload(error)) {
            throw Exception(_mapError(error));
          }
        }
      }
    }

    throw Exception(_mapError(lastError));
  }

  Map<String, dynamic> _parseContent(String content) {
    try {
      if (content.contains('{') && content.contains('}')) {
        final jsonStr = content.substring(
          content.indexOf('{'),
          content.lastIndexOf('}') + 1,
        );
        return Map<String, dynamic>.from(jsonDecode(jsonStr));
      }
    } catch (_) {
      return {'message': content};
    }

    return {'message': content};
  }

  bool _isTransientOverload(Object error) {
    final normalized = error.toString().toLowerCase();
    return normalized.contains('server error [500]') ||
        normalized.contains('"code": 500') ||
        normalized.contains('status":"internal"') ||
        normalized.contains('status: "internal"') ||
        normalized.contains('experiencing high demand') ||
        normalized.contains('spikes in demand') ||
        normalized.contains('try again later');
  }

  bool _isModelNotAvailable(Object error) {
    final normalized = error.toString().toLowerCase();
    return normalized.contains('404') ||
        normalized.contains('not found') ||
        normalized.contains('unsupported') ||
        normalized.contains('unknown model') ||
        normalized.contains('is not found for api version');
  }

  String _mapError(Object? error) {
    if (error == null) {
      return "Le service Gemini n'a pas renvoye de reponse exploitable.";
    }

    final raw = error.toString();
    final normalized = raw.toLowerCase();

    if (_isTransientOverload(raw)) {
      return "Gemini est temporairement surcharge. Reessayez dans quelques instants.";
    }

    if (normalized.contains('api_key_invalid')) {
      return "La configuration Firebase AI du projet est invalide ou incomplete.";
    }

    if (normalized.contains('firebasevertexai.googleapis.com') ||
        normalized.contains('get started')) {
      return "L'API Firebase AI Logic n'est pas encore active sur le projet Firebase.";
    }

    if (normalized.contains('quota')) {
      return "Le quota Gemini du projet Firebase a ete depasse pour le moment.";
    }

    return 'Error generating Gemini response: $raw';
  }
}
