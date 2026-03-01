import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AIService {
  static const String _apiKey = "AIzaSyCsijSSNtyijM3kTrSX72RrKPNYJ1BrQOE";
  static const String _model = "gemini-2.0-flash-lite";
  static const String _baseUrl =
      "https://generativelanguage.googleapis.com/v1/models";

  /// Method for Chatbot — gửi lịch sử chat và tin nhắn mới
  Future<String> getChatResponse(
      List<Map<String, dynamic>> history, String message) async {
    final url = Uri.parse("$_baseUrl/$_model:generateContent?key=$_apiKey");

    // Inject system persona as first turn if history is empty
    final List<Map<String, dynamic>> contents = [
      if (history.isEmpty) ...[
        {
          "role": "user",
          "parts": [{"text": "Bạn là trợ lý AI chuyên về y tế và vắc xin. Hãy trả lời bằng tiếng Việt ngắn gọn."}]
        },
        {
          "role": "model",
          "parts": [{"text": "Được, tôi sẽ trả lời bằng tiếng Việt về các vấn đề y tế và vắc xin."}]
        },
      ],
      ...history,
      {
        "role": "user",
        "parts": [{"text": message}]
      },
    ];

    try {
      http.Response response;
      int attempts = 0;
      do {
        response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"contents": contents}),
        );
        if (response.statusCode == 429 && attempts < 3) {
          attempts++;
          await Future.delayed(Duration(seconds: 5 * attempts)); // 5s, 10s, 15s
        } else {
          break;
        }
      } while (true);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"] ??
            "Xin lỗi, tôi không thể trả lời lúc này.";
      } else if (response.statusCode == 429) {
        return "Hệ thống đang bận, vui lòng thử lại sau 1 phút.";
      } else {
        debugPrint("AI Error ${response.statusCode}: ${response.body}");
        return "Lỗi từ API (${response.statusCode}): ${_parseError(response.body)}";
      }
    } catch (e) {
      debugPrint("AI Network Error: $e");
      return "Không thể kết nối tới AI. Kiểm tra kết nối mạng.";
    }
  }

  /// Method for Scanning Record (OCR/Analysis)
  Future<String> scanVaccinationRecord(File imageFile) async {
    final url = Uri.parse("$_baseUrl/$_model:generateContent?key=$_apiKey");

    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final body = jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "text":
                    "Hãy phân tích ảnh giấy tiêm chủng này và trả về các thông tin: "
                        "1. Tên vắc xin, 2. Số mũi (liều), 3. Ngày tiêm, 4. Địa điểm. "
                        "Nếu không thấy ghi là 'Không tìm thấy'. Trả lời tiếng Việt ngắn gọn."
              },
              {
                "inline_data": {"mime_type": "image/jpeg", "data": base64Image}
              }
            ]
          }
        ]
      });

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"] ??
            "Không thể đọc thông tin từ ảnh.";
      } else {
        return "Lỗi quét ảnh (${response.statusCode}): ${_parseError(response.body)}";
      }
    } catch (e) {
      return "Lỗi phân tích ảnh: $e";
    }
  }

  String _parseError(String body) {
    try {
      final data = jsonDecode(body);
      return data["error"]?["message"] ?? body;
    } catch (_) {
      return body;
    }
  }
}
