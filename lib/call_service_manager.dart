// lib/services/call_service_manager.dart
import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'dart:developer' as dev;

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:system_alert_window/system_alert_window.dart';

class CallServiceManager {
  static const String _notificationChannelId = 'call_tracking_service';
  static const int _notificationId = 999;

  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    // Create notification channel using flutter_local_notifications
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _notificationChannelId,
      'Call Tracking Service',
      description: 'Monitors incoming and outgoing calls',
      importance: Importance.low, // Use low importance to avoid issues
    );

    final FlutterLocalNotificationsPlugin fln = FlutterLocalNotificationsPlugin();
    await fln
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Configure service with minimal settings
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onServiceStart,
        autoStart: false,
        isForegroundMode: false, // Start as background service
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
    }
  }

  static Future<void> stopService() async {
    final service = FlutterBackgroundService();
    service.invoke("stop_service");
  }
}

// ===== Background service entry point =====
@pragma('vm:entry-point')
void _onServiceStart(ServiceInstance service) async {
  // Initialize plugins
  DartPluginRegistrant.ensureInitialized();

  dev.log('Call tracking service started');

  bool isMonitoring = false;
  Timer? monitoringTimer;

  // Start call monitoring when requested
  service.on('start_monitoring').listen((event) {
    _startCallMonitoring(service);
  });

  // Stop call monitoring
  service.on('stop_monitoring').listen((event) {
    _stopCallMonitoring(service);
  });

  // Cleanup on service stop
  service.on('stop_service').listen((event) async {
    _stopCallMonitoring(service);
    await SystemAlertWindow.closeSystemWindow(prefMode: SystemWindowPrefMode.OVERLAY);
    service.stopSelf();
  });

  // Keep service alive with minimal notifications
  Timer.periodic(const Duration(minutes: 30), (_) {
    _updateServiceNotification(service, "Call Tracking Active", "Service is running");
  });

  _updateServiceNotification(service, "Call Tracking Service", "Ready to monitor calls");
}

void _startCallMonitoring(ServiceInstance service) {
  dev.log('Starting call monitoring...');
  _updateServiceNotification(service, "Call Tracking Active", "Monitoring calls");

  // Simulate call monitoring - replace with actual call detection
  Timer.periodic(const Duration(seconds: 10), (timer) async {
    // This would be your actual call detection logic
    await _simulateCallDetection(service);
  });
}

void _stopCallMonitoring(ServiceInstance service) {
  dev.log('Stopping call monitoring...');
  _updateServiceNotification(service, "Call Tracking Service", "Monitoring paused");
}

Future<void> _simulateCallDetection(ServiceInstance service) async {
  // Replace this with your actual call detection logic
  try {
    // Simulate call events
    final events = ['incoming', 'outgoing', 'missed', 'ended'];
    final event = events[DateTime.now().second % events.length];

    await _updateCallOverlay({
      'type': 'call_event',
      'event': event,
      'number': '+1234567890',
      'timestamp': DateTime.now().toString()
    });

    _updateServiceNotification(service, "Call Event: $event", "Number: +1234567890");
  } catch (e) {
    dev.log('Error in call detection: $e');
  }
}

Future<void> _updateCallOverlay(Map<String, dynamic> data) async {
  try {
    await SystemAlertWindow.sendMessageToOverlay(data);
    await SystemAlertWindow.showSystemWindow(
      height: 120,
      width: 300,
      gravity: SystemWindowGravity.TOP,
      prefMode: SystemWindowPrefMode.OVERLAY,
      layoutParamFlags: const [
        SystemWindowFlags.FLAG_NOT_FOCUSABLE,
        SystemWindowFlags.FLAG_NOT_TOUCH_MODAL,
      ],
    );
  } catch (e) {
    dev.log('Error updating overlay: $e');
  }
}

void _updateServiceNotification(ServiceInstance service, String title, String content) {
  try {
    // Check if it's an Android service instance and update notification
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: title,
        content: content,
      );
    }
  } catch (e) {
    // If foreground notification fails, continue as background service
    dev.log('Notification update failed: $e');
    try {
      if (service is AndroidServiceInstance) {
        service.setAsBackgroundService();
      }
    } catch (e2) {
      dev.log('Failed to set as background: $e2');
    }
  }
}

@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  return true;
}