// background_service.dart
import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'dart:developer' as dev;

import 'package:flutter_background_service/flutter_background_service.dart';
// DO NOT import flutter_background_service_android here; it logs a warning in background isolate.
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:system_alert_window/system_alert_window.dart';

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

    final FlutterLocalNotificationsPlugin fln = FlutterLocalNotificationsPlugin();
    await fln
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
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
    if (!await service.isRunning()) {
      await service.startService();
    }
  }

  static Future<void> stopService() async {
    final service = FlutterBackgroundService();
    service.invoke("stop");
  }
}

// ===== Background isolate entry point =====
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Initialize plugins in background isolate
  DartPluginRegistrant.ensureInitialized();

  dev.log('Background service: Service started in isolate');

  // Expose a port so the overlay UI can message us (e.g., Close Overlay)
  final ReceivePort bgPort = ReceivePort();
  const String bgPortName = 'bg_port';
  IsolateNameServer.removePortNameMapping(bgPortName);
  IsolateNameServer.registerPortWithName(bgPort.sendPort, bgPortName);

  Timer? overlayTimer;
  Timer? keepAliveTimer;
  int overlayCount = 0;
  bool overlayLoopEnabled = false;

  // Handle messages (e.g., from overlay UI)
  bgPort.listen((msg) async {
    if (msg is Map && msg['action'] == 'close_overlay') {
      overlayLoopEnabled = false; // stop re-spawning
      await _forceCloseOverlay();
      _updateNotification(service, "Overlay Service Paused", "Overlay closed by user");
    }
  });

  // Start periodic overlay when asked by UI isolate
  service.on('start_overlay').listen((event) async {
    overlayLoopEnabled = true;
    overlayCount = 0;

    overlayTimer?.cancel();
    overlayTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!overlayLoopEnabled) return;
      overlayCount++;
      dev.log('Background service: Trigger overlay #$overlayCount');
      await _showBackgroundOverlay(overlayCount);
      _updateNotification(service, "Overlay Service Active", "Showing every 5s • Count: $overlayCount");
    });
  });

  // Stop periodic overlay
  service.on('stop_overlay').listen((event) async {
    overlayLoopEnabled = false;
    overlayTimer?.cancel();
    await _forceCloseOverlay();
    _updateNotification(service, "Overlay Service Running", "Overlay stopped");
  });

  // App hints
  service.on('app_going_inactive').listen((event) {
    dev.log('Background service: app going inactive');
  });

  service.on('cleanup_on_app_exit').listen((event) {
    dev.log('Background service: cleanup on app exit');
    // Keep service alive unless overlay loop is disabled
    if (!overlayLoopEnabled) {
      service.stopSelf();
    }
  });

  // Stop service entirely
  service.on('stop').listen((event) async {
    overlayLoopEnabled = false;
    overlayTimer?.cancel();
    keepAliveTimer?.cancel();
    bgPort.close();
    await _forceCloseOverlay();
    service.stopSelf();
  });

  // Keep notification updated
  keepAliveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
    final title = overlayLoopEnabled ? "Overlay Service Active" : "Overlay Service Running";
    final content = overlayLoopEnabled
        ? "Overlay pops every 5 seconds"
        : "Service ready — tap to open app";
    _updateNotification(service, title, content);
  });

  _updateNotification(service, "Overlay Service Started", "Ready to show overlays");
}

void _updateNotification(ServiceInstance service, String title, String content) {
  try {
    // Call Android method without importing android-specific plugin into this isolate
    (service as dynamic).setForegroundNotificationInfo(title: title, content: content);
  } catch (_) {
    // ignore on non-Android
  }
}

Future<void> _showBackgroundOverlay(int count) async {
  try {
    // First push data into overlay isolate
    await SystemAlertWindow.sendMessageToOverlay({'type': 'update_count', 'count': count});

    // Then request a compact window (fits MIUI’s tiny height)
    await SystemAlertWindow.showSystemWindow(
      height: 100,
      width: 280,
      gravity: SystemWindowGravity.CENTER,
      prefMode: SystemWindowPrefMode.OVERLAY,
      layoutParamFlags: const [
        SystemWindowFlags.FLAG_NOT_FOCUSABLE,
        SystemWindowFlags.FLAG_NOT_TOUCH_MODAL,
      ],
    );

    // Auto-close after a few seconds (so the 5s loop feels like a toast)
    Timer(const Duration(seconds: 4), () async {
      try {
        await SystemAlertWindow.closeSystemWindow(prefMode: SystemWindowPrefMode.OVERLAY);
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
    await SystemAlertWindow.closeSystemWindow(prefMode: SystemWindowPrefMode.OVERLAY);
  } catch (e) {
    dev.log('Error force closing overlay: $e');
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  return true;
}
