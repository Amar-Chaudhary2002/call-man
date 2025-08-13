import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:call_app/presentation/dashboard/calling_screen.dart';
import 'package:call_app/presentation/dashboard/model/call_record_model.dart';
import 'package:call_app/presentation/dashboard/widgets/call_tracking.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'blocs/auth/auth_cubit.dart';
import 'routes/app_routes.dart';
import 'core/theme.dart';

Future<void> _initFirebase() async => Firebase.initializeApp();
Future<bool> _ensurePermissions() async {
  log('🔐 Requesting permissions...');
  log('🔐 Requesting permissions...');
  if (!Platform.isAndroid) return true;
  final permissions = [
    Permission.phone,
    Permission.systemAlertWindow,
    Permission.notification,
  ];
  Map<Permission, PermissionStatus> statuses = await permissions.request();
  statuses.forEach((permission, status) {
    log('Permission ${permission.toString()}: ${status.toString()}');
    log('Permission ${permission.toString()}: ${status.toString()}');
  });

  if (Platform.isAndroid) {
    final overlayPermission = await FlutterOverlayWindow.isPermissionGranted();
    log('Overlay permission granted: $overlayPermission');
    log('Overlay permission granted: $overlayPermission');

    if (!overlayPermission) {
      log('⚠️ Requesting overlay permission...');
      log('⚠️ Requesting overlay permission...');
      final granted = await FlutterOverlayWindow.requestPermission();
      log('Overlay permission after request: $granted');
      log('Overlay permission after request: $granted');
    }
  }

  return statuses[Permission.phone]?.isGranted == true &&
      statuses[Permission.systemAlertWindow]?.isGranted == true;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  log('🚀 App starting...');
  log('🚀 App starting...');

  FlutterError.onError = (details) {
    if (details.exception.toString().contains('GraphicBuffer')) {
      log('Non-critical graphics error: ${details.exception}');
      return;
    }
    FlutterError.presentError(details);
  };

  await _initFirebase();
  log('✅ Firebase initialized');
  log('✅ Firebase initialized');
  final permissionsGranted = await _ensurePermissions();
  log('Permissions granted: $permissionsGranted');
  log('Permissions granted: $permissionsGranted');
  log('⚠️ Background service disabled temporarily');
  log('⚠️ Background service disabled temporarily');
  try {
    log('🔄 Initializing call tracking service...');
    log('🔄 Initializing call tracking service...');
    final callService = CallTrackingService.instance;
    await callService.initialize();
    log('🔄 Starting call state monitoring...');
    log('🔄 Starting call state monitoring...');
    await callService.startCallStateMonitoring();
    log('✅ Call tracking initialized in main app');
    log('✅ Call tracking initialized in main app');
  } catch (e) {
    log('❌ Failed to initialize call tracking: $e');
    log('❌ Failed to initialize call tracking: $e');
  }

  FlutterError.onError = (FlutterErrorDetails details) {
    final msg = details.exception.toString();
    if (msg.contains('GraphicBuffer') || msg.contains('qdgralloc')) {
      log('Graphics error (non-fatal): ${details.exception}');
      return;
    }
    log('Flutter Error: ${details.exception}');
    log('Flutter Error: ${details.exception}');
    FlutterError.presentError(details);
  };

  runApp(
    BlocProvider(
      create: (_) => AuthCubit()..checkAuthStatus(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupCallMonitoring();
  }

  void _setupCallMonitoring() {
    log('🔄 Setting up call monitoring...');
    log('🔄 Setting up call monitoring...');

    CallTrackingService.instance.callStateStream.listen((callRecord) {
      log(
        '📞 Call state changed: ${callRecord.phoneNumber} - ${callRecord.state}',
      );
      log(
        '📞 Call state changed: ${callRecord.phoneNumber} - ${callRecord.state}',
      );

      // Show overlay for incoming calls and call end
      if (callRecord.state == CallState.ringing ||
          callRecord.state == CallState.disconnected) {
        _showCallOverlay(callRecord);
      }
    });
  }

  Future<void> _showCallOverlay(CallRecord callRecord) async {
    try {
      log('🔔 Showing overlay for call state: ${callRecord.state}');
      log('🔔 Showing overlay for call state: ${callRecord.state}');

      final hasPermission = await FlutterOverlayWindow.isPermissionGranted();
      if (!hasPermission) {
        log('⚠️ No overlay permission');
        log('⚠️ No overlay permission');
        return;
      }

      // Close existing overlay first
      try {
        if (await FlutterOverlayWindow.isActive()) {
          await FlutterOverlayWindow.closeOverlay();
          await Future.delayed(const Duration(milliseconds: 300));
        }
      } catch (e) {
        log('Error closing existing overlay: $e');
        log('Error closing existing overlay: $e');
      }

      // Try different overlay methods until one works
      bool overlayShown = false;
      // Method 1: Minimal overlay (most compatible)
      if (!overlayShown) {
        try {
          await FlutterOverlayWindow.showOverlay();
          await Future.delayed(const Duration(milliseconds: 800));
          overlayShown = await FlutterOverlayWindow.isActive();
          if (overlayShown) {
            log('✅ Method 1 (minimal) worked');
            log('✅ Method 1 (minimal) worked');
          }
        } catch (e) {
          log('❌ Method 1 failed: $e');
          log('❌ Method 1 failed: $e');
        }
      }

      // Method 2: Basic with enableDrag
      if (!overlayShown) {
        try {
          await FlutterOverlayWindow.showOverlay(enableDrag: true);
          await Future.delayed(const Duration(milliseconds: 800));
          overlayShown = await FlutterOverlayWindow.isActive();
          if (overlayShown) {
            log('✅ Method 2 (basic drag) worked');
            log('✅ Method 2 (basic drag) worked');
          }
        } catch (e) {
          log('❌ Method 2 failed: $e');
          log('❌ Method 2 failed: $e');
        }
      }

      // Method 3: Focus pointer (for problematic devices)
      if (!overlayShown) {
        try {
          await FlutterOverlayWindow.showOverlay(
            enableDrag: false,
            flag: OverlayFlag.focusPointer,
            alignment: OverlayAlignment.topCenter,
          );
          await Future.delayed(const Duration(milliseconds: 1000));
          overlayShown = await FlutterOverlayWindow.isActive();
          if (overlayShown) {
            log('✅ Method 3 (focus pointer) worked');
            log('✅ Method 3 (focus pointer) worked');
          }
        } catch (e) {
          log('❌ Method 3 failed: $e');
          log('❌ Method 3 failed: $e');
        }
      }

      // Method 4: Small size (last resort)
      if (!overlayShown) {
        try {
          await FlutterOverlayWindow.showOverlay(
            enableDrag: true,
            height: 120,
            width: WindowSize.fullCover,
            alignment: OverlayAlignment.center,
          );
          await Future.delayed(const Duration(milliseconds: 1000));
          overlayShown = await FlutterOverlayWindow.isActive();
          if (overlayShown) {
            log('✅ Method 4 (small size) worked');
            log('✅ Method 4 (small size) worked');
          }
        } catch (e) {
          log('❌ Method 4 failed: $e');
          log('❌ Method 4 failed: $e');
        }
      }

      if (overlayShown) {
        // Send data to overlay
        log('📡 Sending data to overlay...');
        log('📡 Sending data to overlay...');

        String title = '';
        String subtitle = '';
        String stateString = '';

        if (callRecord.state == CallState.ringing) {
          title = 'Incoming Call';
          subtitle = 'From: ${callRecord.phoneNumber}';
          stateString = 'ringing';
        } else if (callRecord.state == CallState.disconnected) {
          title = 'Call Ended';
          subtitle = 'With: ${callRecord.phoneNumber}';
          stateString = 'disconnected';
        }

        await FlutterOverlayWindow.shareData({
          'title': title,
          'subtitle': subtitle,
          'callState': stateString,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });

        log('✅ Call overlay displayed successfully');
        log('✅ Call overlay displayed successfully');

        // Auto-hide overlay
        int hideDelay = callRecord.state == CallState.ringing
            ? 15
            : 5; // 15s for incoming, 5s for ended
        Future.delayed(Duration(seconds: hideDelay), () async {
          try {
            if (await FlutterOverlayWindow.isActive()) {
              await FlutterOverlayWindow.closeOverlay();
              log('🚫 Call overlay closed automatically');
              log('🚫 Call overlay closed automatically');
            }
          } catch (e) {
            log('Error auto-closing overlay: $e');
            log('Error auto-closing overlay: $e');
          }
        });
      } else {
        log('❌ All overlay methods failed');
        log('❌ All overlay methods failed');
      }
    } catch (e) {
      log('❌ Error showing call overlay: $e');
      log('❌ Error showing call overlay: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(404.47, 889),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'CallMan',
          theme: appTheme,
          initialRoute: '/',
          routes: AppRoutes.routes,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
