import 'package:flutter/material.dart';

class WatchLiveScreen extends StatefulWidget {
  final String trapName;
  final String trapId;
  final bool isActive;

  const WatchLiveScreen({
    super.key,
    required this.trapName,
    required this.trapId,
    required this.isActive,
  });

  @override
  State<WatchLiveScreen> createState() => _WatchLiveScreenState();
}

class _WatchLiveScreenState extends State<WatchLiveScreen> {
  bool isDoorOpen = false; // door state

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
          'Live Update',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),

            /// TRAP NAME + STATUS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.trapName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${widget.trapId}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),

                  /// ACTIVE / INACTIVE
                  Row(
                    children: [
                      Text(
                        widget.isActive ? 'Active' : 'In Active',
                        style: TextStyle(
                          color: widget.isActive
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.circle,
                        size: 10,
                        color: widget.isActive
                            ? Colors.green
                            : Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// CAMERA VIEW PLACEHOLDER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black),
                ),
                child: Stack(
                  children: [
                    /// 1080P LABEL
                    const Positioned(
                      top: 8,
                      left: 8,
                      child: Text(
                        '1080P',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    /// RECORD DOT
                    const Positioned(
                      top: 8,
                      right: 8,
                      child: Icon(
                        Icons.circle,
                        color: Colors.red,
                        size: 10,
                      ),
                    ),

                    /// CENTER FOCUS
                    const Center(
                      child: Icon(
                        Icons.center_focus_strong,
                        size: 40,
                        color: Colors.black54,
                      ),
                    ),

                    /// TIME CODE
                    const Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          '00:55:26:30',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            /// OPEN DOOR BUTTON
            SizedBox(
              width: 300,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canOpenDoor()
                      ? const Color(0xFF3B5CCC)
                      : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                onPressed: _canOpenDoor()
                    ? () {
                  setState(() {
                    isDoorOpen = true;
                  });
                }
                    : null,
                child: const Text(
                  'Open the Door',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// CLOSE DOOR BUTTON
            SizedBox(
              width: 300,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canCloseDoor()
                      ? const Color(0xFF3B5CCC)
                      : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                onPressed: _canCloseDoor()
                    ? () {
                  setState(() {
                    isDoorOpen = false;
                  });
                }
                    : null,
                child: const Text(
                  'Close the Door',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// LOGIC HELPERS

  bool _canOpenDoor() {
    return widget.isActive && !isDoorOpen;
  }

  bool _canCloseDoor() {
    return widget.isActive && isDoorOpen;
  }
}
