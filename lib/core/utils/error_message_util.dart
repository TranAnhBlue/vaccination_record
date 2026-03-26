import 'package:flutter/services.dart';

/// Rút gọn lỗi exception thành một dòng hiển thị cho người dùng (không chứa stack trace).
String readableTechnicalCause(Object error, {int maxLength = 220}) {
  final raw = _rawDetail(error);
  var one = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (one.length > maxLength) {
    one = '${one.substring(0, maxLength - 3)}...';
  }
  return one.isEmpty ? error.runtimeType.toString() : one;
}

String _rawDetail(Object e) {
  if (e is PlatformException) {
    final parts = <String>[];
    if (e.code.isNotEmpty) parts.add('mã: ${e.code}');
    if (e.message != null && e.message!.trim().isNotEmpty) {
      parts.add(e.message!.trim());
    }
    if (e.details != null) {
      final d = e.details.toString().trim();
      if (d.isNotEmpty && d != e.message) parts.add(d);
    }
    if (parts.isEmpty) return e.toString();
    return parts.join(' — ');
  }

  var s = e.toString();
  if (s.startsWith('DatabaseException(') && s.endsWith(')')) {
    s = s.substring('DatabaseException('.length, s.length - 1).trim();
  }
  return s;
}
