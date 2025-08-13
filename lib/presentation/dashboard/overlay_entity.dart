import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

@pragma('vm:entry-point')
void overlayMain() {
  log('🚀 Overlay main started');
  FlutterError.onError = (details) {
    log('❌ Overlay error: ${details.exception}');
  };
  runApp(const _OverlayApp());
}

class _OverlayApp extends StatelessWidget {
  const _OverlayApp();
  @override
  Widget build(BuildContext context) {
    log('📱 Building overlay app');
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const _OverlayPage(),
    );
  }
}

class _OverlayPage extends StatefulWidget {
  const _OverlayPage();

  @override
  State<_OverlayPage> createState() => _OverlayPageState();
}

class _OverlayPageState extends State<_OverlayPage>
    with SingleTickerProviderStateMixin {
  String title = 'Call';
  String subtitle = 'Loading...';
  String callState = 'unknown';
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    log('🎨 Initializing overlay UI');
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();
    // Listen for data from main app
    FlutterOverlayWindow.overlayListener.listen((data) {
      log('📡 Overlay received data: $data');
      if (data is Map && mounted) {
        setState(() {
          title = data['title']?.toString() ?? title;
          subtitle = data['subtitle']?.toString() ?? subtitle;
          callState = data['callState']?.toString() ?? callState;
        });
        log('✅ UI updated - Title: $title, State: $callState');
      }
    });
    log('👂 Overlay listener set up successfully');
  }

  @override
  void dispose() {
    log('🗑️ Disposing overlay');
    _animationController.dispose();
    super.dispose();
  }

  Color _getStateColor() {
    switch (callState.toLowerCase()) {
      case 'ringing':
        return Colors.blue;
      case 'active':
        return Colors.green;
      case 'dialing':
        return Colors.orange;
      case 'disconnected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStateIcon() {
    switch (callState.toLowerCase()) {
      case 'ringing':
        return Icons.phone_in_talk;
      case 'active':
        return Icons.phone;
      case 'dialing':
        return Icons.phone_callback;
      case 'disconnected':
        return Icons.phone_disabled;
      default:
        return Icons.phone;
    }
  }

  @override
  Widget build(BuildContext context) {
    log('🔄 Building overlay UI - State: $callState');

    return Scaffold(
      backgroundColor: Colors.black26,
      body: Center(
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                constraints: const BoxConstraints(
                  maxWidth: 320,
                  minHeight: 150,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                  ],
                  border: Border.all(color: _getStateColor(), width: 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Status icon
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _getStateColor(),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getStateIcon(),
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton.icon(
                          onPressed: () async {
                            log('🚫 Overlay dismissed');
                            try {
                              await FlutterOverlayWindow.closeOverlay();
                            } catch (e) {
                              log('❌ Error closing overlay: $e');
                            }
                          },
                          icon: const Icon(Icons.close, color: Colors.white70),
                          label: const Text(
                            'Close',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            log('📱 Opening main app');
                            try {
                              await FlutterOverlayWindow.closeOverlay();
                            } catch (e) {
                              log('❌ Error closing overlay: $e');
                            }
                          },
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Open'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _getStateColor(),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
