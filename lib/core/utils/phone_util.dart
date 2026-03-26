/// Chuẩn hóa số điện thoại Việt Nam (0xxxxxxxxx) để đăng nhập/đăng ký nhất quán.
String normalizeVietnamesePhone(String raw) {
  var s = raw.trim().replaceAll(RegExp(r'[\s.-]'), '');
  if (s.isEmpty) return s;

  if (s.startsWith('+84')) {
    final rest = s.substring(3);
    if (rest.isEmpty) return raw.trim();
    s = '0$rest';
  } else if (s.startsWith('84') && s.length >= 10 && !s.startsWith('0')) {
    s = '0${s.substring(2)}';
  }
  return s;
}
