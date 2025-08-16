// background_service.dart - Improved version with proper isolate handling
import 'dart:async';
import 'dart:ui';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:system_alert_window/system_alert_window.dart';
import 'dart:developer' as dev;

class BackgroundServiceManager {
  static const String _notificationChannelId = 'overlay_service';
  static const int _notificationId = 888;

  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _notificationChannelId,
      'Overlay Background Service',
      description: 'This channel is used for overlay background service.',
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: _notificationChannelId,
        initialNotificationTitle: 'Overlay Service Running',
        initialNotificationContent: 'Ready to show overlays',
        foregroundServiceNotificationId: _notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  static Future<void> startService() async {
    final service = FlutterBackgroundService();
    var isRunning = await service.isRunning();
    if (!isRunning) {
      service.startService();
    }
  }

  static Future<void> stopService() async {
    final service = FlutterBackgroundService();
    service.invoke("stop");
  }
}

// Background isolate entry point
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // CRITICAL: Only initialize DartPluginRegistrant in background isolate
  // Do NOT call WidgetsFlutterBinding.ensureInitialized() here
  DartPluginRegistrant.ensureInitialized();

  Timer? overlayTimer;
  Timer? keepAliveTimer;
  int overlayCount = 0;
  bool isOverlayServiceRunning = false;
  bool appIsActive = true;

  // Communication port for overlay commands
  ReceivePort receivePort = ReceivePort();
  SendPort? mainAppPort;

  dev.log('Background service: Service started in isolate');

  // Listen for commands from main app
  service.on('start_overlay').listen((event) async {
    dev.log('Background service: Starting overlay timer');
    isOverlayServiceRunning = true;
    overlayCount = 0;

    overlayTimer?.cancel();
    overlayTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      if (!isOverlayServiceRunning) {
        timer.cancel();
        return;
      }

      overlayCount++;
      dev.log('Background service: Triggering overlay #$overlayCount');

      try {
        // Send message to main app to show overlay
        if (mainAppPort != null) {
          mainAppPort!.send({
            'action': 'show_overlay',
            'count': overlayCount,
          });
        } else {
          // Fallback: try to show overlay directly
          await _showBackgroundOverlay(overlayCount);
        }
      } catch (e) {
        dev.log('Error showing overlay: $e');
      }
    });

    // Update notification
    _updateNotification(service, "Overlay Service Active",
        "Showing overlay every 5 seconds - Count: $overlayCount");
  });

  service.on('stop_overlay').listen((event) {
    dev.log('Background service: Stopping overlay timer');
    isOverlayServiceRunning = false;
    overlayTimer?.cancel();

    // Send stop message to main app
    if (mainAppPort != null) {
      mainAppPort!.send({'action': 'close_overlay'});
    } else {
      _forceCloseOverlay();
    }

    _updateNotification(service, "Overlay Service Paused",
        "Service running but overlay stopped");
  });

  service.on('app_going_inactive').listen((event) {
    dev.log('Background service: App going inactive');
    appIsActive = false;
  });

  service.on('cleanup_on_app_exit').listen((event) {
    dev.log('Background service: App exiting - cleaning up');
    appIsActive = false;

    if (!isOverlayServiceRunning) {
      service.stopSelf();
    }
  });

  service.on('stop').listen((event) {
    dev.log('Background service: Stopping service');
    isOverlayServiceRunning = false;
    overlayTimer?.cancel();
    keepAliveTimer?.cancel();
    receivePort.close();
    service.stopSelf();
  });

  service.on('register_main_port').listen((event) {
    if (event != null && event['port'] != null) {
      mainAppPort = event['port'] as SendPort;
      dev.log('Background service: Main app port registered');
    }
  });

  // Keep service alive
  keepAliveTimer = Timer.periodic(Duration(seconds: 30), (timer) {
    String title = isOverlayServiceRunning ? "Overlay Service Active" : "Overlay Service Running";
    String content = isOverlayServiceRunning
        ? "Showing overlay every 5 seconds - Count: $overlayCount"
        : "Service running - tap to open app";
    _updateNotification(service, title, content);
  });

  _updateNotification(service, "Overlay Service Started",
      "Ready to show overlays - tap to open app");
}

void _updateNotification(ServiceInstance service, String title, String content) {
  if (service is AndroidServiceInstance) {
    try {
      service.setForegroundNotificationInfo(
        title: title,
        content: content,
      );
    } catch (e) {
      dev.log('Error updating notification: $e');
    }
  }
}

// Simplified overlay showing for background service
Future<void> _showBackgroundOverlay(int count) async {
  try {
    dev.log('Background service: Attempting to show overlay directly');

    // Send count update first
    await SystemAlertWindow.sendMessageToOverlay({
      'type': 'update_count',
      'count': count,
    });

    // Show the overlay
    await SystemAlertWindow.showSystemWindow(
      height: 180,
      width: 300,
      gravity: SystemWindowGravity.CENTER,
      prefMode: SystemWindowPrefMode.OVERLAY,
      layoutParamFlags: [
        SystemWindowFlags.FLAG_NOT_FOCUSABLE,
        SystemWindowFlags.FLAG_NOT_TOUCH_MODAL,
      ],
    );

    // Auto close after 4 seconds
    Timer(Duration(seconds: 4), () async {
      try {
        await SystemAlertWindow.closeSystemWindow();
      } catch (e) {
        dev.log('Error auto-closing overlay: $e');
      }
    });
  } catch (e) {
    dev.log('Error in _showBackgroundOverlay: $e');
  }
}

Future<void> _forceCloseOverlay() async {
  try {
    await SystemAlertWindow.closeSystemWindow();
    dev.log('Overlay forcefully closed');
  } catch (e) {
    dev.log('Error force closing overlay: $e');
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  // Only initialize what's necessary for iOS background
  DartPluginRegistrant.ensureInitialized();
  return true;
}