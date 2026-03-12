import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../core/config/ai_config.dart';

const String _systemPrompt = '''Bạn là Trợ lý AI Tiêm chủng thông minh, hỗ trợ người dùng về:
- Lịch tiêm chủng cho trẻ em và người lớn (theo chuẩn Bộ Y tế Việt Nam)
- Thông tin về các loại vaccine phổ biến
- Phân tích giấy/sổ tiêm chủng từ ảnh
- Nhắc nhở lịch tiêm và giải đáp thắc mắc về phản ứng sau tiêm

Hãy trả lời bằng tiếng Việt, ngắn gọn, dễ hiểu, chính xác về y tế. 
Khi không chắc chắn, hãy khuyên người dùng tham khảo bác sĩ hoặc cơ sở y tế gần nhất.''';

class AIService {
  GenerativeModel? _model;
  String? _currentApiKey;

  Future<GenerativeModel> _getModel() async {
    final apiKey = await AIConfig.getApiKey();
    if (_model == null || _currentApiKey != apiKey) {
      _currentApiKey = apiKey;
      _model = GenerativeModel(
        model: AIConfig.model,
        apiKey: apiKey,
        systemInstruction: Content.system(_systemPrompt),
      );
    }
    return _model!;
  }

  /// ================= CHAT STREAM =================
  Stream<String> sendMessageStream(
    List<Map<String, dynamic>> history,
    String message,
  ) async* {
    final model = await _getModel();
    final contents = <Content>[];

    for (final h in history) {
      contents.add(
        Content(
          h["role"],
          (h["parts"] as List).map((p) => TextPart(p["text"])).toList(),
        ),
      );
    }

    contents.add(Content.text(message));

    try {
      final response = model.generateContentStream(contents);
      await for (final chunk in response) {
        final text = chunk.text;
        if (text != null) {
          yield text;
        }
      }
    } on InvalidApiKey {
      yield '❌ API key không hợp lệ. Vui lòng vào Hồ sơ → Cài đặt AI để nhập API key mới.';
    } on ServerException catch (e) {
      yield '❌ Lỗi máy chủ: ${e.message}. Vui lòng thử lại.';
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('api_key') || msg.contains('apikey') || msg.contains('unauthorized') || msg.contains('403')) {
        yield '❌ API key không hợp lệ. Vào Hồ sơ → Cài đặt AI để nhập key mới.';
      } else if (msg.contains('network') || msg.contains('socketexception') || msg.contains('timeout')) {
        yield '📡 Không có kết nối mạng. Kiểm tra internet và thử lại.';
      } else {
        yield '⚠️ Không thể kết nối AI. Thử lại sau.\n(Chi tiết: ${e.toString().split('\n').first})';
      }
    }
  }

  /// ================= IMAGE SCAN =================
  Future<String> scanVaccinationRecord(File file) async {
    try {
      final model = await _getModel();
      final bytes = await file.readAsBytes();
      final response = await model.generateContent([
        Content.multi([
          TextPart('Đây là ảnh sổ/phiếu tiêm chủng. Hãy đọc và liệt kê:\n'
              '1. Tên các loại vaccine đã tiêm\n'
              '2. Ngày tiêm từng mũi\n'
              '3. Còn mũi nào chưa tiêm không?\n'
              'Trả lời bằng tiếng Việt, rõ ràng và đầy đủ.'),
          DataPart('image/jpeg', bytes),
        ])
      ]);
      return response.text ?? 'Không đọc được nội dung ảnh.';
    } on InvalidApiKey {
      return '❌ API key không hợp lệ. Vào Hồ sơ → Cài đặt AI để nhập key mới.';
    } catch (e) {
      return '⚠️ Không thể phân tích ảnh: ${e.toString().split('\n').first}';
    }
  }
}