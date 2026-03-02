Stream<String> typeWriter(String text) async* {
  String current = "";

  for (int i = 0; i < text.length; i++) {
    await Future.delayed(const Duration(milliseconds: 15));
    current += text[i];
    yield current;
  }
}