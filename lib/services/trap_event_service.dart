// lib/services/trap_event_service.dart
//
// Handles all API calls to the Node.js backend for:
//   - Fetching captured animal events (history list)
//   - Fetching notification logs
//
// Add to pubspec.yaml:
//   dependencies:
//     http: ^1.2.0

import 'dart:convert';
import 'package:http/http.dart' as http;

// ── CONFIG ─────────────────────────────────────────────────────
// Change to your Node.js backend IP (the machine running server.js)
const String kNodeBackendUrl = 'http://10.153.9.168:3000';

// Change to your Pi IP (for loading captured images)
const String kPiBaseUrl = 'http://10.153.9.18:8000';
// ───────────────────────────────────────────────────────────────


// ── Data Model ─────────────────────────────────────────────────

class TrapEvent {
  final int    serialNo;
  final String trapId;
  final String animalName;
  final double confidenceScore;
  final String? imageUrl;       // relative e.g. "/images/filename.jpg"
  final String timestamp;

  TrapEvent({
    required this.serialNo,
    required this.trapId,
    required this.animalName,
    required this.confidenceScore,
    this.imageUrl,
    required this.timestamp,
  });

  /// Full URL to load the captured image in Image.network()
  String? get fullImageUrl =>
      imageUrl != null ? '$kPiBaseUrl$imageUrl' : null;

  /// Confidence as percentage string e.g. "87.3%"
  String get confidencePercent =>
      '${(confidenceScore * 100).toStringAsFixed(1)}%';

  /// Formatted timestamp for display e.g. "22.02.2026  11:07 am"
  String get formattedDate {
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      final hour   = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      final ampm   = dt.hour >= 12 ? 'pm' : 'am';
      final day    = dt.day.toString().padLeft(2, '0');
      final month  = dt.month.toString().padLeft(2, '0');
      return '${dt.year}.$month.$day  $hour:$minute $ampm';
    } catch (_) {
      return timestamp;
    }
  }

  factory TrapEvent.fromJson(Map<String, dynamic> j) => TrapEvent(
    serialNo:        j['serial_no'] as int,
    trapId:          j['trap_id']   as String,
    animalName:      j['animal_name'] as String,
    confidenceScore: (j['confidence_score'] as num).toDouble(),
    imageUrl:        j['image_url']  as String?,
    timestamp:       j['timestamp']  as String,
  );
}


class TrapNotification {
  final int    serialNo;
  final int    captureSerialNo;
  final String message;
  final String sentAt;
  final String trapId;
  final String animalName;
  final String? imageUrl;

  TrapNotification({
    required this.serialNo,
    required this.captureSerialNo,
    required this.message,
    required this.sentAt,
    required this.trapId,
    required this.animalName,
    this.imageUrl,
  });

  String? get fullImageUrl =>
      imageUrl != null ? '$kPiBaseUrl$imageUrl' : null;

  factory TrapNotification.fromJson(Map<String, dynamic> j) => TrapNotification(
    serialNo:        j['serial_no']         as int,
    captureSerialNo: j['capture_serial_no'] as int,
    message:         j['message']           as String,
    sentAt:          j['sent_at']           as String,
    trapId:          j['trap_id']           as String,
    animalName:      j['animal_name']       as String,
    imageUrl:        j['image_url']         as String?,
  );
}


// ── Service ────────────────────────────────────────────────────

class TrapEventService {

  // Fetch captured animal history — newest first
  // Optionally filter by trapId
  Future<List<TrapEvent>> fetchEvents({
    String? trapId,
    int limit = 50,
  }) async {
    try {
      String url = '$kNodeBackendUrl/api/events?limit=$limit';
      if (trapId != null) url += '&trap_id=$trapId';

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((j) => TrapEvent.fromJson(j)).toList();
      }
      return [];
    } catch (e) {
      print('[TrapEventService] fetchEvents error: $e');
      return [];
    }
  }

  // Fetch notification log list
  Future<List<TrapNotification>> fetchNotifications({int limit = 30}) async {
    try {
      final response = await http
          .get(Uri.parse('$kNodeBackendUrl/api/notifications?limit=$limit'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((j) => TrapNotification.fromJson(j)).toList();
      }
      return [];
    } catch (e) {
      print('[TrapEventService] fetchNotifications error: $e');
      return [];
    }
  }

  // Fetch unread notification count (for badge)
  Future<int> fetchNotificationCount() async {
    try {
      final response = await http
          .get(Uri.parse('$kNodeBackendUrl/api/notifications/count'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['count'] as int;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  // Delete captured event
  Future<bool> deleteEvent(int serialNo) async {
    try {
      final response = await http
          .delete(Uri.parse('$kNodeBackendUrl/api/events/$serialNo'))
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('[TrapEventService] deleteEvent error: $e');
      return false;
    }
  }

  // Check if backend is reachable
  Future<bool> isBackendOnline() async {
    try {
      final response = await http
          .get(Uri.parse('$kNodeBackendUrl/'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
