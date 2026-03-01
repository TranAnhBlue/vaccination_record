import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/services/ai_service.dart';
import '../../data/models/chat_message.dart';

class AIViewModel extends ChangeNotifier {
  final AIService _aiService = AIService();
  final List<ChatMessage> _messages = [];
  // History in Gemini REST API format: [{role, parts:[{text}]}]
  final List<Map<String, dynamic>> _history = [];
  bool _isLoading = false;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;

  AIViewModel() {
    _messages.add(ChatMessage(
      text: "Xin chào! Tôi là Trợ lý AI. Tôi có thể giúp bạn giải đáp thắc mắc về vắc xin hoặc quét giấy tiêm chủng.",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _messages.add(ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    _isLoading = true;
    notifyListeners();

    final response = await _aiService.getChatResponse(_history, text);

    // Update history with both user message and model response
    _history.add({
      "role": "user",
      "parts": [{"text": text}]
    });
    _history.add({
      "role": "model",
      "parts": [{"text": response}]
    });

    _messages.add(ChatMessage(
      text: response,
      isUser: false,
      timestamp: DateTime.now(),
    ));

    _isLoading = false;
    notifyListeners();
  }

  Future<void> scanImage(File imageFile) async {
    _isLoading = true;
    _messages.add(ChatMessage(
      text: "📷 Đang phân tích ảnh giấy tiêm chủng...",
      isUser: false,
      timestamp: DateTime.now(),
    ));
    notifyListeners();

    final response = await _aiService.scanVaccinationRecord(imageFile);

    _messages.removeLast(); // Remove loading message
    _messages.add(ChatMessage(
      text: "📋 Kết quả quét:\n$response",
      isUser: false,
      timestamp: DateTime.now(),
    ));

    _isLoading = false;
    notifyListeners();
  }

  void clearChat() {
    _messages.clear();
    _history.clear();
    _messages.add(ChatMessage(
      text: "Đã xóa lịch sử chat. Tôi có thể giúp gì thêm cho bạn?",
      isUser: false,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }
}
