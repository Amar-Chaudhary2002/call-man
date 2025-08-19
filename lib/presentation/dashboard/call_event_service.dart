// lib/presentation/dashboard/call_event_service.dart
import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_state/phone_state.dart';
// import 'package:device_info_plus/device_info_plus.dart';

class CallEventService {
  static CallEventService? _instance;
  static CallEventService get instance => _instance ??= CallEventService._();
  CallEventService._();

  StreamSubscription<PhoneState>? _subscription;
  Timer? _debounceTimer;
  PhoneState? _lastState;
  DateTime? _lastEventTime;
  bool _isInitialized = false;

  // Navigation key for showing dialogs
  static GlobalKey<NavigatorState>? navigatorKey;

  // Track call start time for duration calculation
  DateTime? _callStartTime;

  // Debounce duration to prevent multiple rapid events
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  // Set the navigator key from main app
  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    navigatorKey = key;
  }

  Future<void> init() async {
    if (_isInitialized) {
      log("CallEventService already initialized");
      return;
    }

    log("Initializing CallEventService...");

    if (!Platform.isAndroid) {
      log("Not Android platform, skipping initialization");
      return;
    }

    final phoneGranted = await Permission.phone.isGranted;
    if (!phoneGranted) {
      log("Phone permission not granted");
      await _showFallbackDialog(
        "Permission Error",
        "Phone permission not granted. Please enable it in settings.",
      );
      return;
    }

    // Cancel any existing subscription
    await dispose();

    try {
      _subscription = PhoneState.stream.listen(
        _handlePhoneStateChange,
        onError: (error) {
          log("Error in phone state stream: $error");
          _showFallbackDialog(
            "Call Detection Error",
            "Error monitoring phone state: $error",
          );
        },
        cancelOnError: false,
      );

      _isInitialized = true;
      log("✅ CallEventService initialized successfully");
      await _showFallbackDialog("Success", "Call monitoring is now active!");
    } catch (e) {
      log("❌ Failed to initialize CallEventService: $e");
      await _showFallbackDialog(
        "Initialization Error",
        "Failed to start call monitoring: $e",
      );
    }
  }

  void _handlePhoneStateChange(PhoneState event) async {
    log("📞 Raw phone state: ${event.status} - Number: ${event.number}");

    // Debounce rapid successive events
    final now = DateTime.now();
    if (_lastEventTime != null &&
        now.difference(_lastEventTime!).inMilliseconds < 100 &&
        _lastState?.status == event.status &&
        _lastState?.number == event.number) {
      log("⏭️ Skipping duplicate event");
      return;
    }

    _lastState = event;
    _lastEventTime = now;

    // Cancel previous debounce timer
    _debounceTimer?.cancel();

    // Debounce the event processing
    _debounceTimer = Timer(_debounceDuration, () async {
      await _processPhoneStateChange(event);
    });
  }

  Future<void> _processPhoneStateChange(PhoneState event) async {
    log("🔄 Processing phone state: ${event.status} - Number: ${event.number}");

    try {
      switch (event.status) {
        case PhoneStateStatus.CALL_INCOMING:
          await _handleIncomingCall(event);
          break;

        // case PhoneStateStatus.CALL_STARTED:
        //   await _handleCallStarted(event);
        //   break;

        case PhoneStateStatus.CALL_ENDED:
          await _handleCallEnded(event);
          break;

        default:
          await _closeOverlay();
          break;
      }
    } catch (e) {
      log("❌ Error processing phone state change: $e");
      await _showFallbackDialog(
        "Call Processing Error",
        "Error handling call state: $e",
      );
    }
  }

  Future<void> _handleIncomingCall(PhoneState event) async {
    final title = 'Incoming Call';
    final subtitle = 'From: ${_formatPhoneNumber(event.number)}';

    log("📞 Incoming call detected");

    // Try overlay first, then fallback to dialog
    final overlayShown = await _showOverlay(title, subtitle, 'ringing');
    if (!overlayShown) {
      await _showFallbackDialog(title, subtitle);
    }
  }

  // Future<void> _handleCallStarted(PhoneState event) async {
  //   _callStartTime = DateTime.now();
  //   final title = 'Call Active';
  //   final subtitle = 'With: ${_formatPhoneNumber(event.number)}';

  //   log("📞 Call started");

  //   // Try overlay first, then fallback to dialog
  //   final overlayShown = await _showOverlay(title, subtitle, 'active');
  //   if (!overlayShown) {
  //     await _showFallbackDialog(title, subtitle);
  //   }
  // }

  Future<void> _handleCallEnded(PhoneState event) async {
    final duration = _calculateCallDuration();
    final title = 'Call Ended';
    final subtitle =
        'Duration: $duration\nWith: ${_formatPhoneNumber(event.number)}';

    log("📞 Call ended");

    // Try overlay first, then fallback to dialog
    final overlayShown = await _showOverlay(title, subtitle, 'ended');
    if (!overlayShown) {
      await _showFallbackDialog(title, subtitle, autoClose: true);
    } else {
      // Auto-hide call ended overlay after 5 seconds
      Timer(const Duration(seconds: 5), () {
        _closeOverlay();
      });
    }

    _callStartTime = null;
  }

  String _formatPhoneNumber(String? number) {
    if (number == null || number.isEmpty) {
      return 'Unknown';
    }
    return number;
  }

  String _calculateCallDuration() {
    if (_callStartTime == null) return "Unknown duration";

    final duration = DateTime.now().difference(_callStartTime!);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return "${minutes}m ${seconds}s";
  }

  static Future<bool> _checkOverlayPermission() async {
    try {
      final hasPermission = await FlutterOverlayWindow.isPermissionGranted();
      log("Current overlay permission status: $hasPermission");

      if (!hasPermission) {
        log("⚠️ Requesting overlay permission...");
        final granted = await FlutterOverlayWindow.requestPermission();
        log("Overlay permission after request: $granted");
        return granted == true;
      }
      return true;
    } catch (e) {
      log("Error checking overlay permission: $e");
      return false;
    }
  }

  Future<bool> _showOverlay(
    String title,
    String subtitle,
    String callState,
  ) async {
    log("🔔 Attempting to show overlay: $title - $subtitle");

    try {
      // Check overlay permission first
      final hasPermission = await _checkOverlayPermission();
      if (!hasPermission) {
        log("❌ Overlay permission denied, cannot show overlay");
        return false;
      }

      // Close any existing overlay
      if (await FlutterOverlayWindow.isActive()) {
        log("🔄 Closing existing overlay");
        await FlutterOverlayWindow.closeOverlay();
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Get overlay configuration
      final config = _getOverlayConfig(callState);

      log("🎨 Showing overlay with config: $config");

      // Show the overlay
      final success = await FlutterOverlayWindow.showOverlay(
        enableDrag: config['enableDrag'] ?? true,
        height: config['height'] ?? 200,
        width: WindowSize.matchParent,
        alignment: config['alignment'] ?? OverlayAlignment.topCenter,
        overlayTitle: title,
        overlayContent: subtitle,
        flag: config['flag'] ?? OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.auto,
      );

      log("Overlay show result: sucess");

      // Wait for overlay to initialize
      await Future.delayed(const Duration(milliseconds: 500));

      // Check if overlay is actually active
      final isActive = await FlutterOverlayWindow.isActive();
      log("Overlay active status after show: $isActive");

      if (isActive) {
        // Send data to overlay
        await FlutterOverlayWindow.shareData({
          'title': title,
          'subtitle': subtitle,
          'callState': callState,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'phoneNumber': _formatPhoneNumber(_lastState?.number),
        });

        log("✅ Overlay shown successfully and data shared: $callState");
        return true;
      } else {
        log("⚠️ Overlay not active after show attempt");
        return false;
      }
    } catch (e) {
      log("❌ Error showing overlay: $e");
      return false;
    }
  }

  Map<String, dynamic> _getOverlayConfig(String callState) {
    switch (callState) {
      case 'ringing':
        return {
          'enableDrag': true,
          'height': 280,
          'alignment': OverlayAlignment.topCenter,
          'flag': OverlayFlag.defaultFlag,
        };
      case 'active':
        return {
          'enableDrag': true,
          'height': 220,
          'alignment': OverlayAlignment.centerRight,
          'flag': OverlayFlag.defaultFlag,
        };
      case 'ended':
        return {
          'enableDrag': false,
          'height': 250,
          'alignment': OverlayAlignment.center,
          'flag': OverlayFlag.focusPointer,
        };
      default:
        return {
          'enableDrag': true,
          'height': 200,
          'alignment': OverlayAlignment.topCenter,
          'flag': OverlayFlag.defaultFlag,
        };
    }
  }

  // Fallback dialog method
  Future<void> _showFallbackDialog(
    String title,
    String message, {
    bool autoClose = false,
  }) async {
    if (navigatorKey?.currentContext == null) {
      log("❌ No navigation context available for dialog");
      return;
    }

    log("💬 Showing fallback dialog: $title - $message");

    try {
      showDialog(
        context: navigatorKey!.currentContext!,
        barrierDismissible: true,
        builder: (BuildContext context) {
          // Auto close dialog if specified
          if (autoClose) {
            Timer(const Duration(seconds: 3), () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            });
          }

          return AlertDialog(
            title: Row(
              children: [
                Icon(_getIconForTitle(title), color: _getColorForTitle(title)),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 18)),
              ],
            ),
            content: Text(message),
            actions: [
              if (!autoClose)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              if (title.contains('Call') && !title.contains('Error'))
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    testOverlay(); // Test overlay again
                  },
                  child: const Text('Test Overlay'),
                ),
            ],
          );
        },
      );
    } catch (e) {
      log("❌ Error showing dialog: $e");
    }
  }

  IconData _getIconForTitle(String title) {
    if (title.contains('Incoming')) return Icons.phone_in_talk;
    if (title.contains('Active')) return Icons.phone;
    if (title.contains('Ended')) return Icons.phone_disabled;
    if (title.contains('Error')) return Icons.error;
    if (title.contains('Success')) return Icons.check_circle;
    return Icons.info;
  }

  Color _getColorForTitle(String title) {
    if (title.contains('Incoming')) return Colors.blue;
    if (title.contains('Active')) return Colors.green;
    if (title.contains('Ended')) return Colors.orange;
    if (title.contains('Error')) return Colors.red;
    if (title.contains('Success')) return Colors.green;
    return Colors.grey;
  }

  Future<void> _closeOverlay() async {
    try {
      if (await FlutterOverlayWindow.isActive()) {
        await FlutterOverlayWindow.closeOverlay();
        log("🔴 Overlay closed");
      }
    } catch (e) {
      log("Error closing overlay: $e");
    }
  }

  // Public method to test overlay manually
  Future<void> testOverlay() async {
    log("🧪 Testing overlay manually...");
    final overlayShown = await _showOverlay(
      "Test Overlay",
      "This is a test overlay",
      "test",
    );
    if (!overlayShown) {
      await _showFallbackDialog(
        "Test Result",
        "Overlay failed to show. This dialog confirms call detection is working!",
      );
    }
  }

  Future<void> dispose() async {
    log("🧹 Disposing CallEventService...");

    _debounceTimer?.cancel();
    _debounceTimer = null;

    await _subscription?.cancel();
    _subscription = null;

    _lastState = null;
    _lastEventTime = null;
    _callStartTime = null;
    _isInitialized = false;

    await _closeOverlay();
    log("✅ CallEventService disposed");
  }

  bool get isInitialized => _isInitialized;

  // Debug method to check current status
  Future<Map<String, dynamic>> getDebugInfo() async {
    return {
      'isInitialized': _isInitialized,
      'hasPhonePermission': await Permission.phone.isGranted,
      'hasOverlayPermission': await FlutterOverlayWindow.isPermissionGranted(),
      'isOverlayActive': await FlutterOverlayWindow.isActive(),
      'lastState': _lastState?.status.toString(),
      'lastEventTime': _lastEventTime?.toString(),
    };
  }
}
