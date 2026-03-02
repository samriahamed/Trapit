import 'dart:async';
import 'trap_event_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final TrapEventService _eventService = TrapEventService();
  Timer? _pollTimer;
  int _lastKnownSerialNo = 0;

  Future<void> init() async {
    // Notifications disabled temporarily
  }

  void startPolling({Duration interval = const Duration(seconds: 10)}) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(interval, (_) => _checkForNewEvents());
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _checkForNewEvents() async {
    try {
      final events = await _eventService.fetchEvents(limit: 5);
      if (events.isEmpty) return;
      final latest = events.first;
      if (latest.serialNo > _lastKnownSerialNo) {
        _lastKnownSerialNo = latest.serialNo;
      }
    } catch (_) {}
  }
}