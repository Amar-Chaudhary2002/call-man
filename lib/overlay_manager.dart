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
  static bool _overlayActive = false; // Track overlay state manually
  static Timer? _autoCloseTimer;

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
        log('Received message from overlay: $message');
        if (message is Map && message['action'] == 'overlay_closed_by_user') {
          _autoCloseTimer?.cancel();
          _overlayActive = false;
          log('Overlay closed by user interaction');
        }
      });

      _isInitialized = true;
      log('✅ OverlayManager initialized');
    } catch (e) {
      log('❌ Failed to initialize OverlayManager: $e');
    }
  }

  /// Set up ports for background service communication
  static void setupBackgroundPorts() {
    try {
      // Background service sets up its own port for communication
      final bgPort = ReceivePort();
      IsolateNameServer.removePortNameMapping(_BG_TO_OVERLAY_PORT);
      IsolateNameServer.registerPortWithName(bgPort.sendPort, _BG_TO_OVERLAY_PORT);

      bgPort.listen((message) {
        log('Background service received overlay message: $message');
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

  /// Close existing overlay if any
  static Future<void> _closeExistingOverlay() async {
    if (_overlayActive) {
      try {
        await SystemAlertWindow.closeSystemWindow(prefMode: SystemWindowPrefMode.OVERLAY);
        await Future.delayed(const Duration(milliseconds: 300));
        _overlayActive = false;
        log('🗑️ Closed existing overlay');
      } catch (e) {
        log('Warning: Error closing existing overlay: $e');
        // Still set to false to proceed
        _overlayActive = false;
      }
    }
  }

  /// Show call overlay with enhanced error handling and retry logic
  static Future<bool> showCallOverlay({
    required String title,
    required String subtitle,
    required String callState,
    String phoneNumber = '',
    bool autoClose = false,
    Duration autoCloseDuration = const Duration(seconds: 10),
    int maxRetries = 3,
  }) async {
    if (!_isInitialized) {
      log('❌ OverlayManager not initialized');
      return false;
    }

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        log('🔄 Attempting to show overlay (attempt $attempt/$maxRetries)');

        // Check permissions first
        if (!await _hasOverlayPermission()) {
          log('❌ System overlay permission not granted');
          return false;
        }

        // Close any existing overlay
        await _closeExistingOverlay();

        // Show new overlay
        await SystemAlertWindow.showSystemWindow(
          height: 200,
          width: 350,
          gravity: SystemWindowGravity.TOP,
          prefMode: SystemWindowPrefMode.OVERLAY,
          layoutParamFlags: const [
            SystemWindowFlags.FLAG_NOT_FOCUSABLE,
            SystemWindowFlags.FLAG_NOT_TOUCH_MODAL,
          ],
        );

        // Mark overlay as active
        _overlayActive = true;

        // Wait for overlay to initialize
        await Future.delayed(const Duration(milliseconds: 500));

        // Send data to overlay
        await SystemAlertWindow.sendMessageToOverlay({
          'title': title,
          'subtitle': subtitle,
          'callState': callState,
          'phoneNumber': phoneNumber,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });

        log('✅ Call overlay displayed successfully');

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
        _overlayActive = false; // Reset state on error

        if (attempt < maxRetries) {
          // Wait before retrying
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        } else {
          log('❌ All attempts failed to show overlay');
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

      if (_overlayActive) {
        await SystemAlertWindow.closeSystemWindow(prefMode: SystemWindowPrefMode.OVERLAY);
        _overlayActive = false;
        log('✅ Overlay closed successfully');
      } else {
        log('ℹ️ No active overlay to close');
      }
    } catch (e) {
      log('❌ Error closing overlay: $e');
      _overlayActive = false; // Reset state even on error
    }
  }

  /// Check if overlay is currently showing
  static Future<bool> isOverlayActive() async {
    return _overlayActive;
  }

  /// Update overlay content without recreating it
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
    bool autoClose = true,
  }) async {
    final title = 'Incoming Call';
    final subtitle = contactName != null
        ? '$contactName\n$phoneNumber'
        : phoneNumber;

    return await showCallOverlay(
      title: title,
      subtitle: subtitle,
      callState: 'ringing',
      phoneNumber: phoneNumber,
      autoClose: autoClose,
      autoCloseDuration: const Duration(seconds: 15), // Longer for incoming calls
    );
  }

  /// Show specific overlay for active calls
  static Future<bool> showActiveCallOverlay({
    required String phoneNumber,
    String? contactName,
    String? duration,
    bool autoClose = true,
  }) async {
    final title = 'Call Started';
    final subtitle = contactName != null
        ? '$contactName\n$phoneNumber${duration != null ? '\nDuration: $duration' : ''}'
        : '$phoneNumber${duration != null ? '\nDuration: $duration' : ''}';

    return await showCallOverlay(
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
    bool autoClose = true,
  }) async {
    final title = 'Call Ended';
    final subtitle = contactName != null
        ? '$contactName\n$phoneNumber${duration != null ? '\nDuration: $duration' : ''}'
        : '$phoneNumber${duration != null ? '\nDuration: $duration' : ''}';

    return await showCallOverlay(
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
    return await showCallOverlay(
      title: 'Test',
      subtitle: '$message\nTime: ${DateTime.now().toString().substring(11, 19)}',
      callState: 'test',
      phoneNumber: 'Test Number',
      autoClose: true,
      autoCloseDuration: autoCloseDuration,
    );
  }

  /// Clean up resources
  static void cleanup() {
    try {
      _autoCloseTimer?.cancel();
      _overlayToAppPort?.close();

      // Remove port mappings
      IsolateNameServer.removePortNameMapping(_APP_TO_OVERLAY_PORT);
      IsolateNameServer.removePortNameMapping(_OVERLAY_TO_APP_PORT);
      IsolateNameServer.removePortNameMapping(_BG_TO_OVERLAY_PORT);

      _isInitialized = false;
      _overlayActive = false;
      log('✅ OverlayManager cleaned up');
    } catch (e) {
      log('❌ Error during OverlayManager cleanup: $e');
    }
  }

  /// Get send port for communication with overlay
  static SendPort? getOverlayPort() {
    return IsolateNameServer.lookupPortByName(_APP_TO_OVERLAY_PORT);
  }

  /// Request overlay permission from user
  static Future<bool> requestOverlayPermission() async {
    try {
      final hasPermission = await SystemAlertWindow.checkPermissions();
      if (hasPermission == true) {
        return true;
      }

      // Request permission
      await SystemAlertWindow.requestPermissions();

      // Check again after request
      final newPermissionStatus = await SystemAlertWindow.checkPermissions();
      return newPermissionStatus == true;
    } catch (e) {
      log('❌ Error requesting overlay permission: $e');
      return false;
    }
  }
}