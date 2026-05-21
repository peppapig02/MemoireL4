import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';

class GeminiService {
  GeminiService({String modelName = 'gemini-3.5-flash'})
    : _model = FirebaseAI.googleAI().generativeModel(model: modelName);

  final GenerativeModel _model;

  Future<Map<String, dynamic>> generateResponse(
    String prompt, {
    String? context,
  }) async {
    try {
      final fullPrompt =
          context == null || context.trim().isEmpty
              ? prompt
              : '$context\n\nQuestion utilisateur:\n$prompt';

      final response = await _model.generateContent([
        Content.text(fullPrompt),
      ]);

      final content = response.text;
      if (content == null || content.trim().isEmpty) {
        throw Exception('Gemini returned an empty response.');
      }

      return _parseContent(content);
    } catch (e) {
      throw Exception('Error generating Gemini response: $e');
    }
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
}
