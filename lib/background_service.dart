// background_service.dart
import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:system_alert_window/system_alert_window.dart';
import 'package:phone_state/phone_state.dart';

class BackgroundServiceManager {
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        autoStartOnBoot: false,
        notificationChannelId: 'call_overlay_service',
        initialNotificationTitle: 'Call Overlay Service',
        initialNotificationContent: 'Monitoring calls for overlay display',
        foregroundServiceNotificationId: 888,
      ),
    );
  }

  static Future<void> startService() async {
    final service = FlutterBackgroundService();
    await service.startService();
  }

  static Future<void> stopService() async {
    final service = FlutterBackgroundService();
    service.invoke("cleanup_on_app_exit");
  }
}

// Entry point for service
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  final callOverlayService = CallOverlayService(service);
  await callOverlayService.initialize();
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

class CallOverlayService {
  final ServiceInstance service;
  StreamSubscription<PhoneState>? _phoneStateSubscription;
  bool _callMonitoringEnabled = false;
  bool _appInForeground = true;
  int _callEventCount = 0;
  Timer? _autoCloseTimer;
  bool _overlayVisible = false;

  CallOverlayService(this.service);

  Future<void> initialize() async {
    dev.log("🚀 Background service started");

    // Commands from main app
    service.on('enable_call_monitoring').listen((_) {
      dev.log("📱 Call monitoring enabled");
      _enableCallMonitoring();
    });

    service.on('disable_call_monitoring').listen((_) {
      dev.log("📱 Call monitoring disabled");
      _disableCallMonitoring();
    });

    service.on('app_going_active').listen((_) {
      dev.log("📱 App going active - hiding overlays");
      _appInForeground = true;
      _hideOverlay();
    });

    service.on('app_going_inactive').listen((_) {
      dev.log("📱 App going inactive - overlays enabled");
      _appInForeground = false;
    });

    service.on('cleanup_on_app_exit').listen((_) {
      dev.log("📱 App exit cleanup");
      _cleanup();
    });

    // Update notification every 10s
    Timer.periodic(const Duration(seconds: 10), (timer) {
      if (service is AndroidServiceInstance) {
        (service as AndroidServiceInstance).setForegroundNotificationInfo(
          title: "Call Overlay Active",
          content: _callMonitoringEnabled
              ? "Monitoring calls${_appInForeground ? ' (App Active)' : ''}"
              : "Service running",
        );
      }
    });
  }

  void _enableCallMonitoring() {
    _callMonitoringEnabled = true;
    _phoneStateSubscription = PhoneState.stream.listen(_handlePhoneStateChange);
  }

  void _disableCallMonitoring() {
    _callMonitoringEnabled = false;
    _phoneStateSubscription?.cancel();
    _hideOverlay();
  }

  void _handlePhoneStateChange(PhoneState state) {
    if (!_callMonitoringEnabled) return;

    dev.log("📞 Phone state changed: ${state.status}");

    String eventType = '';
    bool shouldShowOverlay = false;

    switch (state.status) {
      case PhoneStateStatus.CALL_INCOMING:
        eventType = 'Incoming';
        shouldShowOverlay = true;
        break;
      case PhoneStateStatus.CALL_STARTED:
        eventType = 'Started';
        shouldShowOverlay = true;
        break;
      case PhoneStateStatus.CALL_ENDED:
        eventType = 'Ended';
        shouldShowOverlay = true;
        break;
      default:
        return;
    }

    if (shouldShowOverlay && !_appInForeground) {
      _showCallOverlay(eventType);
    } else {
      dev.log("💡 Overlay not shown - App in foreground: $_appInForeground");
    }
  }

  Future<void> _showCallOverlay(String eventType) async {
    try {
      _callEventCount++;
      dev.log("🔥 Showing overlay: $eventType (Event #$_callEventCount)");

      _autoCloseTimer?.cancel();

      final hasPermission = await SystemAlertWindow.checkPermissions() ?? false;
      if (!hasPermission) {
        dev.log("❌ No overlay permission");
        return;
      }

      if (_overlayVisible) {
        await _hideOverlay();
      }

      // Overlay data
      final overlayData = {
        'type': 'call_event',
        'event_type': eventType,
        'count': _callEventCount,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      final success = await SystemAlertWindow.showSystemWindow(
        height: 120,
        width: 300,
        gravity: SystemWindowGravity.TOP,
        prefMode: SystemWindowPrefMode.OVERLAY,
        notificationTitle: "Call Overlay",
        notificationBody: "Call $eventType",
      );

      if (success == true) {
        _overlayVisible = true;
        dev.log("✅ Overlay shown successfully");

        // Send data if overlay supports it
        await SystemAlertWindow.sendMessageToOverlay(overlayData);

        _autoCloseTimer = Timer(const Duration(seconds: 5), () {
          _hideOverlay();
        });
      } else {
        dev.log("❌ Failed to show overlay");
      }
    } catch (e) {
      dev.log("❌ Error showing overlay: $e");
    }
  }

  Future<void> _hideOverlay() async {
    try {
      if (_overlayVisible) {
        await SystemAlertWindow.closeSystemWindow(
          prefMode: SystemWindowPrefMode.OVERLAY,
        );
        _overlayVisible = false;
        _autoCloseTimer?.cancel();
        dev.log("🔒 Overlay hidden");
      }
    } catch (e) {
      dev.log("❌ Error hiding overlay: $e");
    }
  }

  void _cleanup() {
    _hideOverlay();
    _phoneStateSubscription?.cancel();
    _autoCloseTimer?.cancel();
  }
}
