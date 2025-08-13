import 'dart:async';
import 'dart:io';
import 'package:app_settings/app_settings.dart';

import 'package:call_app/presentation/dashboard/call_event_service.dart';
import 'package:call_app/routes/app_routes.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import 'blocs/auth/auth_cubit.dart';
import 'core/theme.dart';

// Global navigator key for dialogs
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _initFirebase() async => Firebase.initializeApp();

Future<bool> _ensurePermissions() async {
  debugPrint('🔐 Requesting permissions...');

  if (!Platform.isAndroid) return true;

  // Check and request required permissions
  final permissions = [
    Permission.phone,
    Permission.systemAlertWindow,
    Permission.notification,
  ];

  final statuses = await permissions.request();

  // Check if all permissions are granted
  final allGranted = statuses.values.every((status) => status.isGranted);

  if (!allGranted) {
    debugPrint('❌ Some permissions were denied');
    // Show which permissions were denied
    statuses.forEach((permission, status) {
      if (!status.isGranted) {
        debugPrint('❌ Permission denied: $permission - $status');
      }
    });
    return false;
  }

  // Special handling for overlay permission
  if (Platform.isAndroid) {
    final hasOverlayPermission = await _checkOverlayPermission();
    if (!hasOverlayPermission) {
      debugPrint('⚠️ Overlay permission not granted');
      await _showOverlayPermissionInstructions();
      return false;
    }
  }

  return true;
}

Future<bool> _checkOverlayPermission() async {
  bool? hasPermission = await FlutterOverlayWindow.isPermissionGranted();

  if (!hasPermission) {
    // Try requesting permission directly
    hasPermission = await FlutterOverlayWindow.requestPermission();

    // If still not granted, open settings
    if (!hasPermission!) {
      await AppSettings.openAppSettings(
          type: AppSettingsType.settings
      );
      // Check again after returning from settings
      await Future.delayed(const Duration(seconds: 2));
      hasPermission = await FlutterOverlayWindow.isPermissionGranted();
    }
  }

  return hasPermission;
}

Future<void> _showOverlayPermissionInstructions() async {
  final deviceInfo = DeviceInfoPlugin();
  final androidInfo = await deviceInfo.androidInfo;
  final manufacturer = androidInfo.manufacturer.toLowerCase();

  String instructions = 'Please enable "Display over other apps" permission '
      'in your device settings to use overlay feature.';

  if (manufacturer.contains('xiaomi') || manufacturer.contains('redmi')) {
    instructions += '\n\nFor Xiaomi devices: Go to Settings > Apps > Manage apps > '
        'Your App > Other permissions > Display pop-up windows';
  } else if (manufacturer.contains('oppo') || manufacturer.contains('realme')) {
    instructions += '\n\nFor Oppo/Realme devices: Go to Settings > Apps > '
        'Your App > Floating window management';
  } else if (manufacturer.contains('vivo')) {
    instructions += '\n\nFor Vivo devices: Go to Settings > More settings > '
        'Applications > Your App > Floating window';
  }

  debugPrint('📋 Overlay permission instructions: $instructions');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('🚀 App starting...');

  await _initFirebase();
  debugPrint('✅ Firebase initialized');

  final permissionsGranted = await _ensurePermissions();
  debugPrint('Permissions granted: $permissionsGranted');

  // Set the navigator key for CallEventService
  CallEventService.setNavigatorKey(navigatorKey);

  // Initialize overlay listener
  await FlutterOverlayWindow.overlayListener.listen((data) {
    debugPrint('📨 Main received overlay data: $data');
  });

  // Initialize call tracking service
  try {
    await CallEventService.instance.init();
    debugPrint('✅ Call tracking initialized');

    // Test overlay after initialization with delay to ensure app is ready
    Timer(const Duration(seconds: 5), () {
      debugPrint('🧪 Running overlay test...');
      CallEventService.instance.testOverlay();
    });
  } catch (e) {
    debugPrint('❌ Failed to initialize call tracking: $e');
  }

  runApp(
    BlocProvider(
      create: (_) => AuthCubit()..checkAuthStatus(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(404.47, 889),
      builder: (_, __) => MaterialApp(
        navigatorKey: navigatorKey, // Add the navigator key here
        title: 'CallApp',
        theme: appTheme,
        initialRoute: '/',
        routes: AppRoutes.routes,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}