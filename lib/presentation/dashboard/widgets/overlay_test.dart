// lib/presentation/dashboard/widgets/overlay_test_widget.dart
import 'package:flutter/material.dart';
import 'dart:developer' as dev;

import 'overlay_manager.dart';

class OverlayTestWidget extends StatefulWidget {
  const OverlayTestWidget({super.key});

  @override
  State<OverlayTestWidget> createState() => _OverlayTestWidgetState();
}

class _OverlayTestWidgetState extends State<OverlayTestWidget> {
  final CallOverlayManager _overlayManager = CallOverlayManager();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeOverlay();
  }

  Future<void> _initializeOverlay() async {
    try {
      final success = await _overlayManager.initialize();
      setState(() {
        _isInitialized = success;
      });
      dev.log('Overlay manager initialized: $success');
    } catch (e) {
      dev.log('Error initializing overlay manager: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.near_me_outlined,
                  color: _isInitialized ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Overlay Test Panel',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _isInitialized
                  ? '✅ Overlay system ready'
                  : '❌ Overlay system not ready',
              style: TextStyle(
                color: _isInitialized ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            if (_isInitialized) ...[
              const Text(
                'Test different overlay types:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _testIncomingCall(),
                    icon: const Icon(Icons.call_received, size: 18),
                    label: const Text('Incoming Call'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _testActiveCall(),
                    icon: const Icon(Icons.call, size: 18),
                    label: const Text('Active Call'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _testCallEnded(),
                    icon: const Icon(Icons.call_end, size: 18),
                    label: const Text('Call Ended'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _testSequence(),
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Test Full Sequence'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _closeOverlay(),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Close'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: _initializeOverlay,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry Initialization'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _testIncomingCall() async {
    try {
      dev.log('🧪 Testing incoming call overlay');
      await _overlayManager.showIncomingCallOverlay('+91 98765 43210');
      _showSnackBar('Incoming call overlay shown', Colors.blue);
    } catch (e) {
      dev.log('❌ Incoming call test failed: $e');
      _showSnackBar('Failed to show incoming call overlay', Colors.red);
    }
  }

  Future<void> _testActiveCall() async {
    try {
      dev.log('🧪 Testing active call overlay');
      await _overlayManager.showActiveCallOverlay('+91 98765 43210');
      _showSnackBar('Active call overlay shown', Colors.green);
    } catch (e) {
      dev.log('❌ Active call test failed: $e');
      _showSnackBar('Failed to show active call overlay', Colors.red);
    }
  }

  Future<void> _testCallEnded() async {
    try {
      dev.log('🧪 Testing call ended overlay');
      await _overlayManager.showCallEndedOverlay('+91 98765 43210', '2m 30s');
      _showSnackBar('Call ended overlay shown', Colors.red);
    } catch (e) {
      dev.log('❌ Call ended test failed: $e');
      _showSnackBar('Failed to show call ended overlay', Colors.red);
    }
  }

  Future<void> _testSequence() async {
    try {
      dev.log('🧪 Testing full call sequence');
      _showSnackBar('Starting full sequence test...', Colors.purple);

      // Incoming call
      await _overlayManager.showIncomingCallOverlay('+91 12345 67890');
      await Future.delayed(const Duration(seconds: 3));

      // Active call
      await _overlayManager.showActiveCallOverlay('+91 12345 67890');
      await Future.delayed(const Duration(seconds: 3));

      // Call ended
      await _overlayManager.showCallEndedOverlay('+91 12345 67890', '0m 6s');

      _showSnackBar('Full sequence test completed', Colors.green);
      dev.log('✅ Full sequence test completed');
    } catch (e) {
      dev.log('❌ Sequence test failed: $e');
      _showSnackBar('Sequence test failed', Colors.red);
    }
  }

  Future<void> _closeOverlay() async {
    try {
      await _overlayManager.closeOverlay();
      _showSnackBar('Overlay closed', Colors.grey);
    } catch (e) {
      dev.log('❌ Failed to close overlay: $e');
      _showSnackBar('Failed to close overlay', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _overlayManager.dispose();
    super.dispose();
  }
}

// Usage: Add this widget to any screen where you want to test overlays
// Example in your dashboard or home screen:
/*
class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dashboard')),
      body: Column(
        children: [
          // Your existing widgets

          // Add the overlay test widget
          OverlayTestWidget(),

          // Your other widgets
        ],
      ),
    );
  }
}
*/