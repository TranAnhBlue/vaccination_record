import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/services/ai_service.dart';
import '../../data/models/chat_message.dart';

class AIViewModel extends ChangeNotifier {
  final AIService _aiService = AIService();

  final List<ChatMessage> _messages = [];
  final List<Map<String, dynamic>> _history = [];

  bool _isLoading = false;
  bool _isTyping = false;
  bool _disposed = false;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isTyping => _isTyping;

  AIViewModel() {
    _messages.add(ChatMessage(
      text:
      "Xin chào! Tôi là Trợ lý AI 🤖.\nTôi có thể giúp bạn về vắc xin hoặc quét giấy tiêm.",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  // ================= SEND =================
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    _messages.add(ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    ));

    /// create AI placeholder
    final aiMessage = ChatMessage(
      text: "",
      isUser: false,
      timestamp: DateTime.now(),
    );

    _messages.add(aiMessage);

    _isLoading = true;
    _isTyping = true;
    _safeNotify();

    try {
      await for (final chunk
          in _aiService.sendMessageStream(_history, text)) {
        aiMessage.text += chunk;
        _safeNotify();
      }

      // Only add to history if it wasn't an error message
      if (!aiMessage.text.startsWith('❌') && !aiMessage.text.startsWith('⚠️') && !aiMessage.text.startsWith('📡')) {
        _history.add({'role': 'user', 'parts': [{'text': text}]});
        _history.add({'role': 'model', 'parts': [{'text': aiMessage.text}]});

        if (_history.length > 20) {
          _history.removeRange(0, _history.length - 20);
        }
      } else {
        // If error, maybe clear placeholder or show as separate message
      }
    } catch (e) {
      aiMessage.text = '⚠️ Lỗi không xác định: ${e.toString().split('\n').first}';
    }

    _isTyping = false;
    _isLoading = false;
    _safeNotify();
  }

  /// ================= TYPE EFFECT =================
  Future<void> _typingEffect(String text) async {
    _isTyping = true;

    final message = ChatMessage(
      text: "",
      isUser: false,
      timestamp: DateTime.now(),
    );

    _messages.add(message);
    _safeNotify();

    for (int i = 0; i < text.length; i++) {
      await Future.delayed(const Duration(milliseconds: 10)); // Faster typing

      message.text += text[i];

      if (i % 5 == 0) {
        _safeNotify();
      }
    }

    _isTyping = false;
    _safeNotify();
  }

  /// ================= IMAGE =================
  Future<void> scanImage(File imageFile) async {
    if (_isLoading) return;

    _isLoading = true;

    final loadingMsg = ChatMessage(
      text: "📷 Đang phân tích ảnh...",
      isUser: false,
      timestamp: DateTime.now(),
    );

    _messages.add(loadingMsg);
    _safeNotify();

    final response =
    await _aiService.scanVaccinationRecord(imageFile);

    _messages.remove(loadingMsg);

    await _typingEffect("📋 Kết quả:\n$response");

    _isLoading = false;
    _safeNotify();
  }

  /// ================= CLEAR =================
  void clearChat() {
    _messages.clear();
    _history.clear();

    _messages.add(ChatMessage(
      text: "Đã xóa lịch sử chat.",
      isUser: false,
      timestamp: DateTime.now(),
    ));

    _safeNotify();
  }
}