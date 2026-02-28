import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenRouterService {
  final String _apiKey = dotenv.env['OPENROUTER_API_KEY'] ?? '';

  Future<String> sendMessage({
    required String model,
    required String message,
  }) async {
    final url = Uri.parse("https://openrouter.ai/api/v1/chat/completions");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_apiKey",
        },
        body: jsonEncode({
          "model": model,
          "messages": [
            {"role": "user", "content": message},
          ],
          "stream": false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['choices'] != null && data['choices'].isNotEmpty) {
          return data['choices'][0]['message']['content'];
        } else {
          return "No response content found.";
        }
      } else {
        throw Exception("Failed: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error sending message: $e");
    }
  }
}
