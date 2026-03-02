import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../models/trap_model.dart';
import '../screens/trapped_history_screen.dart';
import '../profile/userprofile.dart';
import '../dashboard/trap_registration_screen.dart';
import '../session/user_session.dart';
import '../services/api_service.dart';
import '../services/trap_event_service.dart';
import '../live/watch_live.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isLoadingLive = false;
  bool isLoadingTraps = true;

  int _currentTrapIndex = 0;
  final PageController _pageController = PageController();

  List<TrapModel> _traps = [];
  final Map<String, bool> _onlineMap = {};
  Timer? _onlineTimer;
  bool _checkingOnline = false;

  // ── Recent notifications ─────────────────────────────────────
  List<TrapEvent> _recentEvents = [];
  Timer? _eventTimer;
  int _lastKnownSerialNo = 0;
  final TrapEventService _eventService = TrapEventService();

  @override
  void initState() {
    super.initState();
    _loadTrapsFromServer();
    _loadRecentEvents();
    _startEventPolling();
  }

  @override
  void dispose() {
    _onlineTimer?.cancel();
    _eventTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // ── Trap IP ──────────────────────────────────────────────────
  String? _getTrapHost(TrapModel trap) => "10.153.9.18";

  // ── Load traps ───────────────────────────────────────────────
  Future<void> _loadTrapsFromServer() async {
    try {
      final data = await ApiService.getUserTraps(UserSession.email);
      if (!mounted) return;
      setState(() {
        _traps = data;
        isLoadingTraps = false;
        for (final t in _traps) {
          _onlineMap.putIfAbsent(t.trapId, () => false);
        }
      });
      _startOnlineTimer();
      await _refreshOnlineStatus();
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoadingTraps = false);
    }
  }

  void _startOnlineTimer() {
    _onlineTimer?.cancel();
    _onlineTimer = Timer.periodic(
      const Duration(seconds: 3),
          (_) => _refreshOnlineStatus(),
    );
  }

  Future<void> _refreshOnlineStatus() async {
    if (_checkingOnline || _traps.isEmpty) return;
    _checkingOnline = true;
    try {
      final Map<String, bool> latest = {};
      for (final trap in _traps) {
        final online = await _pingTrapHealth(_getTrapHost(trap));
        latest[trap.trapId] = online;
      }
      if (!mounted) return;
      setState(() => latest.forEach((id, v) => _onlineMap[id] = v));
    } finally {
      _checkingOnline = false;
    }
  }

  Future<bool> _pingTrapHealth(String? host) async {
    if (host == null || host.trim().isEmpty) return false;
    try {
      final res = await http
          .get(Uri.parse("http://$host:8000/health"))
          .timeout(const Duration(seconds: 2));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Recent events polling ────────────────────────────────────
  Future<void> _loadRecentEvents() async {
    try {
      final events = await _eventService.fetchEvents(limit: 5);
      if (!mounted) return;
      setState(() {
        _recentEvents = events;
        if (events.isNotEmpty) _lastKnownSerialNo = events.first.serialNo;
      });
    } catch (_) {}
  }

  void _startEventPolling() {
    _eventTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      try {
        final events = await _eventService.fetchEvents(limit: 5);
        if (!mounted) return;
        if (events.isNotEmpty && events.first.serialNo > _lastKnownSerialNo) {
          setState(() {
            _recentEvents = events;
            _lastKnownSerialNo = events.first.serialNo;
          });
        }
      } catch (_) {}
    });
  }

  // ── Back press ───────────────────────────────────────────────
  Future<bool> _onWillPop() async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Close App'),
        content: const Text('Do you want to close the App?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => SystemNavigator.pop(),
            child: const Text('Yes'),
          ),
        ],
      ),
    ) ??
        false;
  }

  void _confirmDeleteTrap(int index) {
    final trap = _traps[index];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Trap'),
        content: Text('Do you want to delete "${trap.trapName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ApiService.deleteTrap(trap.trapId);
              await _loadTrapsFromServer();
              setState(() {
                if (_currentTrapIndex >= _traps.length) _currentTrapIndex = 0;
              });
            },
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ── BUILD ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: const Color(0xFF0B2A4A),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () async => await _onWillPop(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.history, color: Colors.white),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const TrappedHistoryScreen()),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.person, color: Colors.white),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserProfileScreen(
                          fullName: UserSession.fullName,
                          email: UserSession.email,
                        ),
                      ),
                    );
                    setState(() {});
                  },
                ),
              ],
            ),
            body: isLoadingTraps
                ? const Center(child: CircularProgressIndicator())
                : _buildBody(),
            floatingActionButton: FloatingActionButton(
              backgroundColor: const Color(0xFF3B5CCC),
              tooltip: 'Add trap',
              child: const Icon(Icons.add, color: Colors.white),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TrapRegistrationScreen()),
                );
                _loadTrapsFromServer();
              },
            ),
          ),
          if (isLoadingLive)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // ── Welcome ──────────────────────────────────────────
          Center(
            child: Column(
              children: [
                Text(
                  'Welcome ${UserSession.displayName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Let\'s manage your traps efficiently',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── My Devices ───────────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Devices',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 130, // ← compact height
                  child: _traps.isEmpty
                      ? const Center(
                    child: Text(
                      'No traps added yet',
                      style: TextStyle(color: Colors.black54),
                    ),
                  )
                      : PageView.builder(
                    controller: _pageController,
                    itemCount: _traps.length,
                    onPageChanged: (i) =>
                        setState(() => _currentTrapIndex = i),
                    itemBuilder: (_, index) {
                      final trap = _traps[index];
                      return GestureDetector(
                        onLongPress: () => _confirmDeleteTrap(index),
                        child: _trapCard(trap),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Recent Trap Notifications ─────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Detections',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _recentEvents.isEmpty
                    ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'No recent detections',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                )
                    : Column(
                  children: _recentEvents
                      .take(5)
                      .map((e) => _notificationCard(e))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Compact trap card ────────────────────────────────────────
  Widget _trapCard(TrapModel trap) {
    final online = _onlineMap[trap.trapId] ?? false;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Left: trap info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  trap.trapName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${trap.trapId}',
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 4,
                      backgroundColor: online ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      online ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: online ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Right: Watch Live button
          SizedBox(
            width: 130,
            height: 42,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: online
                    ? const Color(0xFF3B5CCC)
                    : Colors.grey.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              onPressed: online
                  ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WatchLiveScreen(
                      trapId: trap.trapId,
                      trapName: trap.trapName,
                      rtspUrl: "rtsp://10.153.9.18:8554/live",
                    ),
                  ),
                );
              }
                  : null,
              child: Text(
                online ? 'WATCH LIVE' : 'OFFLINE',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


// ── Notification card ────────────────────────────────────────
  Widget _notificationCard(TrapEvent event) {
    final color = _confidenceColor(event.confidenceScore);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const TrappedHistoryScreen(),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 54,
                height: 54,
                child: event.fullImageUrl != null
                    ? Image.network(
                  event.fullImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _imgPlaceholder(),
                )
                    : _imgPlaceholder(),
              ),
            ),
            const SizedBox(width: 10),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.pets, size: 14, color: Colors.black54),
                      const SizedBox(width: 4),
                      Text(
                        event.animalName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          event.confidencePercent,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    event.trapId,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    event.formattedDate,
                    style: const TextStyle(color: Colors.black45, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
    color: Colors.grey.shade200,
    child: const Icon(Icons.pets, color: Colors.white70, size: 24),
  );

  Color _confidenceColor(double c) {
    if (c >= 0.80) return Colors.green.shade600;
    if (c >= 0.65) return Colors.orange.shade600;
    return Colors.red.shade400;
  }
}