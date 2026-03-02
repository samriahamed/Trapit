// lib/screens/trapped_history_screen.dart
//
// Trapped History screen — loads real events from Node.js backend,
// shows captured images from Pi, and triggers local notifications
// when new events arrive while the screen is open.

import 'package:flutter/material.dart';
import '../services/trap_event_service.dart';
import '../services/notification_service.dart';

class TrappedHistoryScreen extends StatefulWidget {
  const TrappedHistoryScreen({super.key});

  @override
  State<TrappedHistoryScreen> createState() => _TrappedHistoryScreenState();
}

class _TrappedHistoryScreenState extends State<TrappedHistoryScreen>
    with WidgetsBindingObserver {

  final TrapEventService    _service = TrapEventService();
  final NotificationService _notifs  = NotificationService();

  List<TrapEvent> _events  = [];
  bool  _loading           = true;
  bool  _hasError          = false;
  String _errorMessage     = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadEvents();
    _notifs.startPolling();   // starts checking for new trap events every 10s
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notifs.stopPolling();
    super.dispose();
  }

  // Resume polling when app comes back to foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadEvents();
      _notifs.startPolling();
    } else if (state == AppLifecycleState.paused) {
      _notifs.stopPolling();
    }
  }

  Future<void> _loadEvents() async {
    if (!mounted) return;
    setState(() { _loading = true; _hasError = false; });

    try {
      final events = await _service.fetchEvents(limit: 50);
      if (mounted) {
        setState(() {
          _events  = events;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading      = false;
          _hasError     = true;
          _errorMessage = 'Could not reach server. Check your connection.';
        });
      }
    }
  }

  // NEW — Proper delete handler
  Future<void> _deleteEvent(int index) async {
    final event = _events[index];

    final success = await _service.deleteEvent(event.serialNo);

    if (success) {
      setState(() {
        _events.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event deleted successfully')),
      );
    } else {
      _loadEvents();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete event')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B2A4A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Trapped History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadEvents,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_events.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      color: const Color(0xFF0B2A4A),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        itemCount: _events.length,
        itemBuilder: (context, index) {
          final event = _events[index];

          return Dismissible(
            key: Key(event.serialNo.toString()),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (direction) {
              _deleteEvent(index);   // 🔥 UPDATED — call new handler
            },
            child: _buildHistoryCard(event),
          );
        },
      ),
    );
  }

  // ── Empty state ─────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, color: Colors.white24, size: 64),
          const SizedBox(height: 16),
          const Text(
            'No trapped animals yet',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Events will appear here once the trap is triggered',
            style: TextStyle(color: Colors.white38, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Error state ──────────────────────────────────────────────
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, color: Colors.white38, size: 64),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            style: const TextStyle(color: Colors.white70, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadEvents,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0B2A4A),
            ),
          ),
        ],
      ),
    );
  }

  // ── History card ─────────────────────────────────────────────
  Widget _buildHistoryCard(TrapEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Captured image ──────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 70,
              height: 70,
              child: event.fullImageUrl != null
                  ? Image.network(
                event.fullImageUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (ctx, child, progress) =>
                progress == null
                    ? child
                    : Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorBuilder: (ctx, err, stack) => _imagePlaceholder(),
              )
                  : _imagePlaceholder(),
            ),
          ),
          const SizedBox(width: 12),

          // ── Event details ───────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Animal : ${event.animalName}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Date : ${event.formattedDate}',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'Trap ID : ${event.trapId}',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 4),
                // Confidence badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _confidenceColor(event.confidenceScore),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Confidence: ${event.confidencePercent}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 70,
      height: 70,
      color: Colors.grey.shade300,
      child: const Icon(Icons.pets, color: Colors.white70, size: 32),
    );
  }

  // Green for high confidence, orange for medium, red for low
  Color _confidenceColor(double confidence) {
    if (confidence >= 0.80) return Colors.green.shade600;
    if (confidence >= 0.65) return Colors.orange.shade600;
    return Colors.red.shade400;
  }
}