// lib/presentation/dashboard/call_overlay_manager.dart
import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';

class CallOverlayManager {
  static final CallOverlayManager _instance = CallOverlayManager._internal();
  factory CallOverlayManager() => _instance;
  CallOverlayManager._internal();

  bool _isInitialized = false;
  bool _isOverlayActive = false;
  Timer? _autoCloseTimer;

  /// Initialize overlay manager with proper permissions
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Check and request overlay permission
      final hasOverlayPermission = await _ensureOverlayPermission();
      if (!hasOverlayPermission) {
        dev.log('❌ Overlay permission not granted');
        return false;
      }

      _isInitialized = true;
      dev.log('✅ CallOverlayManager initialized');
      return true;
    } catch (e) {
      dev.log('❌ Failed to initialize CallOverlayManager: $e');
      return false;
    }
  }

  /// Ensure overlay permission is granted
  Future<bool> _ensureOverlayPermission() async {
    try {
      bool hasPermission = await FlutterOverlayWindow.isPermissionGranted();

      if (!hasPermission) {
        dev.log('🔐 Requesting overlay permission...');
        hasPermission = await FlutterOverlayWindow.requestPermission() ?? false;
      }

      dev.log('Overlay permission status: $hasPermission');
      return hasPermission;
    } catch (e) {
      dev.log('Error checking overlay permission: $e');
      return false;
    }
  }

  /// Show overlay for incoming call
  Future<void> showIncomingCallOverlay(String phoneNumber) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _closeExistingOverlay();

      dev.log('📞 Showing incoming call overlay for: $phoneNumber');

      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        overlayTitle: "Incoming Call",
        overlayContent: "From: $phoneNumber",
        flag: OverlayFlag.defaultFlag,
        alignment: OverlayAlignment.topCenter,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.auto,
        height: 200,
        width: WindowSize.fullCover,
      );

      // Wait for overlay to be ready
      await Future.delayed(const Duration(milliseconds: 500));

      await FlutterOverlayWindow.shareData({
        'type': 'incoming_call',
        'title': '📞 Incoming Call',
        'subtitle': 'From: $phoneNumber',
        'phoneNumber': phoneNumber,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'backgroundColor': '#2563eb', // Blue for incoming
      });

      _isOverlayActive = true;
      _setAutoCloseTimer(30); // Auto-close after 30 seconds

      dev.log('✅ Incoming call overlay displayed');
    } catch (e) {
      dev.log('❌ Failed to show incoming call overlay: $e');
    }
  }

  /// Show overlay for active call
  Future<void> showActiveCallOverlay(String phoneNumber) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _closeExistingOverlay();

      dev.log('📞 Showing active call overlay for: $phoneNumber');

      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        overlayTitle: "Call Active",
        overlayContent: "With: $phoneNumber",
        flag: OverlayFlag.defaultFlag,
        alignment: OverlayAlignment.topCenter,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.auto,
        height: 180,
        width: WindowSize.fullCover,
      );

      await Future.delayed(const Duration(milliseconds: 500));

      await FlutterOverlayWindow.shareData({
        'type': 'active_call',
        'title': '📞 Call Active',
        'subtitle': 'With: $phoneNumber',
        'phoneNumber': phoneNumber,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'backgroundColor': '#16a34a', // Green for active
      });

      _isOverlayActive = true;
      _cancelAutoCloseTimer(); // Don't auto-close active calls

      dev.log('✅ Active call overlay displayed');
    } catch (e) {
      dev.log('❌ Failed to show active call overlay: $e');
    }
  }

  /// Show overlay for call ended
  Future<void> showCallEndedOverlay(String phoneNumber, String duration) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _closeExistingOverlay();

      dev.log('📞 Showing call ended overlay for: $phoneNumber');

      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        overlayTitle: "Call Ended",
        overlayContent: "Duration: $duration",
        flag: OverlayFlag.defaultFlag,
        alignment: OverlayAlignment.center,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.auto,
        height: 250,
        width: WindowSize.fullCover,
      );

      await Future.delayed(const Duration(milliseconds: 500));

      await FlutterOverlayWindow.shareData({
        'type': 'call_ended',
        'title': '📴 Call Ended',
        'subtitle': 'Duration: $duration\nWith: $phoneNumber',
        'phoneNumber': phoneNumber,
        'duration': duration,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'backgroundColor': '#dc2626', // Red for ended
      });

      _isOverlayActive = true;
      _setAutoCloseTimer(10); // Auto-close after 10 seconds

      dev.log('✅ Call ended overlay displayed');
    } catch (e) {
      dev.log('❌ Failed to show call ended overlay: $e');
    }
  }

  /// Close existing overlay if active
  Future<void> _closeExistingOverlay() async {
    try {
      if (await FlutterOverlayWindow.isActive()) {
        await FlutterOverlayWindow.closeOverlay();
        await Future.delayed(const Duration(milliseconds: 300));
      }
      _isOverlayActive = false;
      _cancelAutoCloseTimer();
    } catch (e) {
      dev.log('Error closing existing overlay: $e');
    }
  }

  /// Close overlay manually
  Future<void> closeOverlay() async {
    await _closeExistingOverlay();
    dev.log('🚫 Overlay closed manually');
  }

  /// Set auto-close timer
  void _setAutoCloseTimer(int seconds) {
    _cancelAutoCloseTimer();
    _autoCloseTimer = Timer(Duration(seconds: seconds), () async {
      await closeOverlay();
      dev.log('⏰ Overlay auto-closed after ${seconds}s');
    });
  }

  /// Cancel auto-close timer
  void _cancelAutoCloseTimer() {
    _autoCloseTimer?.cancel();
    _autoCloseTimer = null;
  }

  /// Check if overlay is currently active
  bool get isActive => _isOverlayActive;

  /// Dispose resources
  void dispose() {
    _cancelAutoCloseTimer();
    _isInitialized = false;
    _isOverlayActive = false;
  }
}


@pragma('vm:entry-point')
void overlayMain() {
  runApp(const CallOverlayApp());
}

class CallOverlayApp extends StatelessWidget {
  const CallOverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const CallOverlayWidget(),
    );
  }
}

class CallOverlayWidget extends StatefulWidget {
  const CallOverlayWidget({super.key});

  @override
  State<CallOverlayWidget> createState() => _CallOverlayWidgetState();
}

class _CallOverlayWidgetState extends State<CallOverlayWidget>
    with SingleTickerProviderStateMixin {
  String _type = 'unknown';
  String _title = 'Call';
  String _subtitle = '';
  String _phoneNumber = '';
  String _backgroundColor = '#6b7280';

  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: -100.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();

    // Listen for data updates
    FlutterOverlayWindow.overlayListener.listen((data) {
      debugPrint('📡 Overlay received: $data');
      if (data is Map) {
        setState(() {
          _type = data['type']?.toString() ?? _type;
          _title = data['title']?.toString() ?? _title;
          _subtitle = data['subtitle']?.toString() ?? _subtitle;
          _phoneNumber = data['phoneNumber']?.toString() ?? _phoneNumber;
          _backgroundColor = data['backgroundColor']?.toString() ?? _backgroundColor;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  IconData _getIcon() {
    switch (_type) {
      case 'incoming_call':
        return Icons.call_received;
      case 'active_call':
        return Icons.call;
      case 'call_ended':
        return Icons.call_end;
      default:
        return Icons.phone;
    }
  }

  Color _getBackgroundColor() {
    try {
      return Color(int.parse(_backgroundColor.replaceFirst('#', '0xff')));
    } catch (e) {
      return Colors.grey[800]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Container(
                margin: const EdgeInsets.all(16),
                child: Material(
                  elevation: 16,
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getBackgroundColor().withOpacity(0.95),
                          _getBackgroundColor().withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon with pulse animation
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIcon(),
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Title
                        Text(
                          _title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        // Subtitle
                        if (_subtitle.isNotEmpty)
                          Text(
                            _subtitle,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              height: 1.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        const SizedBox(height: 20),

                        // Action buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (_type == 'call_ended')
                              _buildActionButton(
                                icon: Icons.note_add,
                                label: 'Add Note',
                                onPressed: () {
                                  debugPrint('📝 Add note for $_phoneNumber');
                                  // TODO: Open note-taking interface
                                  _closeOverlay();
                                },
                                isPrimary: false,
                              ),
                            _buildActionButton(
                              icon: Icons.close,
                              label: 'Dismiss',
                              onPressed: _closeOverlay,
                              isPrimary: false,
                            ),
                            _buildActionButton(
                              icon: Icons.open_in_new,
                              label: 'Open App',
                              onPressed: () {
                                debugPrint('📱 Opening main app');
                                // TODO: Implement deep link to main app
                                _closeOverlay();
                              },
                              isPrimary: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary
            ? Colors.white.withOpacity(0.2)
            : Colors.white.withOpacity(0.1),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
          side: BorderSide(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Future<void> _closeOverlay() async {
    try {
      await _animationController.reverse();
      await FlutterOverlayWindow.closeOverlay();
    } catch (e) {
      debugPrint('Error closing overlay: $e');
    }
  }
}

