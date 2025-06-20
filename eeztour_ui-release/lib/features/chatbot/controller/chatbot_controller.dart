import 'dart:convert';
import 'package:flutter/material.dart';
import '../model/message_model.dart';
import '../services/chatbot_api_service.dart';

class ChatbotController extends ChangeNotifier {
  List<Message> _messages = [];
  bool _isTyping = false;
  bool _isConnected = false;
  final ChatbotApiService _apiService = ChatbotApiService();

  List<Message> get messages => _messages;
  bool get isTyping => _isTyping;
  bool get isConnected => _isConnected;

  ChatbotController() {
    _checkApiConnection();
  }

  Future<void> _checkApiConnection() async {
    _isConnected = await _apiService.checkHealth();
    notifyListeners();
  }

  void sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // 1. Add the user message.
    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    _messages.add(userMessage);
    notifyListeners();

    _isTyping = true;
    notifyListeners();

    try {
      // 2. Send the message to the API.
      final response = await _apiService.sendMessage(text);
      final responseText = response['response'];
      String botResponseText = 'Failed to parse chatbot response.';
      dynamic rawData; // to store raw JSON data

      // 3. Use regex to extract the JSON block from triple backticks.
      final regex = RegExp(r'```(?:json)?\s*(\{.*?\})\s*```', dotAll: true);
      final match = regex.firstMatch(responseText);

      if (match != null) {
        String jsonBlock = match.group(1)!;
        // Optionally remove extra spaces or newlines.
        String cleanedJson =
            jsonBlock.replaceAll('\n', '').replaceAll('\t', '').trim();

        try {
          final parsedData = json.decode(cleanedJson);
          if (parsedData is Map<String, dynamic> &&
              parsedData.containsKey('detailed_response')) {
            botResponseText = parsedData['detailed_response'];
            // Save the raw data separately
            rawData = parsedData['raw_data'];
          } else {
            botResponseText = responseText;
          }
        } catch (e) {
          botResponseText = 'Failed to parse JSON data.';
        }
      } else {
        // Fallback if regex did not find a JSON block.
        botResponseText = responseText;
      }

      // 4. Add the primary bot reply message using detailed_response.
      final botMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: botResponseText,
        isUser: false,
        timestamp: DateTime.now(),
      );
      _messages.add(botMessage);

      // 5. If raw_data exists, add another bot message with a clickable link.
      if (rawData != null) {
        final analyticsMessage = Message(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          text: "Tap here to view raw analytics data.",
          isUser: false,
          timestamp: DateTime.now(),
          additionalData: rawData, // attach the raw JSON for later display
        );
        _messages.add(analyticsMessage);
      }
    } catch (e) {
      final errorMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: 'Server error. Please try again later.',
        isUser: false,
        timestamp: DateTime.now(),
      );
      _messages.add(errorMessage);
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  void clearChat() {
    _messages.clear();
    notifyListeners();
  }
}
