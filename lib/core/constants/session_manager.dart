import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const keyLogin = "logged_in";
  static const keyPhone = "user_phone";

  static Future<void> saveLogin(String phone) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setBool(keyLogin, true);
    await pref.setString(keyPhone, phone);
  }

  static Future<String?> getPhone() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString(keyPhone);
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