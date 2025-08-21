// lib/presentation/dashboard/overlay_manager.dart
import 'dart:async';
import 'dart:developer';
import 'dart:isolate';
import 'dart:ui';
import 'package:system_alert_window/system_alert_window.dart';

class OverlayManager {
  static const String _APP_TO_OVERLAY_PORT = 'app_to_overlay_port';
  static const String _OVERLAY_TO_APP_PORT = 'overlay_to_app_port';
  static const String _BG_TO_OVERLAY_PORT = 'bg_to_overlay_port';

  static ReceivePort? _overlayToAppPort;
  static bool _isInitialized = false;
  static bool _overlayActive = false;
  static Timer? _autoCloseTimer;

  // Prevent duplicate overlays
  static String? _lastCallId;
  static DateTime? _lastOverlayTime;
  static Timer? _cooldownTimer;
  static const Duration _cooldownDuration = Duration(seconds: 3);

  /// Initialize overlay manager - call once during app startup
  static void initialize() {
    if (_isInitialized) return;

    try {
      // Set up port for receiving messages from overlay
      _overlayToAppPort = ReceivePort();
      IsolateNameServer.removePortNameMapping(_OVERLAY_TO_APP_PORT);
      IsolateNameServer.registerPortWithName(_overlayToAppPort!.sendPort, _OVERLAY_TO_APP_PORT);

      // Listen for overlay messages
      _overlayToAppPort!.listen((message) {
        log('📨 Received message from overlay: $message');
        _handleOverlayMessage(message);
      });

      _isInitialized = true;
      log('✅ OverlayManager initialized');
    } catch (e) {
      log('❌ Failed to initialize OverlayManager: $e');
    }
  }

  /// Handle messages from overlay
  static void _handleOverlayMessage(dynamic message) {
    if (message is Map) {
      final action = message['action']?.toString();
      final callId = message['callId']?.toString();

      switch (action) {
        case 'overlay_closed_by_user':
          _autoCloseTimer?.cancel();
          _overlayActive = false;
          _lastCallId = null;
          log('📱 Overlay closed by user for call: $callId');
          break;

        case 'open_call_interaction':
          final phoneNumber = message['phoneNumber']?.toString() ?? '';
          final callState = message['callState']?.toString() ?? '';
          log('📱 Opening call interaction for: $phoneNumber ($callState)');
          _handleOpenCallInteraction(phoneNumber, callState, callId ?? '');
          break;

        default:
          log('❓ Unknown overlay message action: $action');
      }
    }
  }

  /// Handle opening call interaction screen
  static void _handleOpenCallInteraction(String phoneNumber, String callState, String callId) {
    // Implement your call interaction screen navigation here
    log('🚀 Should open call interaction screen for $phoneNumber');
    // Example: Get.toNamed('/call-interaction', arguments: {...});
  }

  /// Set up ports for background service communication
  static void setupBackgroundPorts() {
    try {
      final bgPort = ReceivePort();
      IsolateNameServer.removePortNameMapping(_BG_TO_OVERLAY_PORT);
      IsolateNameServer.registerPortWithName(bgPort.sendPort, _BG_TO_OVERLAY_PORT);

      bgPort.listen((message) {
        log('📨 Background service received overlay message: $message');
        _handleOverlayMessage(message);
      });

      log('✅ Background overlay ports set up');
    } catch (e) {
      log('❌ Failed to set up background ports: $e');
    }
  }

  /// Check if system alert window permission is granted
  static Future<bool> _hasOverlayPermission() async {
    try {
      final hasPermission = await SystemAlertWindow.checkPermissions();
      return hasPermission == true;
    } catch (e) {
      log('❌ Error checking overlay permission: $e');
      return false;
    }
  }

  /// Check if we should skip showing overlay due to cooldown or duplicate
  static bool _shouldSkipOverlay(String callId) {
    final now = DateTime.now();

    // Check if same call ID (duplicate)
    if (_lastCallId == callId && _overlayActive) {
      log('🚫 Duplicate overlay prevented for call: $callId');
      return true;
    }

    // Check cooldown period
    if (_lastOverlayTime != null &&
        now.difference(_lastOverlayTime!) < _cooldownDuration) {
      log('🚫 Overlay cooldown active, skipping call: $callId');
      return true;
    }

    return false;
  }

  /// Close existing overlay if any
  static Future<void> _closeExistingOverlay() async {
    if (_overlayActive) {
      try {
        await SystemAlertWindow.closeSystemWindow(prefMode: SystemWindowPrefMode.OVERLAY);
        await Future.delayed(const Duration(milliseconds: 300));
        _overlayActive = false;
        _lastCallId = null;
        log('🗑️ Closed existing overlay');
      } catch (e) {
        log('⚠️ Warning: Error closing existing overlay: $e');
        _overlayActive = false;
        _lastCallId = null;
      }
    }
  }

  /// Show call overlay with corrected parameters
  static Future<bool> showCallOverlay({
    required String callId,
    required String title,
    required String subtitle,
    required String callState,
    String phoneNumber = '',
    bool autoClose = false,
    Duration autoCloseDuration = const Duration(seconds: 10),
    int maxRetries = 2,
  }) async {
    if (!_isInitialized) {
      log('❌ OverlayManager not initialized');
      return false;
    }

    // Check for duplicate/cooldown
    if (_shouldSkipOverlay(callId)) {
      return false;
    }

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        log('🔄 Attempting to show overlay for call: $callId (attempt $attempt/$maxRetries)');

        // Check permissions first
        if (!await _hasOverlayPermission()) {
          log('❌ System overlay permission not granted');
          return false;
        }

        // Close any existing overlay
        await _closeExistingOverlay();

        // Show new overlay with correct parameters
        await SystemAlertWindow.showSystemWindow(
          height: 400,
          width: 350,
          gravity: SystemWindowGravity.TOP,
          prefMode: SystemWindowPrefMode.OVERLAY,
          layoutParamFlags: [
            SystemWindowFlags.FLAG_NOT_FOCUSABLE,
            SystemWindowFlags.FLAG_NOT_TOUCH_MODAL,
          ],
          notificationTitle: title,
          notificationBody: subtitle,
        );

        // Mark overlay as active and update tracking
        _overlayActive = true;
        _lastCallId = callId;
        _lastOverlayTime = DateTime.now();

        // Wait for overlay to initialize
        await Future.delayed(const Duration(milliseconds: 300));

        // Send data to overlay
        try {
          await SystemAlertWindow.sendMessageToOverlay({
            'callId': callId,
            'title': title,
            'subtitle': subtitle,
            'callState': callState,
            'phoneNumber': phoneNumber,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
          log('📤 Data sent to overlay successfully');
        } catch (e) {
          log('❌ Error sending data to overlay: $e');
        }

        log('✅ Call overlay displayed successfully for: $callId');

        // Set up auto-close if requested
        if (autoClose) {
          _autoCloseTimer?.cancel();
          _autoCloseTimer = Timer(autoCloseDuration, () async {
            await closeOverlay();
            log('🕐 Overlay auto-closed after ${autoCloseDuration.inSeconds}s');
          });
        }

        return true;

      } catch (e) {
        log('❌ Attempt $attempt failed to show overlay: $e');
        _overlayActive = false;
        _lastCallId = null;

        if (attempt < maxRetries) {
          // Wait before retrying
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        } else {
          log('❌ All attempts failed to show overlay for call: $callId');
          return false;
        }
      }
    }

    return false;
  }

  /// Close overlay safely
  static Future<void> closeOverlay() async {
    try {
      _autoCloseTimer?.cancel();
      _cooldownTimer?.cancel();

      if (_overlayActive) {
        await SystemAlertWindow.closeSystemWindow(prefMode: SystemWindowPrefMode.OVERLAY);
        _overlayActive = false;
        _lastCallId = null;
        log('✅ Overlay closed successfully');
      } else {
        log('ℹ️ No active overlay to close');
      }
    } catch (e) {
      log('❌ Error closing overlay: $e');
      _overlayActive = false;
      _lastCallId = null;
    }
  }

  /// Mark overlay as closed (called from overlay widget)
  static void markOverlayClosed() {
    _overlayActive = false;
    _lastCallId = null;
    _autoCloseTimer?.cancel();
    log('📝 Overlay marked as closed');
  }

  /// Check if overlay is currently showing
  static Future<bool> isOverlayActive() async {
    return _overlayActive;
  }

  /// Get the last call ID that had an overlay
  static String? get lastCallId => _lastCallId;

  /// Check if overlay is visible for specific call
  static bool isCallOverlayVisible(String callId) {
    return _overlayActive && _lastCallId == callId;
  }

  /// Update overlay content using correct method
  static Future<void> updateOverlay({
    String? title,
    String? subtitle,
    String? callState,
    String? phoneNumber,
  }) async {
    try {
      if (!_overlayActive) {
        log('❌ Cannot update - no active overlay');
        return;
      }

      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (subtitle != null) data['subtitle'] = subtitle;
      if (callState != null) data['callState'] = callState;
      if (phoneNumber != null) data['phoneNumber'] = phoneNumber;
      data['timestamp'] = DateTime.now().millisecondsSinceEpoch;

      await SystemAlertWindow.sendMessageToOverlay(data);
      log('✅ Overlay updated successfully');
    } catch (e) {
      log('❌ Error updating overlay: $e');
    }
  }

  /// Show specific overlay for incoming calls
  static Future<bool> showIncomingCallOverlay({
    required String phoneNumber,
    String? contactName,
    String? callId,
    bool autoClose = true,
  }) async {
    final id = callId ?? 'incoming_${phoneNumber}_${DateTime.now().millisecondsSinceEpoch}';
    final title = 'Incoming Call';
    final subtitle = contactName != null
        ? '$contactName\n$phoneNumber'
        : phoneNumber;

    return await showCallOverlay(
      callId: id,
      title: title,
      subtitle: subtitle,
      callState: 'ringing',
      phoneNumber: phoneNumber,
      autoClose: autoClose,
      autoCloseDuration: const Duration(seconds: 15),
    );
  }

  /// Show specific overlay for active calls
  static Future<bool> showActiveCallOverlay({
    required String phoneNumber,
    String? contactName,
    String? duration,
    String? callId,
    bool autoClose = true,
  }) async {
    final id = callId ?? 'active_${phoneNumber}_${DateTime.now().millisecondsSinceEpoch}';
    final title = 'Call Started';
    final subtitle = contactName != null
        ? '$contactName\n$phoneNumber${duration != null ? '\nDuration: $duration' : ''}'
        : '$phoneNumber${duration != null ? '\nDuration: $duration' : ''}';

    return await showCallOverlay(
      callId: id,
      title: title,
      subtitle: subtitle,
      callState: 'active',
      phoneNumber: phoneNumber,
      autoClose: autoClose,
      autoCloseDuration: const Duration(seconds: 8),
    );
  }

  /// Show specific overlay for call ended
  static Future<bool> showCallEndedOverlay({
    required String phoneNumber,
    String? contactName,
    String? duration,
    String? callId,
    bool autoClose = true,
  }) async {
    final id = callId ?? 'ended_${phoneNumber}_${DateTime.now().millisecondsSinceEpoch}';
    final title = 'Call Ended';
    final subtitle = contactName != null
        ? '$contactName\n$phoneNumber${duration != null ? '\nDuration: $duration' : ''}'
        : '$phoneNumber${duration != null ? '\nDuration: $duration' : ''}';

    return await showCallOverlay(
      callId: id,
      title: title,
      subtitle: subtitle,
      callState: 'ended',
      phoneNumber: phoneNumber,
      autoClose: autoClose,
      autoCloseDuration: const Duration(seconds: 8),
    );
  }

  /// Show test overlay
  static Future<bool> showTestOverlay({
    String message = 'Test overlay',
    Duration autoCloseDuration = const Duration(seconds: 5),
  }) async {
    final testId = 'test_${DateTime.now().millisecondsSinceEpoch}';

    return await showCallOverlay(
      callId: testId,
      title: 'System Test',
      subtitle: '$message\nTime: ${DateTime.now().toString().substring(11, 19)}',
      callState: 'test',
      phoneNumber: '',
      autoClose: true,
      autoCloseDuration: autoCloseDuration,
    );
  }

  /// Clean up resources
  static void cleanup() {
    try {
      _autoCloseTimer?.cancel();
      _cooldownTimer?.cancel();
      _overlayToAppPort?.close();

      try {
        IsolateNameServer.removePortNameMapping(_APP_TO_OVERLAY_PORT);
        IsolateNameServer.removePortNameMapping(_OVERLAY_TO_APP_PORT);
        IsolateNameServer.removePortNameMapping(_BG_TO_OVERLAY_PORT);
      } catch (e) {
        // Ignore port removal errors
      }

      _isInitialized = false;
      _overlayActive = false;
      _lastCallId = null;
      _lastOverlayTime = null;

      log('✅ OverlayManager cleaned up');
    } catch (e) {
      log('❌ Error during OverlayManager cleanup: $e');
    }
  }

  /// Request overlay permission from user
  static Future<bool> requestOverlayPermission() async {
    try {
      final hasPermission = await SystemAlertWindow.checkPermissions();
      if (hasPermission == true) {
        return true;
      }

      // Request permission using correct method
      await SystemAlertWindow.requestPermissions(prefMode: SystemWindowPrefMode.OVERLAY);

      // Check again after request
      final newPermissionStatus = await SystemAlertWindow.checkPermissions();
      return newPermissionStatus == true;
    } catch (e) {
      log('❌ Error requesting overlay permission: $e');
      return false;
    }
  }
}
