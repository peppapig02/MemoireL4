import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OpenAIService {
  OpenAIService({required this.apiKey, this.functions});

  final String apiKey;
  final String baseUrl = 'https://api.openai.com/v1';
  final FirebaseFunctions? functions;

  Future<Map<String, dynamic>> generateResponse(
    String prompt, {
    String? context,
  }) async {
    try {
      if (kIsWeb) {
        return _generateResponseWithCallable(prompt, context: context);
      }

      final messages = [
        if (context != null) {'role': 'system', 'content': context},
        {'role': 'user', 'content': prompt},
      ];

      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to generate response: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];
      return _parseContent(content);
    } catch (e) {
      throw Exception('Error generating response: $e');
    }
  }

  Future<Map<String, dynamic>> _generateResponseWithCallable(
    String prompt, {
    String? context,
  }) async {
    try {
      final callableFunctions = functions ?? FirebaseFunctions.instance;
      final callable = callableFunctions.httpsCallable('generateChatResponse');
      final response = await callable.call({
        'prompt': prompt,
        'context': context,
      });
      final data = response.data;

      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      throw Exception('Invalid response format from generateChatResponse');
    } on FirebaseFunctionsException catch (e) {
      throw Exception(_mapCallableError(e));
    }
  }

  String _mapCallableError(FirebaseFunctionsException error) {
    switch (error.code) {
      case 'failed-precondition':
        return "Le backend IA n'est pas encore configure. Il faut finaliser la configuration serveur OpenAI.";
      case 'internal':
        return "Le backend IA web n'est pas encore disponible. Verifiez que la Firebase Function a bien ete deployee et que le projet est en plan Blaze.";
      case 'unavailable':
        return "Le backend IA est temporairement indisponible. Reessayez dans un instant.";
      default:
        return error.message ??
            "Le backend IA a renvoye une erreur (${error.code}).";
    }
  }

  Map<String, dynamic> _parseContent(dynamic content) {
    if (content is! String) {
      return {'message': '$content'};
    }

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
