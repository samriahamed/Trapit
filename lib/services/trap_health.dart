import 'package:http/http.dart' as http;

class TrapHealth {
  static Future<bool> isOnline(String host) async {
    try {
      final url = Uri.parse("http://$host:8000/health");
      final res = await http.get(url).timeout(const Duration(seconds: 2));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}