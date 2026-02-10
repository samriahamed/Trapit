import 'dart:convert';
import 'package:http/http.dart' as http;
import '../session/user_session.dart';
import '../models/trap_model.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  // ================= AUTH =================

  static Future<void> register({
    required String email,
    required String fullName,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'fullName': fullName,
        'password': password,
      }),
    );

    if (res.statusCode == 400) {
      throw Exception('User already exists');
    }

    if (res.statusCode != 201) {
      throw Exception('Registration failed');
    }
  }

  static Future<void> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Invalid email or password');
    }

    final data = json.decode(res.body);

    UserSession.email = data['user']['email'];
    UserSession.fullName = data['user']['fullName'] ?? '';

    await UserSession.saveSession();
  }

  /// ⭐ UPDATE NAME
  static Future<void> updateUserName(String fullName) async {
    final res = await http.put(
      Uri.parse('$baseUrl/auth/update-name'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': UserSession.email,
        'fullName': fullName,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to update name');
    }

    UserSession.fullName = fullName;
    await UserSession.saveSession();
  }

  /// 🔐 CHANGE PASSWORD (NEW)
  static Future<void> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/change-password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception(json.decode(res.body)['message']);
    }
  }

  // ================= FORGOT PASSWORD =================

  static Future<void> sendOtp(String email) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to send OTP');
    }
  }

  static Future<void> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'otp': otp,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Invalid or expired OTP');
    }
  }

  static Future<void> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'newPassword': newPassword,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Password reset failed');
    }
  }

  // ================= TRAPS =================

  static Future<List<TrapModel>> getUserTraps(String email) async {
    final res = await http.get(
      Uri.parse('$baseUrl/traps/user/$email'),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to load traps');
    }

    final List data = json.decode(res.body);
    return data.map((e) => TrapModel.fromJson(e)).toList();
  }

  static Future<void> addTrap({
    required String email,
    required String trapId,
    required String trapName,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/traps/add'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'trapId': trapId,
        'trapName': trapName,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to add trap');
    }
  }

  static Future<void> updateTrapStatus({
    required String trapId,
    required bool isActive,
  }) async {
    final res = await http.put(
      Uri.parse('$baseUrl/traps/status'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'trapId': trapId,
        'status': isActive ? 'active' : 'inactive',
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to update trap status');
    }
  }

  static Future<void> deleteTrap(String trapId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/traps/$trapId'),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to delete trap');
    }
  }
}
