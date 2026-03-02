import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// 🔥 Change this if your backend IP changes
const String kNodeBackendUrl = 'http://10.153.9.168:3000';

class UserSession {
  static String email = '';
  static String fullName = '';

  static bool get isLoggedIn => email.isNotEmpty;

  /// SMART FALLBACK
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

  // Validate user with backend
  static Future<void> validateWithServer() async {
    if (email.isEmpty) return;

    try {
      final response = await http.get(
        Uri.parse('$kNodeBackendUrl/api/auth/validate-user/$email'),
      );

      // If user does not exist anymore → clear session
      if (response.statusCode != 200) {
        await clear();
      }
    } catch (_) {
      // If server unreachable, do nothing (keep session)
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    email = '';
    fullName = '';
  }
}