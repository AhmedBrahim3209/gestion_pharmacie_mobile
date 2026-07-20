import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ChatMessage {
  final String message;
  final bool isUser;
  final DateTime timestamp;
  ChatMessage({required this.message, required this.isUser, DateTime? timestamp}) : timestamp = timestamp ?? DateTime.now();
}

class ChatProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<ChatMessage> _messages = [];
  bool _isLoading = false;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;

  Future<void> sendMessage(String text) async {
    _messages.add(ChatMessage(message: text, isUser: true));
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _api.sendChatMessage(text);
      _messages.add(ChatMessage(
        message: response['response'] ?? response['message'] ?? 'Pas de réponse',
        isUser: false,
      ));
    } catch (e) {
      _messages.add(ChatMessage(message: 'Erreur: ${e.toString()}', isUser: false));
    }
    _isLoading = false;
    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }
}
