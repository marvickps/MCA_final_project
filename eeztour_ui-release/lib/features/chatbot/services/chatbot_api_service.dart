import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatbotApiService {
  // Remove trailing slash to avoid double slashes in URL
  final String baseUrl = 'https://renewed-moral-firefly.ngrok-free.app';

  // Use 'http://localhost:8000' for iOS simulator or web, or your actual server IP/domain when deployed

  // Send message to chatbot API
  Future<Map<String, dynamic>> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'message': message}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get response: ${response.statusCode}');
      }
    } catch (e) {
      // Return error as part of the response
      return {
        'response':
            'Error connecting to the chatbot server. Please try again later.',
        'error': e.toString(),
      };
    }
  }

  // Check API health
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
