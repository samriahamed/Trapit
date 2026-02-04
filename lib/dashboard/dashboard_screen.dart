import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/trap_model.dart';
import '../history/trappedhistory.dart';
import '../profile/userprofile.dart';
import '../live/watch_live.dart';
import '../dashboard/trap_registration_screen.dart';
import '../session/user_session.dart';
import '../services/api_service.dart';

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

  /// ✅ DASHBOARD-OWNED TRAPS
  List<TrapModel> _traps = [];

  @override
  void initState() {
    super.initState();
    _loadTrapsFromServer();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// 🌐 LOAD TRAPS FROM BACKEND
  Future<void> _loadTrapsFromServer() async {
    try {
      final data = await ApiService.getUserTraps(UserSession.email);
      setState(() {
        _traps = data;
        isLoadingTraps = false;
      });
    } catch (e) {
      setState(() => isLoadingTraps = false);
    }
  }

  /// BACK BUTTON CONFIRMATION
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

  /// 🗑️ DELETE TRAP
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
                if (_currentTrapIndex >= _traps.length) {
                  _currentTrapIndex = 0;
                }
              });
            },
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: const Color(0xFF0B2A4A),

            /// APP BAR
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TrappedHistoryScreen(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.person, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserProfileScreen(
                          fullName: UserSession.fullName,
                          email: UserSession.email,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),

            body: isLoadingTraps
                ? const Center(child: CircularProgressIndicator())
                : _buildBody(),

            floatingActionButton: FloatingActionButton(
              backgroundColor: const Color(0xFF3B5CCC),
              child: const Icon(Icons.add),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TrapRegistrationScreen(),
                  ),
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

  /// ================= UI BODY =================
  Widget _buildBody() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),

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
            'Let’s manage your traps efficiently',
            style: TextStyle(color: Colors.white70),
          ),

          const SizedBox(height: 24),

          /// MY DEVICES
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
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
                const SizedBox(height: 14),

                SizedBox(
                  height: 190,
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

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _trapCard(TrapModel trap) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(trap.trapName, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text('ID: ${trap.trapId}', style: const TextStyle(color: Colors.black54)),
          const Spacer(),
          Switch(
            value: trap.isActive,
            onChanged: (v) async {
              setState(() => trap.isActive = v);
              await ApiService.updateTrapStatus(
                trapId: trap.trapId,
                isActive: v,
              );
            },
          ),
        ],
      ),
    );
  }
}
