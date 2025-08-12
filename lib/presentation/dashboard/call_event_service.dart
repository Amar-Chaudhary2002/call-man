// lib/presentation/dashboard/call_event_service.dart
import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_state/phone_state.dart';

class CallEventService {
  // FIX: type matches the stream
  static StreamSubscription<PhoneState>? _sub;

  static Future<void> init() async {
    log("INit funcation of call_event_service file");
    if (!Platform.isAndroid) return;

    final phoneGranted = await Permission.phone.isGranted;
    if (!phoneGranted) return;

    _sub?.cancel();
    _sub = PhoneState.stream.listen((event) async {
      print('Phone state changed: ${event.status} - Number: ${event.number}');

      switch (event.status) {
        case PhoneStateStatus.CALL_INCOMING:
          await _showOverlay('Incoming Call', event.number ?? 'Unknown');
          break;
        case PhoneStateStatus.CALL_STARTED:
          await _showOverlay('Call Started', event.number ?? 'Unknown');
          break;
        case PhoneStateStatus.CALL_ENDED:
          await _showOverlay('Call Ended', 'Duration: X min');
          break;
        default:
          await _closeIfOpen();
          break;
      }
    });
  }

  static Future<bool> _isXiaomiDevice() async {
    try {
      const platform = MethodChannel('device_info');
      final manufacturer = await platform.invokeMethod('getManufacturer');
      return manufacturer.toString().toLowerCase().contains('xiaomi');
    } catch (e) {
      return false;
    }
  }

  static Future<bool> _checkXiaomiOverlayPermission() async {
    if (!Platform.isAndroid) return true;

    try {
      const platform = MethodChannel('overlay_permission');
      final bool hasPermission = await platform.invokeMethod('checkXiaomiPermission');
      if (!hasPermission) {
        final bool granted = await platform.invokeMethod('requestXiaomiPermission');
        return granted;
      }
      return true;
    } catch (e) {
      log("Xiaomi permission check failed: $e");
      return false;
    }
  }
  static Future<void> _showOverlay(String title, String subtitle) async {
    log("Inside _showOverlay with title: $title, subtitle: $subtitle");

    if (Platform.isAndroid && await _isXiaomiDevice()) {
      if (!await _checkXiaomiOverlayPermission()) {
        log("Xiaomi overlay permission denied");
        return;
      }
    }

    try {
      // 1. Check and request overlay permission if needed
      if (!await FlutterOverlayWindow.isPermissionGranted()) {
        log("Requesting overlay permission...");
        final granted = await FlutterOverlayWindow.requestPermission();
        if (!granted!) {
          log("Overlay permission denied");
          return;
        }
      }

      // 2. Close any existing overlay
      if (await FlutterOverlayWindow.isActive()) {
        await FlutterOverlayWindow.closeOverlay();
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // 3. Show new overlay - no return value to check
      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        height: 200,
        width: WindowSize.matchParent,
        alignment: OverlayAlignment.centerRight,
        overlayTitle: title,
        overlayContent: subtitle,
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.auto,
      );

      // 4. Wait for overlay to initialize
      await Future.delayed(const Duration(milliseconds: 300));

      // 5. Send data to overlay
      await FlutterOverlayWindow.shareData({
        'title': title,
        'subtitle': subtitle,
        'callState': title.contains('Incoming')
            ? 'ringing'
            : title.contains('Ended')
            ? 'disconnected'
            : 'active',
      });

      log("Overlay shown successfully");
    } catch (e) {
      log("Error showing overlay: $e");
      // Try fallback method
      await _showFallbackOverlay(title, subtitle);
    }
  }


  static Future<void> _showFallbackOverlay(String title, String subtitle) async {
    try {
      log("Attempting fallback overlay method");

      // Show overlay without checking return value
      await FlutterOverlayWindow.showOverlay(
        enableDrag: false,
        height: 150,
        width: WindowSize.matchParent,
        alignment: OverlayAlignment.bottomCenter,
        overlayTitle: title,
        overlayContent: subtitle,
        flag: OverlayFlag.flagNotFocusable,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.auto,
      );

      // Check if it worked by verifying if overlay is active
      await Future.delayed(const Duration(milliseconds: 300));
      if (await FlutterOverlayWindow.isActive()) {
        await FlutterOverlayWindow.shareData({
          'title': title,
          'subtitle': subtitle,
          'callState': 'fallback',
        });
        log("Fallback overlay shown successfully");
      } else {
        log("Fallback overlay failed to show");
      }
    } catch (e) {
      log("Fallback overlay also failed: $e");
    }
  }



  static Future<void> _closeIfOpen() async {
    if (await FlutterOverlayWindow.isActive()) {
      await FlutterOverlayWindow.closeOverlay();
    }
  }

  static Future<void> dispose() async {
    await _sub?.cancel();
  }
}

@pragma('vm:entry-point')
Future<void> onBackgroundServiceStart(ServiceInstance service) async {
  await CallEventService.init();
  service.on('stopService').listen((_) async {
    await CallEventService.dispose();
    service.stopSelf();
  });
}
