import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatApi {
  final String baseUrl;
  final String bot;

  ChatApi({
    this.baseUrl = "https://food-chatbot-backend-bq0s.onrender.com",
    this.bot = "food",
  });

  Future<String> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message, 'bot': bot}),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return data['reply'];
      } else {
        return "❌ Error contacting chatbot";
      }
    } catch (e) {
      return "❌ Network error: $e";
    }
  }
}
