import 'package:shared_preferences/shared_preferences.dart';

class AIConfig {
  static const String _apiKeyPref = 'gemini_api_key';
  static const String defaultModel = 'gemini-1.5-flash';

  // Fallback key (may be expired — users should set their own)
  static const String _fallbackKey = 'AIzaSyBtjdHjEOK1CLnpHXAkChOhUPv1C6uWsxI';

  static Future<String> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_apiKeyPref);
    return (stored != null && stored.isNotEmpty) ? stored : _fallbackKey;
  }

  static Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPref, key.trim());
  }

  static Future<bool> hasCustomKey() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_apiKeyPref);
    return stored != null && stored.isNotEmpty && stored != _fallbackKey;
  }

  // Synchronous access – returns fallback only.
  // Use getApiKey() for async loading.
  static String get model => defaultModel;
}