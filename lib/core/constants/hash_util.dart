import 'dart:convert';
import 'package:crypto/crypto.dart';

class HashUtil {
  static String hash(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }
}