import 'dart:convert';
import 'package:http/http.dart' as http;
import '../session/user_session.dart';
import '../models/trap_model.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  // ================= AUTH =================

  /// 👤 REGISTER USER
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

  /// 🔐 LOGIN USER
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

    // ✅ Save user to session
    UserSession.email = data['user']['email'];
    UserSession.fullName = data['user']['fullName'] ?? '';
  }

  // ================= TRAPS =================

  /// 📄 GET ALL TRAPS FOR USER
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

  /// ➕ ADD TRAP
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

  /// 🔄 UPDATE STATUS
  static Future<void> updateTrapStatus({
    required String trapId,
    required bool isActive,
  }) async {
    await http.put(
      Uri.parse('$baseUrl/traps/status'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'trapId': trapId,
        'status': isActive ? 'active' : 'inactive',
      }),
    );
  }

  /// 🗑️ DELETE TRAP
  static Future<void> deleteTrap(String trapId) async {
    await http.delete(
      Uri.parse('$baseUrl/traps/$trapId'),
    );
  }
}
