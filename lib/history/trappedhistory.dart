import 'package:flutter/material.dart';

class TrappedHistoryScreen extends StatefulWidget {
  const TrappedHistoryScreen({super.key});

  @override
  State<TrappedHistoryScreen> createState() => _TrappedHistoryScreenState();
}

class _TrappedHistoryScreenState extends State<TrappedHistoryScreen> {
  /// TEMP SAMPLE DATA (Replace with real backend / notifications later)
  final List<Map<String, String>> trappedHistory = [
    {
      'animal': 'Monkey',
      'date': '28.02.2025  4.35 pm',
      'trapId': 'TRAP_01',
      'image': '', // future image url or asset
    },
    {
      'animal': 'Monkey',
      'date': '28.02.2025  4.35 pm',
      'trapId': 'TRAP_01',
      'image': '',
    },
    {
      'animal': 'Monkey',
      'date': '28.02.2025  4.35 pm',
      'trapId': 'TRAP_01',
      'image': '',
    },
    {
      'animal': 'Monkey',
      'date': '28.02.2025  4.35 pm',
      'trapId': 'TRAP_01',
      'image': '',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B2A4A),

      /// APP BAR
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Trapped History',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),

      body: trappedHistory.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
        itemCount: trappedHistory.length,
        itemBuilder: (context, index) {
          final item = trappedHistory[index];
          return _buildHistoryCard(item);
        },
      ),
    );
  }

  /// EMPTY STATE
  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'No history to show',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 16,
        ),
      ),
    );
  }

  /// HISTORY CARD UI
  Widget _buildHistoryCard(Map<String, String> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          /// IMAGE PLACEHOLDER
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.image,
              color: Colors.white70,
            ),
          ),

          const SizedBox(width: 12),

          /// DETAILS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Animal : ${item['animal']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Date : ${item['date']}',
                  style: const TextStyle(
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Trap ID : ${item['trapId']}',
                  style: const TextStyle(
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
