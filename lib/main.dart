import 'dart:async';
import 'dart:io';

import 'package:call_app/presentation/dashboard/call_event_service.dart';
import 'package:call_app/presentation/dashboard/model/call_record_model.dart';
import 'package:call_app/presentation/dashboard/widgets/call_tracking.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'presentation/dashboard/overlay_entity.dart' show overlayMain;
import 'blocs/auth/auth_cubit.dart';
import 'core/theme.dart';

// Global navigator key for dialogs
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _initFirebase() async => Firebase.initializeApp();
Future<bool> _ensurePermissions() async {
  debugPrint('🔐 Requesting permissions...');
  print('🔐 Requesting permissions...');

  if (!Platform.isAndroid) return true;

  // Request all necessary permissions
  final permissions = [
    Permission.phone,
    Permission.systemAlertWindow,
    Permission.notification,
  ];

  Map<Permission, PermissionStatus> statuses = await permissions.request();

  // Log permission statuses
  statuses.forEach((permission, status) {
    debugPrint('Permission ${permission.toString()}: ${status.toString()}');
    print('Permission ${permission.toString()}: ${status.toString()}');
  });

  // Check overlay permission separately
  if (Platform.isAndroid) {
    final overlayPermission = await FlutterOverlayWindow.isPermissionGranted();
    debugPrint('Overlay permission granted: $overlayPermission');
    print('Overlay permission granted: $overlayPermission');

    if (!overlayPermission) {
      debugPrint('⚠️ Requesting overlay permission...');
      print('⚠️ Requesting overlay permission...');
      final granted = await FlutterOverlayWindow.requestPermission();
      debugPrint('Overlay permission after request: $granted');
      print('Overlay permission after request: $granted');
    }
  }

  return true;
}

// Background service entry point
@pragma('vm:entry-point')
void onBackgroundServiceStart(ServiceInstance service) async {
  log('🔄 Background service started');

  // CRITICAL: Start foreground notification immediately for Android
  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: "Call Tracking Active",
      content: "Initializing call monitoring...",
    );
    log('✅ Foreground notification set immediately');
  }

  try {
    // Initialize call state monitoring
    final callService = CallTrackingService.instance;
    await callService.initialize();

    // Start monitoring call states
    await callService.startCallStateMonitoring();
    log('✅ Call monitoring initialized');

    // Update notification
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "Call Tracking Active",
        content: "Monitoring calls in background",
      );
    }
  } catch (e) {
    log('❌ Error in background service: $e');
    // Still keep the service running with error notification
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "Call Tracking Error",
        content: "Service running but monitoring failed",
      );
    }
  }

  service.on('stopService').listen((event) {
    log('🛑 Stopping background service');
    try {
      CallTrackingService.instance.stopCallStateMonitoring();
    } catch (e) {
      log('Error stopping call monitoring: $e');
    }
    service.stopSelf();
  });

  // Keep service alive and update notification periodically
  Timer.periodic(const Duration(seconds: 30), (timer) async {
    if (service is AndroidServiceInstance) {
      try {
        service.setForegroundNotificationInfo(
          title: "Call Tracking Active",
          content:
              "Last update: ${DateTime.now().toString().substring(11, 19)}",
        );
      } catch (e) {
        log('Error updating notification: $e');
      }
    }
  });
}

Future<void> _initBackgroundService({required bool useForeground}) async {
  log('🚀 Initializing background service...');

  final service = FlutterBackgroundService();

  try {
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onBackgroundServiceStart,
        autoStart: true,
        isForegroundMode: true, // Always use foreground mode for stability
        notificationChannelId: 'call_tracking_channel',
        initialNotificationTitle: 'Call Tracking Service',
        initialNotificationContent: 'Starting call monitoring service...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onBackgroundServiceStart,
        // onBackground: onBackgroundServiceStart,
      ),
    );

    // Add small delay before starting service
    await Future.delayed(const Duration(milliseconds: 500));

    final isRunning = await service.isRunning();
    if (!isRunning) {
      await service.startService();
      log('✅ Background service started');
    } else {
      log('✅ Background service already running');
    }
  } catch (e) {
    log('❌ Failed to initialize background service: $e');
    // Try to start without foreground mode as fallback
    try {
      await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: onBackgroundServiceStart,
          autoStart: false,
          isForegroundMode: false,
          notificationChannelId: 'call_tracking_fallback',
          initialNotificationTitle: 'Call Tracking (Fallback)',
          initialNotificationContent: 'Running in background mode',
          foregroundServiceNotificationId: 889,
        ),
        iosConfiguration: IosConfiguration(
          autoStart: true,
          onForeground: onBackgroundServiceStart,
        ),
      );
      await service.startService();
      log('✅ Background service started in fallback mode');
    } catch (fallbackError) {
      log('❌ Fallback background service also failed: $fallbackError');
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('🚀 App starting...');
  print('🚀 App starting...'); // Use both print and debugPrint

  FlutterError.onError = (details) {
    if (details.exception.toString().contains('GraphicBuffer')) {
      print('Non-critical graphics error: ${details.exception}');
      return;
    }
    FlutterError.presentError(details);
  };

  await _initFirebase();
  debugPrint('✅ Firebase initialized');
  print('✅ Firebase initialized');

  final permissionsGranted = await _ensurePermissions();
  debugPrint('Permissions granted: $permissionsGranted');
  print('Permissions granted: $permissionsGranted');

  // TEMPORARILY DISABLE background service to fix crashes
  // TODO: Re-enable once notification channels are properly configured
  // await _initBackgroundService(useForeground: true);
  debugPrint('⚠️ Background service disabled temporarily');
  print('⚠️ Background service disabled temporarily');

  // Initialize call tracking service directly in main app
  try {
    debugPrint('🔄 Initializing call tracking service...');
    print('🔄 Initializing call tracking service...');

    final callService = CallTrackingService.instance;
    await callService.initialize();

    debugPrint('🔄 Starting call state monitoring...');
    print('🔄 Starting call state monitoring...');

    await callService.startCallStateMonitoring();

    debugPrint('✅ Call tracking initialized in main app');
    print('✅ Call tracking initialized in main app');

    // Test overlay immediately
    debugPrint('🧪 Testing overlay immediately...');
    print('🧪 Testing overlay immediately...');
    _testOverlayImmediately();
  } catch (e) {
    debugPrint('❌ Failed to initialize call tracking: $e');
    print('❌ Failed to initialize call tracking: $e');
  }

  FlutterError.onError = (FlutterErrorDetails details) {
    final msg = details.exception.toString();
    if (msg.contains('GraphicBuffer') || msg.contains('qdgralloc')) {
      debugPrint('Graphics error (non-fatal): ${details.exception}');
      return;
    }
    debugPrint('Flutter Error: ${details.exception}');
    print('Flutter Error: ${details.exception}');
    FlutterError.presentError(details);
  };

  runApp(
    BlocProvider(
      create: (_) => AuthCubit()..checkAuthStatus(),
      child: const MyApp(),
    ),
  );
}

// Test overlay function that runs immediately - FIXED VERSION
Future<void> _testOverlayImmediately() async {
  // Wait a bit for app to initialize
  await Future.delayed(const Duration(seconds: 2));

  try {
    debugPrint('🔍 Checking overlay permission...');
    print('🔍 Checking overlay permission...');

    final hasPermission = await FlutterOverlayWindow.isPermissionGranted();
    debugPrint('Overlay permission granted: $hasPermission');
    print('Overlay permission granted: $hasPermission');

    if (!hasPermission) {
      debugPrint('⚠️ Requesting overlay permission...');
      print('⚠️ Requesting overlay permission...');

      final granted = await FlutterOverlayWindow.requestPermission();
      debugPrint('Overlay permission after request: $granted');
      print('Overlay permission after request: $granted');

      if (!granted!) {
        debugPrint('❌ Overlay permission denied by user');
        print('❌ Overlay permission denied by user');
        return;
      }
    }

    debugPrint('🔄 Attempting to show overlay...');
    print('🔄 Attempting to show overlay...');

    // Close any existing overlay first
    try {
      if (await FlutterOverlayWindow.isActive()) {
        await FlutterOverlayWindow.closeOverlay();
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      debugPrint('Error closing existing overlay: $e');
      print('Error closing existing overlay: $e');
    }

    // FIXED: Show overlay with correct parameters
    await FlutterOverlayWindow.showOverlay(
      enableDrag: true,
      overlayTitle: 'Test Overlay',
      overlayContent: 'Testing overlay on startup',
      flag: OverlayFlag.defaultFlag,
      alignment: OverlayAlignment.topCenter,
      visibility: NotificationVisibility.visibilityPublic,
      positionGravity: PositionGravity.auto,
      height: 250,
      width: WindowSize.matchParent,
    );

    // Wait a moment for overlay to initialize
    await Future.delayed(const Duration(milliseconds: 500));

    debugPrint('📡 Sending data to overlay...');
    print('📡 Sending data to overlay...');

    await FlutterOverlayWindow.shareData({
      'title': 'Startup Test',
      'subtitle':
          'App started successfully!\nTime: ${DateTime.now().toString().substring(11, 19)}',
      'callState': 'test',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    debugPrint('✅ Test overlay should be displayed now!');
    print('✅ Test overlay should be displayed now!');

    // Auto-hide after 10 seconds
    Future.delayed(const Duration(seconds: 10), () async {
      try {
        await FlutterOverlayWindow.closeOverlay();
        debugPrint('🚫 Test overlay closed automatically');
        print('🚫 Test overlay closed automatically');
      } catch (e) {
        debugPrint('Error closing test overlay: $e');
        print('Error closing test overlay: $e');
      }
    });
  } catch (e) {
    debugPrint('❌ Failed to show test overlay: $e');
    print('❌ Failed to show test overlay: $e');
  }
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
    _testCallMonitoring();
  }

  void _testCallMonitoring() {
    debugPrint('🔄 Setting up call monitoring test...');
    print('🔄 Setting up call monitoring test...');

    // Listen to call state changes for testing
    CallTrackingService.instance.callStateStream.listen((callRecord) {
      debugPrint(
        '📞 Call state changed: ${callRecord.phoneNumber} - ${callRecord.state}',
      );
      print(
        '📞 Call state changed: ${callRecord.phoneNumber} - ${callRecord.state}',
      );

      // Test overlay display
      _showTestOverlay(callRecord);
    });
  }

  // FIXED: Show test overlay with correct parameters
  Future<void> _showTestOverlay(CallRecord callRecord) async {
    try {
      debugPrint('🔔 Attempting to show call overlay...');
      print('🔔 Attempting to show call overlay...');

      final hasPermission = await FlutterOverlayWindow.isPermissionGranted();
      if (!hasPermission) {
        debugPrint('⚠️ Overlay permission not granted');
        print('⚠️ Overlay permission not granted');
        return;
      }

      // Close existing overlay first
      if (await FlutterOverlayWindow.isActive()) {
        await FlutterOverlayWindow.closeOverlay();
        await Future.delayed(const Duration(milliseconds: 200));
      }

      // FIXED: Show test overlay with correct parameters
      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        overlayTitle: 'Call State Change',
        overlayContent:
            'Number: ${callRecord.phoneNumber}\nState: ${callRecord.state}',
        flag: OverlayFlag.defaultFlag,
        alignment: OverlayAlignment.topCenter,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.auto,
        height: 200,
        width: WindowSize.matchParent,
      );

      // Wait for overlay to initialize
      await Future.delayed(const Duration(milliseconds: 300));

      await FlutterOverlayWindow.shareData({
        'title': 'Call State Change',
        'subtitle':
            'Number: ${callRecord.phoneNumber}\nState: ${callRecord.state}',
        'callState': callRecord.state.toString(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      debugPrint(
        '✅ Test overlay displayed for call: ${callRecord.phoneNumber}',
      );
      print('✅ Test overlay displayed for call: ${callRecord.phoneNumber}');

      // Auto-hide after 3 seconds for testing
      Future.delayed(const Duration(seconds: 3), () {
        FlutterOverlayWindow.closeOverlay();
      });
    } catch (e) {
      debugPrint('❌ Failed to show test overlay: $e');
      print('❌ Failed to show test overlay: $e');
    }
  }

  // FIXED: Test method to manually trigger overlay
  Future<void> _testOverlayManually() async {
    log('🧪 Testing overlay manually...');

    try {
      final hasPermission = await FlutterOverlayWindow.isPermissionGranted();
      if (!hasPermission) {
        log('⚠️ Requesting overlay permission...');
        final granted = await FlutterOverlayWindow.requestPermission();
        if (!granted!) {
          log('❌ Overlay permission denied');
          return;
        }
      }

      // FIXED: Show overlay with correct parameters
      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        overlayTitle: 'Test Overlay',
        overlayContent: 'This is a test overlay',
        flag: OverlayFlag.defaultFlag,
        alignment: OverlayAlignment.topCenter,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.auto,
        height: 200,
        width: WindowSize.matchParent,
      );

      // Wait for overlay to initialize
      await Future.delayed(const Duration(milliseconds: 300));

      await FlutterOverlayWindow.shareData({
        'title': 'Test Overlay',
        'subtitle': 'Manual test overlay\nTime: ${DateTime.now().toString()}',
        'callState': 'test',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      log('✅ Manual test overlay displayed');

      // Auto-hide after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        FlutterOverlayWindow.closeOverlay();
      });
    } catch (e) {
      log('❌ Failed to show manual test overlay: $e');
    }
  }

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
