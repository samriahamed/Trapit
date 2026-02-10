import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static String email = '';
  static String fullName = '';

  static bool get isLoggedIn => email.isNotEmpty;

  /// ✅ SMART FALLBACK
  static String get displayName {
    if (fullName.trim().isNotEmpty) return fullName.trim();
    if (email.trim().isNotEmpty) return email.trim();
    return 'User';
  }

  static Future<void> saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
    await prefs.setString('fullName', fullName);
  }

  static Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    email = prefs.getString('email') ?? '';
    fullName = prefs.getString('fullName') ?? '';
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    email = '';
    fullName = '';
  }
}
