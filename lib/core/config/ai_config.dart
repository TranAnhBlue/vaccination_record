import 'package:shared_preferences/shared_preferences.dart';

class AIConfig {
  static const String _apiKeyPref = 'gemini_api_key';
  static const String defaultModel = 'gemini-2.5-flash';

  static Future<String> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_apiKeyPref);
    return (stored ?? '').trim();
  }

  static Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPref, key.trim());
  }

  static Future<bool> hasCustomKey() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_apiKeyPref);
    return stored != null && stored.trim().isNotEmpty;
  }

  static String get model => defaultModel;
}