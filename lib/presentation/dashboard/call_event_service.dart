// lib/presentation/dashboard/call_event_service.dart
import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_state/phone_state.dart';
import 'package:system_alert_window/system_alert_window.dart';

import '../../overlay_manager.dart';

class CallEventService {
  static StreamSubscription<PhoneState>? _phoneStateSubscription;
  static bool _isInitialized = false;
  static String? _lastPhoneNumber;
  static PhoneStateStatus? _lastCallState;
  static DateTime? _callStartTime;

  // Callback for overlay close requests from background
  static VoidCallback? onOverlayCloseRequest;

  /// Initialize the call event service
  Future<bool> init() async {
    if (_isInitialized) {
      log('Call event service already initialized');
      return true;
    }

    try {
      log('🔄 Initializing call event service...');

      if (!Platform.isAndroid) {
        log('❌ Call monitoring only supported on Android');
        return false;
      }

      // Check phone permission
      final phonePermissionStatus = await Permission.phone.status;
      if (!phonePermissionStatus.isGranted) {
        log('❌ Phone permission not granted');
        return false;
      }

      // Check system alert window permission
      final overlayPermission = await SystemAlertWindow.checkPermissions();
      if (overlayPermission != true) {
        log('❌ System overlay permission not granted');
        return false;
      }

      // Cancel existing subscription if any
      await _phoneStateSubscription?.cancel();

      // Set up phone state monitoring
      _phoneStateSubscription = PhoneState.stream.listen(
        _handlePhoneStateChange,
        onError: (error) {
          log('❌ Phone state stream error: $error');
        },
      );

      _isInitialized = true;
      log('✅ Call event service initialized successfully');
      return true;

    } catch (e) {
      log('❌ Failed to initialize call event service: $e');
      return false;
    }
  }

  /// Handle phone state changes
  static Future<void> _handlePhoneStateChange(PhoneState phoneState) async {
    try {
      final phoneNumber = phoneState.number ?? 'Unknown';
      final status = phoneState.status;

      log('📞 Phone state changed: $status - Number: $phoneNumber');

      // Store current call info
      _lastPhoneNumber = phoneNumber;
      _lastCallState = status;

      // Handle different call states
      switch (status) {
        case PhoneStateStatus.CALL_INCOMING:
          await _handleIncomingCall(phoneNumber);
          break;

        case PhoneStateStatus.CALL_STARTED:
          await _handleCallStarted(phoneNumber);
          break;

        case PhoneStateStatus.CALL_ENDED:
          await _handleCallEnded(phoneNumber);
          break;

        case PhoneStateStatus.NOTHING:
        // Call completely ended, clean up if needed
          await _handleCallIdle();
          break;
      }

    } catch (e) {
      log('❌ Error handling phone state change: $e');
    }
  }

  /// Handle incoming call
  static Future<void> _handleIncomingCall(String phoneNumber) async {
    try {
      log('📞 Incoming call from: $phoneNumber');

      final success = await OverlayManager.showIncomingCallOverlay(
        phoneNumber: phoneNumber,
        contactName: await _getContactName(phoneNumber),
        autoClose: false, // Keep showing until call state changes
      );

      if (success) {
        log('✅ Incoming call overlay displayed');
      } else {
        log('❌ Failed to show incoming call overlay');
        // Try fallback method
        await _showFallbackOverlay('Incoming Call', phoneNumber, 'ringing');
      }

    } catch (e) {
      log('❌ Error handling incoming call: $e');
    }
  }

  /// Handle call started
  static Future<void> _handleCallStarted(String phoneNumber) async {
    try {
      log('📞 Call started with: $phoneNumber');
      _callStartTime = DateTime.now();

      final success = await OverlayManager.showActiveCallOverlay(
        phoneNumber: phoneNumber,
        contactName: await _getContactName(phoneNumber),
        autoClose: true,
      );

      if (success) {
        log('✅ Active call overlay displayed');
      } else {
        log('❌ Failed to show active call overlay');
        // Try fallback method
        await _showFallbackOverlay('Call Started', phoneNumber, 'active');
      }

    } catch (e) {
      log('❌ Error handling call started: $e');
    }
  }

  /// Handle call ended
  static Future<void> _handleCallEnded(String phoneNumber) async {
    try {
      log('📞 Call ended with: $phoneNumber');

      // Calculate call duration
      String? duration;
      if (_callStartTime != null) {
        final endTime = DateTime.now();
        final durationSeconds = endTime.difference(_callStartTime!).inSeconds;
        if (durationSeconds > 0) {
          final minutes = durationSeconds ~/ 60;
          final seconds = durationSeconds % 60;
          duration = '${minutes}m ${seconds}s';
        }
      }

      final success = await OverlayManager.showCallEndedOverlay(
        phoneNumber: phoneNumber,
        contactName: await _getContactName(phoneNumber),
        duration: duration,
        autoClose: true,
      );

      if (success) {
        log('✅ Call ended overlay displayed');
      } else {
        log('❌ Failed to show call ended overlay');
        // Try fallback method
        await _showFallbackOverlay(
            'Call Ended',
            phoneNumber + (duration != null ? '\nDuration: $duration' : ''),
            'ended'
        );
      }

      // Reset call tracking
      _callStartTime = null;

    } catch (e) {
      log('❌ Error handling call ended: $e');
    }
  }

  /// Handle call idle state
  static Future<void> _handleCallIdle() async {
    try {
      log('📞 Call state: Idle');

      // Close any active overlay after a brief delay
      Future.delayed(const Duration(seconds: 2), () async {
        try {
          await OverlayManager.closeOverlay();
          log('🗑️ Attempted to close overlay due to idle state');
        } catch (e) {
          log('ℹ️ Overlay close on idle result: $e');
        }
      });

    } catch (e) {
      log('❌ Error handling call idle: $e');
    }
  }

  /// Fallback overlay method using direct system alert window
  static Future<void> _showFallbackOverlay(String title, String content, String callState) async {
    try {
      log('🔄 Using fallback overlay method');

      // Close any existing overlay (always attempt, ignore errors)
      try {
        await SystemAlertWindow.closeSystemWindow(prefMode: SystemWindowPrefMode.OVERLAY);
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (e) {
        log('ℹ️ Fallback overlay close attempt: $e');
      }

      // Show fallback overlay
      await SystemAlertWindow.showSystemWindow(
        height: 150,
        width: 300,
        gravity: SystemWindowGravity.CENTER,
        prefMode: SystemWindowPrefMode.OVERLAY,
        layoutParamFlags: const [
          SystemWindowFlags.FLAG_NOT_FOCUSABLE,
          SystemWindowFlags.FLAG_NOT_TOUCH_MODAL,
        ],
      );

      // Wait for overlay to initialize
      await Future.delayed(const Duration(milliseconds: 400));

      // Send data to overlay
      await SystemAlertWindow.sendMessageToOverlay({
        'title': title,
        'subtitle': content,
        'callState': callState,
        'phoneNumber': _lastPhoneNumber ?? '',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      log('✅ Fallback overlay displayed');

      // Auto-close after 5 seconds
      Timer(const Duration(seconds: 5), () async {
        try {
          await SystemAlertWindow.closeSystemWindow(prefMode: SystemWindowPrefMode.OVERLAY);
          log('🗑️ Fallback overlay auto-closed');
        } catch (e) {
          log('Error closing fallback overlay: $e');
        }
      });

    } catch (e) {
      log('❌ Fallback overlay method also failed: $e');
    }
  }

  /// Get contact name for phone number (placeholder implementation)
  static Future<String?> _getContactName(String phoneNumber) async {
    try {
      // TODO: Implement contact lookup if contacts permission is available
      // For now, return null to use phone number only
      return null;
    } catch (e) {
      log('Error getting contact name: $e');
      return null;
    }
  }

  /// Check if service is initialized and working
  static bool get isInitialized => _isInitialized;

  /// Get last known phone state
  static PhoneStateStatus? get lastCallState => _lastCallState;

  /// Get last known phone number
  static String? get lastPhoneNumber => _lastPhoneNumber;

  /// Test overlay functionality
  static Future<void> testOverlay() async {
    try {
      log('🧪 Testing overlay functionality...');

      final success = await OverlayManager.showTestOverlay(
        message: 'Call service test overlay',
        autoCloseDuration: const Duration(seconds: 3),
      );

      if (success) {
        log('✅ Test overlay displayed successfully');
      } else {
        log('❌ Test overlay failed, trying fallback...');
        await _showFallbackOverlay('Test', 'Service test overlay', 'test');
      }

    } catch (e) {
      log('❌ Error testing overlay: $e');
    }
  }

  // /// Manual overlay trigger for testing specific call states
  // static Future<void> simulateCallState(PhoneStateStatus status, [String phoneNumber = '+1234567890']) async {
  //   try {
  //     log('🎭 Simulating call state: $status with number: $phoneNumber');
  //
  //     final phoneState = PhoneState.fromMap({
  //       'status': status.toString().split('.').last,
  //       'number': phoneNumber,
  //     });
  //
  //     await _handlePhoneStateChange(phoneState);
  //
  //   } catch (e) {
  //     log('❌ Error simulating call state: $e');
  //   }
  // }

  /// Dispose of the service and clean up resources
  static Future<void> dispose() async {
    try {
      log('🧹 Disposing call event service...');

      await _phoneStateSubscription?.cancel();
      _phoneStateSubscription = null;

      // Close any active overlays
      await OverlayManager.closeOverlay();

      _isInitialized = false;
      _lastPhoneNumber = null;
      _lastCallState = null;
      _callStartTime = null;
      onOverlayCloseRequest = null;

      log('✅ Call event service disposed');

    } catch (e) {
      log('❌ Error disposing call event service: $e');
    }
  }

  /// Force close overlay (can be called from background service)
  static Future<void> forceCloseOverlay() async {
    try {
      await SystemAlertWindow.closeSystemWindow(prefMode: SystemWindowPrefMode.OVERLAY);
      log('✅ Overlay force-closed');
    } catch (e) {
      log('❌ Error force-closing overlay: $e');
    }
  }
}