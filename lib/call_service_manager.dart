// lib/services/call_service_manager.dart
import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'dart:developer' as dev;

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:system_alert_window/system_alert_window.dart';
import 'package:phone_state/phone_state.dart';
import 'package:permission_handler/permission_handler.dart';

import 'overlay_manager.dart';

class CallServiceManager {
  static const String _notificationChannelId = 'call_tracking_service';
  static const int _notificationId = 999;

  // Call tracking state
  static StreamSubscription<PhoneState>? _phoneStateSubscription;
  static String? _lastCallState;
  static String? _lastPhoneNumber;
  static DateTime? _lastEventTime;
  static Timer? _callDurationTimer;
  static DateTime? _callStartTime;

  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    // Create notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _notificationChannelId,
      'Call Tracking Service',
      description: 'Monitors incoming and outgoing calls',
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin fln = FlutterLocalNotificationsPlugin();
    await fln
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Configure service
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onServiceStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: _notificationChannelId,
        initialNotificationTitle: 'Call Tracking',
        initialNotificationContent: 'Service initializing...',
        foregroundServiceNotificationId: _notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onServiceStart,
        onBackground: _onIosBackground,
      ),
    );
  }

  static Future<void> startService() async {
    final service = FlutterBackgroundService();
    if (!await service.isRunning()) {
      await service.startService();
      dev.log('✅ Call tracking service started');
    } else {
      dev.log('ℹ️ Service already running');
    }
  }

  static Future<void> stopService() async {
    final service = FlutterBackgroundService();
    service.invoke("stop_service");
    dev.log('🛑 Call tracking service stop requested');
  }

  static Future<void> _startCallMonitoring() async {
    try {
      // Check permission first
      final phonePermission = await Permission.phone.status;
      if (!phonePermission.isGranted) {
        dev.log('❌ Phone permission not granted');
        return;
      }

      // Cancel existing subscription
      await _phoneStateSubscription?.cancel();

      // Start phone state monitoring
      _phoneStateSubscription = PhoneState.stream.listen(
        _handlePhoneStateChange,
        onError: (error) {
          dev.log('❌ Phone state stream error: $error');
        },
      );

      dev.log('✅ Call monitoring started');
    } catch (e) {
      dev.log('❌ Error starting call monitoring: $e');
    }
  }

  static void _handlePhoneStateChange(PhoneState state) {
    try {
      final phoneNumber = state.number ?? 'Unknown';
      final callState = _mapPhoneStateToString(state.status);
      final now = DateTime.now();

      dev.log('📞 Call state changed: $callState for $phoneNumber');

      // Prevent duplicate events within 2 seconds
      if (_lastCallState == callState &&
          _lastPhoneNumber == phoneNumber &&
          _lastEventTime != null &&
          now.difference(_lastEventTime!).inSeconds < 2) {
        dev.log('🚫 Duplicate call state ignored');
        return;
      }

      // Update tracking variables
      _lastCallState = callState;
      _lastPhoneNumber = phoneNumber;
      _lastEventTime = now;

      // Handle different call states
      switch (callState.toLowerCase()) {
        case 'ringing':
          _handleIncomingCall(phoneNumber);
          break;
        case 'started':
          _handleCallStarted(phoneNumber);
          break;
        case 'ended':
          _handleCallEnded(phoneNumber);
          break;
      }

    } catch (e) {
      dev.log('❌ Error handling phone state change: $e');
    }
  }

  static void _handleIncomingCall(String phoneNumber) {
    final callId = 'incoming_${phoneNumber}_${DateTime.now().millisecondsSinceEpoch}';

    OverlayManager.showIncomingCallOverlay(
      phoneNumber: phoneNumber,
      callId: callId,
      autoClose: true,
    );
  }

  static void _handleCallStarted(String phoneNumber) {
    _callStartTime = DateTime.now();
    final callId = 'active_${phoneNumber}_${_callStartTime!.millisecondsSinceEpoch}';

    // Start duration tracking
    _callDurationTimer?.cancel();
    _callDurationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_callStartTime != null) {
        final duration = _formatDuration(DateTime.now().difference(_callStartTime!));
        OverlayManager.updateOverlay(
          title: 'Call Active',
          subtitle: '$phoneNumber\nDuration: $duration',
        );
      }
    });

    OverlayManager.showActiveCallOverlay(
      phoneNumber: phoneNumber,
      callId: callId,
      autoClose: false, // Don't auto-close active calls
    );
  }

  static void _handleCallEnded(String phoneNumber) {
    _callDurationTimer?.cancel();

    String? duration;
    if (_callStartTime != null) {
      duration = _formatDuration(DateTime.now().difference(_callStartTime!));
      _callStartTime = null;
    }

    final callId = 'ended_${phoneNumber}_${DateTime.now().millisecondsSinceEpoch}';

    OverlayManager.showCallEndedOverlay(
      phoneNumber: phoneNumber,
      duration: duration,
      callId: callId,
      autoClose: true,
    );
  }

  static String _mapPhoneStateToString(PhoneStateStatus status) {
    switch (status) {
      case PhoneStateStatus.CALL_INCOMING:
        return 'ringing';
      case PhoneStateStatus.CALL_STARTED:
        return 'started';
      case PhoneStateStatus.CALL_ENDED:
        return 'ended';
      case PhoneStateStatus.NOTHING:
        return 'idle';
      default:
        return 'unknown';
    }
  }

  static String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  static Future<void> _stopCallMonitoring() async {
    try {
      await _phoneStateSubscription?.cancel();
      _phoneStateSubscription = null;
      _callDurationTimer?.cancel();
      _callDurationTimer = null;
      _callStartTime = null;

      dev.log('✅ Call monitoring stopped');
    } catch (e) {
      dev.log('❌ Error stopping call monitoring: $e');
    }
  }
}

// ===== Background service entry point =====
@pragma('vm:entry-point')
void _onServiceStart(ServiceInstance service) async {
  // Initialize plugins
  DartPluginRegistrant.ensureInitialized();

  dev.log('🚀 Call tracking service started in background');

  try {
    // Set up overlay manager for background service
    OverlayManager.setupBackgroundPorts();

    // Start call monitoring immediately
    await CallServiceManager._startCallMonitoring();

    _updateServiceNotification(service, "Call Tracking Active", "Monitoring calls in background");

    // Handle service commands
    service.on('start_monitoring').listen((event) async {
      await CallServiceManager._startCallMonitoring();
      _updateServiceNotification(service, "Call Tracking Active", "Monitoring started");
    });

    service.on('stop_monitoring').listen((event) async {
      await CallServiceManager._stopCallMonitoring();
      _updateServiceNotification(service, "Call Tracking Paused", "Monitoring stopped");
    });

    // Cleanup on service stop
    service.on('stop_service').listen((event) async {
      await CallServiceManager._stopCallMonitoring();
      await OverlayManager.closeOverlay();
      OverlayManager.cleanup();
      service.stopSelf();
    });

    // Keep service alive with periodic updates
    Timer.periodic(const Duration(minutes: 15), (_) {
      final now = DateTime.now().toString().substring(11, 19);
      _updateServiceNotification(service, "Call Tracking Active", "Heartbeat: $now");
    });

  } catch (e) {
    dev.log('❌ Error in background service: $e');
    _updateServiceNotification(service, "Call Tracking Error", "Service error occurred");
  }
}

void _updateServiceNotification(ServiceInstance service, String title, String content) {
  try {
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: title,
        content: content,
      );
    }
  } catch (e) {
    dev.log('❌ Notification update failed: $e');
    try {
      if (service is AndroidServiceInstance) {
        service.setAsBackgroundService();
      }
    } catch (e2) {
      dev.log('❌ Failed to set as background: $e2');
    }
  }
}

@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  return true;
}
