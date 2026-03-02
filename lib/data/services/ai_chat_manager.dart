// import '../models/chat_memory.dart';
// import 'ai_service.dart';
//
// class AIChatManager {
//   final AIService _service = AIService();
//   final ChatMemory _memory = ChatMemory();
//
//   Future<String> sendMessage(String message) async {
//     _memory.addUser(message);
//
//     final reply = await _service.getChatResponse(
//       _memory.getContext(),
//       message,
//     );
//
//     _memory.addAI(reply);
//
//     return reply;
//   }
//
//   void clear() {
//     _memory.clear();
//   }
// }