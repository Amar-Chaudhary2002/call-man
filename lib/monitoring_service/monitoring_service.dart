// One more overlay attempt with different flags and parameters
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:call_app/database/database_service.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

const String STOP_MONITORING_SERVICE_KEY = "stop";

// Entry Point for Monitoring Isolate
@pragma('vm:entry-point')
onMonitoringServiceStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DatabaseService databaseService = await DatabaseService.instance();

  print("=== OVERLAY SERVICE STARTED (ATTEMPT 2) ===");

  // Stop this background service
  _registerListener(service);

  // Try different overlay approaches
  _startPeriodicTimer();
}

Future<void> _startPeriodicTimer() async {
  print("=== STARTING OVERLAY TIMER (ATTEMPT 2) ===");

  Timer.periodic(const Duration(seconds: 5), (timer) async {
    print("5 seconds elapsed - trying different overlay methods");

    await _tryMultipleOverlayMethods();
  });
}

Future<void> _tryMultipleOverlayMethods() async {
  try {
    bool hasPermission = await FlutterOverlayWindow.isPermissionGranted();

    if (!hasPermission) {
      print("❌ No overlay permission");
      return;
    }

    // Close any existing overlay
    await FlutterOverlayWindow.closeOverlay();
    await Future.delayed(Duration(milliseconds: 300));

    // Try Method 1: Minimal parameters
    print("Trying Method 1: Minimal parameters");
    await FlutterOverlayWindow.showOverlay();
    await Future.delayed(Duration(milliseconds: 500));
    bool active1 = await FlutterOverlayWindow.isActive();
    print("Method 1 result - Active: $active1");

    if (!active1) {
      await FlutterOverlayWindow.closeOverlay();
      await Future.delayed(Duration(milliseconds: 300));

      // Try Method 2: Fixed size
      print("Trying Method 2: Fixed size");
      await FlutterOverlayWindow.showOverlay(
        height: 400,
        width: 300,
      );
      await Future.delayed(Duration(milliseconds: 500));
      bool active2 = await FlutterOverlayWindow.isActive();
      print("Method 2 result - Active: $active2");

      if (!active2) {
        await FlutterOverlayWindow.closeOverlay();
        await Future.delayed(Duration(milliseconds: 300));

        // Try Method 3: Different flags
        print("Trying Method 3: Different flags");
        await FlutterOverlayWindow.showOverlay(
          height: WindowSize.matchParent,
          width: WindowSize.matchParent,
          flag: OverlayFlag.focusPointer,
          positionGravity: PositionGravity.auto,
        );
        await Future.delayed(Duration(milliseconds: 500));
        bool active3 = await FlutterOverlayWindow.isActive();
        print("Method 3 result - Active: $active3");

        if (!active3) {
          print("❌ All overlay methods failed");
        }
      }
    }

    // Auto-close after 3 seconds if any method worked
    Timer(Duration(seconds: 3), () async {
      await FlutterOverlayWindow.closeOverlay();
      print("Auto-closed overlay");
    });

  } catch (e, stackTrace) {
    print("❌ Error in overlay methods: $e");
    print("Stack: $stackTrace");
  }
}

_registerListener(ServiceInstance service) {
  service.on(STOP_MONITORING_SERVICE_KEY).listen((event) {
    FlutterOverlayWindow.closeOverlay();
    service.stopSelf();
  });
}