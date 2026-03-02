import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../core/config/ai_config.dart';

class AIService {
  late final GenerativeModel _model;

  AIService() {
    _model = GenerativeModel(
      model: AIConfig.model,
      apiKey: AIConfig.apiKey,
    );
  }

  /// ================= CHAT STREAM =================
  Stream<String> sendMessageStream(
      List<Map<String, dynamic>> history,
      String message,
      ) async* {
    final contents = <Content>[];

    /// convert history -> Content
    for (final h in history) {
      contents.add(
        Content(
          h["role"],
          (h["parts"] as List)
              .map((p) => TextPart(p["text"]))
              .toList(),
        ),
      );
    }

    /// add new message
    contents.add(Content.text(message));

    final response = _model.generateContentStream(contents);

    await for (final chunk in response) {
      final text = chunk.text;
      if (text != null) {
        yield text;
      }
    }
  }

  /// ================= IMAGE SCAN =================
  Future<String> scanVaccinationRecord(File file) async {
    final bytes = await file.readAsBytes();

    final response = await _model.generateContent([
      Content.multi([
        TextPart("Phân tích giấy tiêm chủng trong ảnh này."),
        DataPart("image/jpeg", bytes),
      ])
    ]);

    return response.text ?? "Không đọc được nội dung.";
  }
}