import 'dart:convert'; //pour encoder/décoder le JSON
import 'package:http/http.dart' as http;//package HTTP pour faire les requêtes vers l'API OpenAI

class OpenAIService {
  final String apiKey;
  final String baseUrl = 'https://api.openai.com/v1';

  OpenAIService({required this.apiKey});

  Future<Map<String, dynamic>> generateResponse(
    String prompt, {
    String? context,
  }) async {
    try {
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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];

        // Essayer de parser la réponse comme JSON
        try {
          // Vérifier si la réponse est au format attendu
          if (content.contains('{') && content.contains('}')) {
            // Extraire la partie JSON de la réponse
            //Parfois ChatGPT renvoie du texte au format JSON
            //Donc tu essaies de l’extraire proprement (entre {}) et de le décoder
            final jsonStr = content.substring(
              content.indexOf('{'),
              content.lastIndexOf('}') + 1,
            );
            return jsonDecode(jsonStr);
          }
        } catch (e) {
          // Si le parsing échoue, retourner la réponse brute
          return {'message': content};
        }

        return {'message': content};
      } else {
        throw Exception('Failed to generate response: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error generating response: $e');
    }
  }
}
