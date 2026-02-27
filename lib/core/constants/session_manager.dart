import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const keyLogin = "logged_in";

  static Future<void> saveLogin() async {
    final pref = await SharedPreferences.getInstance();
    await pref.setBool(keyLogin, true);
  }

  static Future<bool> isLoggedIn() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getBool(keyLogin) ?? false;
  }

  static Future<void> logout() async {
    final pref = await SharedPreferences.getInstance();
    await pref.clear();
  }
}