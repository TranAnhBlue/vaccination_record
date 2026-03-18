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

    if (apiKey.isEmpty) {
      throw Exception('missing_api_key');
    }

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

  String _mapRole(dynamic role) {
    final r = (role ?? '').toString().toLowerCase();
    if (r == 'model' || r == 'assistant') return 'model';
    return 'user';
  }

  List<TextPart> _mapParts(dynamic parts) {
    if (parts is! List) return [TextPart('')];

    return parts.map<TextPart>((p) {
      if (p is Map) {
        return TextPart((p['text'] ?? '').toString());
      }
      return TextPart(p.toString());
    }).toList();
  }

  /// ================= CHAT STREAM =================
  Stream<String> sendMessageStream(
    List<Map<String, dynamic>> history,
    String message,
  ) async* {
    try {
      final model = await _getModel();
      final contents = <Content>[];

      for (final h in history) {
        contents.add(
          Content(
            _mapRole(h['role']),
            _mapParts(h['parts']),
          ),
        );
      }

      contents.add(Content.text(message));

      final response = model.generateContentStream(contents);

      await for (final chunk in response) {
        final text = chunk.text;
        if (text != null && text.trim().isNotEmpty) {
          yield text;
        }
      }
    } on InvalidApiKey {
      yield '❌ API key không hợp lệ. Vui lòng vào Hồ sơ → Cài đặt AI để nhập API key mới.';
    } on UnsupportedUserLocation {
      yield '🌍 Gemini AI chưa hỗ trợ vùng của bạn. Vui lòng thử dùng VPN hoặc kiểm tra lại tài khoản Google AI.';
    } on ServerException catch (e) {
      final err = e.message.toLowerCase();

      if (err.contains('quota') || err.contains('429')) {
        yield '❌ Giới hạn AI đã hết (Quota exceeded). Thử lại sau 1 phút hoặc dùng API key cá nhân.';
      } else if (err.contains('not found') ||
          err.contains('unsupported') ||
          err.contains('404')) {
        yield '⚠️ Model "${AIConfig.model}" không tìm thấy hoặc chưa được hỗ trợ cho API key này. Hãy đổi model trong Cài đặt AI.';
      } else if (err.contains('403') ||
          err.contains('api key') ||
          err.contains('unauthorized')) {
        yield '❌ API key không hợp lệ hoặc không có quyền dùng model này.';
      } else {
        yield '❌ Lỗi máy chủ: ${e.message}. Vui lòng thử lại.';
      }
    } catch (e) {
      final msg = e.toString().toLowerCase();

      if (msg.contains('missing_api_key')) {
        yield '❌ Bạn chưa cấu hình Gemini API key. Vào Hồ sơ → Cài đặt AI để nhập key.';
      } else if (msg.contains('quota') || msg.contains('429')) {
        yield '❌ API key đã hết quota. Hãy thử key khác hoặc thử lại sau.';
      } else if (msg.contains('not found') || msg.contains('404')) {
        yield '⚠️ Model AI không tồn tại hoặc đã ngừng hỗ trợ. Hãy đổi sang model khác.';
      } else if (msg.contains('403') ||
          msg.contains('api key') ||
          msg.contains('apikey') ||
          msg.contains('unauthorized')) {
        yield '❌ API key không hợp lệ hoặc không có quyền dùng model này.';
      } else if (msg.contains('socketexception') ||
          msg.contains('network') ||
          msg.contains('timeout')) {
        yield '📡 Không có kết nối mạng. Kiểm tra internet rồi thử lại.';
      } else {
        yield '⚠️ Không thể kết nối AI. ${e.toString().split('\n').first}';
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
          TextPart(
            'Đây là ảnh sổ/phiếu tiêm chủng. Hãy đọc và liệt kê:\n'
            '1. Tên các loại vaccine đã tiêm\n'
            '2. Ngày tiêm từng mũi\n'
            '3. Còn mũi nào chưa tiêm không?\n'
            'Trả lời bằng tiếng Việt, rõ ràng và đầy đủ.',
          ),
          DataPart('image/jpeg', bytes),
        ]),
      ]);

      return response.text ?? 'Không đọc được nội dung ảnh.';
    } on InvalidApiKey {
      return '❌ API key không hợp lệ. Vào Hồ sơ → Cài đặt AI để nhập key mới.';
    } catch (e) {
      return '⚠️ Không thể phân tích ảnh: ${e.toString().split('\n').first}';
    }
  }

  /// ================= FAMILY INSIGHTS =================
  Future<String> getFamilyInsights(String summary) async {
    try {
      final model = await _getModel();
      final response = await model.generateContent([
        Content.text(
          'Dựa trên dữ liệu tiêm chủng của gia đình dưới đây, hãy đưa ra 1 lời khuyên ngắn gọn (tối đa 2 câu) về mũi tiêm quan trọng nhất cần lưu ý tiếp theo hoặc tình trạng chung.\n'
          'Dữ liệu:\n$summary\n'
          'Hãy trả lời bằng tiếng Việt, thân thiện và chuyên nghiệp.',
        ),
      ]);

      return response.text ??
          'Hãy tiếp tục theo dõi lịch tiêm chủng để bảo vệ sức khỏe gia đình.';
    } catch (e) {
      final msg = e.toString().toLowerCase();

      if (msg.contains('missing_api_key')) {
        return '❌ Bạn chưa cấu hình Gemini API key.';
      }

      return 'AI đang phân tích dữ liệu gia đình bạn. Hãy quay lại sau ít phút.';
    }
  }
}