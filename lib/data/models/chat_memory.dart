class ChatMemory {
  final List<Map<String, dynamic>> history = [];

  void addUser(String text) {
    history.add({
      "role": "user",
      "parts": [{"text": text}]
    });
  }

  void addAI(String text) {
    history.add({
      "role": "model",
      "parts": [{"text": text}]
    });
  }

  List<Map<String, dynamic>> getContext({int limit = 10}) {
    if (history.length <= limit) return history;
    return history.sublist(history.length - limit);
  }

  void clear() => history.clear();
}