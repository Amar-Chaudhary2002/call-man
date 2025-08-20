// main.dart - Fixed version
import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:ui';
import 'package:call_app/presentation/dashboard/call_event_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:system_alert_window/system_alert_window.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'blocs/auth/auth_cubit.dart';
import 'notification_utils.dart';
import 'overlay_manager.dart';
import 'routes/app_routes.dart';
import 'core/theme.dart';

// === Overlay isolate entry point ===
@pragma("vm:entry-point")
void overlayMain() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Material(color: Colors.transparent, child: CallOverlayWidget()),
  ));
}

class CallOverlayWidget extends StatefulWidget {
  const CallOverlayWidget({Key? key}) : super(key: key);

  @override
  State<CallOverlayWidget> createState() => _CallOverlayWidgetState();
}

class _CallOverlayWidgetState extends State<CallOverlayWidget> {
  String title = 'Call Status';
  String subtitle = 'Initializing...';
  String callState = 'idle';
  String phoneNumber = '';
  String currentTime = '';
  Timer? _timeTimer;

  @override
  void initState() {
    super.initState();

    // Update time every second
    _timeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        currentTime = DateTime.now().toString().substring(11, 19);
      });
    });

    // Listen for messages from the app/service
    SystemAlertWindow.overlayListener.listen((data) {
      log("Overlay received data: $data");
      if (data is Map && mounted) {
        setState(() {
          title = data['title']?.toString() ?? 'Call Status';
          subtitle = data['subtitle']?.toString() ?? '';
          callState = data['callState']?.toString() ?? 'idle';
          phoneNumber = data['phoneNumber']?.toString() ?? '';
        });
      }
    });
  }

  @override
  void dispose() {
    _timeTimer?.cancel();
    super.dispose();
  }

  Future<void> _closeOverlay() async {
    try {
      // Inform the app that user closed the overlay
      final sendPort = IsolateNameServer.lookupPortByName('overlay_to_app_port');
      sendPort?.send({'action': 'overlay_closed_by_user'});

      await SystemAlertWindow.closeSystemWindow(prefMode: SystemWindowPrefMode.OVERLAY);
    } catch (e) {
      log("Error closing overlay: $e");
    }
  }

  Color _getCallStateColor() {
    switch (callState.toLowerCase()) {
      case 'ringing':
      case 'incoming':
        return Colors.blue;
      // case 'active':
      // case 'started':
      //   return Colors.green;
      case 'ended':
      case 'disconnected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _getCallStateIcon() {
    switch (callState.toLowerCase()) {
      case 'ringing':
      case 'incoming':
        return Icons.phone_in_talk;
      case 'active':
      case 'started':
        return Icons.call;
      case 'ended':
      case 'disconnected':
        return Icons.call_end;
      default:
        return Icons.phone;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateColor = _getCallStateColor();

    return Center(
      child: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 350, maxHeight: 200),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: stateColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(_getCallStateIcon(), color: stateColor, size: 20),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: stateColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: _closeOverlay,
                      borderRadius: BorderRadius.circular(15),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close, size: 18, color: Colors.red),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Phone number (if available)
                if (phoneNumber.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: stateColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      phoneNumber,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Subtitle
                if (subtitle.isNotEmpty) ...[
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                ],

                // Current time
                Text(
                  'Time: $currentTime',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// === Main App Setup ===
Future<void> _initFirebase() async => Firebase.initializeApp();

// Replace the permissions section in _ensurePermissions() method
Future<bool> _ensurePermissions() async {
  log('🔐 Requesting permissions...');

  if (!Platform.isAndroid) return true;

  // Check phone permission first - use the correct permission constant
  final phoneStatus = await Permission.phone.status;
  if (phoneStatus.isGranted) {
    log('📱 Phone permission already granted');
  } else {
    final phoneResult = await Permission.phone.request();
    if (!phoneResult.isGranted) {
      log('❌ Phone permission denied');
      return false;
    }
  }

  // Request notification permission (critical for Android 13+)
  final notificationStatus = await Permission.notification.status;
  if (!notificationStatus.isGranted) {
    log('🔔 Requesting notification permission...');
    final notificationResult = await Permission.notification.request();
    if (!notificationResult.isGranted) {
      log('❌ Notification permission denied - this will cause service issues');
    }
  }

  // Request other permissions using the correct constants
  final permissionsToRequest = [
    Permission.ignoreBatteryOptimizations,
  ];

  // For Android, request additional call-related permissions
  if (Platform.isAndroid) {
    permissionsToRequest.addAll([
      Permission.manageExternalStorage, // For call log access
      Permission.accessNotificationPolicy, // For call state access
    ]);
  }

  Map<Permission, PermissionStatus> statuses = await permissionsToRequest.request();

  // Log permission statuses
  statuses.forEach((permission, status) {
    log('Permission ${permission.toString()}: ${status.toString()}');
  });

  // Check and request system alert window permission specifically
  final overlayPermission = await SystemAlertWindow.checkPermissions();
  log('System overlay permission status: $overlayPermission');

  if (overlayPermission == null || !overlayPermission) {
    log('⚠️ Requesting system overlay permission...');
    try {
      final granted = await SystemAlertWindow.requestPermissions();
      log('System overlay permission after request: $granted');

      if (granted == null || !granted) {
        log('❌ System overlay permission denied');
        return false;
      }
    } catch (e) {
      log('❌ Error requesting system overlay permission: $e');
      return false;
    }
  }

  final phoneGranted = await Permission.phone.status.then((s) => s.isGranted);
  final overlayGranted = overlayPermission == true;
  final notificationGranted = await Permission.notification.status.then((s) => s.isGranted);

  log('Final permissions - Phone: $phoneGranted, Overlay: $overlayGranted, Notifications: $notificationGranted');
  return phoneGranted && overlayGranted;
}

Future<void> _showPermissionEducationDialog(BuildContext context) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.security, color: Colors.orange),
          SizedBox(width: 8),
          Flexible(child: Text('Permissions Required')),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('For call tracking and overlay features to work properly, please enable:'),
          SizedBox(height: 12),
          Text('1. Phone permissions - to detect call states'),
          Text('2. Notifications - for background service alerts'),
          Text('3. Display over other apps - for call overlays'),
          Text('4. Background activity - keep service running'),
          Text('5. Disable battery optimization - prevent killing'),
          SizedBox(height: 8),
          Text('(MIUI users: Enable "Display pop-up windows while running in background")'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Later'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            await _ensurePermissions();
          },
          child: const Text('Grant Permissions'),
        ),
      ],
    ),
  );
}

// FIXED: Background service with proper notification handling
@pragma('vm:entry-point')
void onBackgroundServiceStart(ServiceInstance service) async {
  log('🔄 Background service started in isolate');

  // CRITICAL: Initialize plugins in background isolate
  DartPluginRegistrant.ensureInitialized();

  // Initialize notification channel
  await NotificationUtils.initialize();

  // ANDROID-SPECIFIC: Handle Android services with proper error handling
  if (service is AndroidServiceInstance) {
    log('📱 Configuring Android service...');

    try {
      // Start as background service first
      service.setAsBackgroundService();
      log('✅ Set as background service');

      // Wait a moment before attempting foreground
      await Future.delayed(const Duration(seconds: 2));

      // Try to set as foreground with proper notification
      service.setForegroundNotificationInfo(
        title: "Call Tracking",
        content: "Monitoring calls in background",
      );

      service.setAsForegroundService();
      log('✅ Successfully set as foreground service');

    } catch (e) {
      log('❌ Foreground service failed, continuing as background: $e');
      // Continue as background service if foreground fails
      service.setAsBackgroundService();
    }

    // Set up service event listeners with error handling
    try {
      service.on('setAsBackground').listen((event) {
        try {
          service.setAsBackgroundService();
          log('📢 Service set to background on request');
        } catch (e) {
          log('❌ Error setting background on request: $e');
        }
      });

      service.on('setAsForeground').listen((event) {
        try {
          service.setAsForegroundService();
          log('📢 Service set to foreground on request');
        } catch (e) {
          log('❌ Error setting foreground on request: $e');
        }
      });
    } catch (e) {
      log('❌ Error setting up service listeners: $e');
    }
  }

  // Set up port communication
  try {
    OverlayManager.setupBackgroundPorts();
    log('✅ Background ports setup complete');
  } catch (e) {
    log('❌ Error setting up ports: $e');
  }

  // Initialize call tracking with proper delay and error handling
  try {
    log('⏳ Waiting before initializing call tracking...');
    await Future.delayed(const Duration(seconds: 3));

    final callService = CallEventService();
    await callService.init();
    log('✅ Call monitoring initialized in background service');

    // Listen for overlay close requests
    CallEventService.onOverlayCloseRequest = () async {
      try {
        await SystemAlertWindow.closeSystemWindow(prefMode: SystemWindowPrefMode.OVERLAY);
        log('✅ Overlay closed from background service');
      } catch (e) {
        log('❌ Error closing overlay from background: $e');
      }
    };

  } catch (e) {
    log('❌ Error initializing call service in background: $e');
  }

  // Handle service stop
  service.on('stopService').listen((event) async {
    log('🛑 Stopping background service');
    try {
      await CallEventService.dispose();
      await SystemAlertWindow.closeSystemWindow(prefMode: SystemWindowPrefMode.OVERLAY);
      OverlayManager.cleanup();
    } catch (e) {
      log('Error during service cleanup: $e');
    }
    service.stopSelf();
  });

  // Keep service alive with periodic updates
  Timer.periodic(const Duration(minutes: 15), (timer) async {
    if (service is AndroidServiceInstance) {
      try {
        final now = DateTime.now().toString().substring(11, 19);
        service.setForegroundNotificationInfo(
          title: "Call Tracking Active",
          content: "Heartbeat: $now",
        );
      } catch (e) {
        log('Error in periodic notification update: $e');
      }
    }
  });
}

// FIXED: Background service configuration
Future<void> _initBackgroundService() async {
  log('🚀 Initializing background service configuration...');

  final service = FlutterBackgroundService();

  try {
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onBackgroundServiceStart,
        autoStart: false, // Manual start only
        isForegroundMode: true,
        notificationChannelId: 'call_tracking_service_channel',
        // notificationChannelName: 'Call Tracking Service',
        // notificationChannelDescription: 'Monitors incoming and outgoing calls',
        initialNotificationTitle: 'Call Tracking Service',
        initialNotificationContent: 'Preparing to monitor calls...',
        foregroundServiceNotificationId: 999, // Unique ID
        autoStartOnBoot: false, // Prevent auto-start issues
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onBackgroundServiceStart,
      ),
    );

    log('✅ Background service configured successfully');

    // Test service configuration
    final isConfigured = await service.isRunning();
    log('🔍 Service configuration test - IsRunning: $isConfigured');

  } catch (e) {
    log('❌ Failed to configure background service: $e');
    // Don't rethrow - let the app continue without background service
  }
}

Future<void> _startBackgroundService() async {
  log('🚀 Starting background service...');

  try {
    final service = FlutterBackgroundService();

    // Check current status
    final isCurrentlyRunning = await service.isRunning();
    log('📊 Current service status: $isCurrentlyRunning');

    if (!isCurrentlyRunning) {
      log('🔄 Service not running, starting now...');

      // Give system time
      await Future.delayed(const Duration(milliseconds: 1000));

      final startResult = await service.startService();
      log('📋 Service start result: $startResult');

      if (startResult) {
        log('✅ Background service started successfully');

        // Verify startup with multiple checks
        for (int i = 0; i < 3; i++) {
          await Future.delayed(const Duration(seconds: 2));
          final isNowRunning = await service.isRunning();
          log('🔍 Service verification check ${i + 1}: $isNowRunning');

          if (isNowRunning) {
            log('✅ Service verified running after ${(i + 1) * 2} seconds');
            break;
          }
        }
      } else {
        log('❌ Service start returned false');
      }
    } else {
      log('✅ Background service already running');
    }

  } catch (e) {
    log('❌ Exception during service startup: $e');
    log('🔄 Service may still work despite this error');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  log('🚀 App starting...');

  // ENHANCED: Better error handling with specific error filtering
  FlutterError.onError = (details) {
    final msg = details.exception.toString();

    // Filter out known non-fatal errors
    final nonFatalErrors = [
      'GraphicBuffer', 'qdgralloc', 'AdrenoUtils', 'Gralloc4',
      'AHardwareBuffer', 'format 56', 'Unknown Format',
      'AccessibilityNodeInfo', 'AccessibilityRecord', 'LongArray',
      'incremental_prop', 'miuilog', 'data_log_file'
    ];

    if (nonFatalErrors.any((error) => msg.contains(error))) {
      log('Non-fatal system warning: ${details.exception}');
      return;
    }

    // Log actual Flutter errors
    log('Flutter Error: ${details.exception}');
    log('Stack trace: ${details.stack}');
    FlutterError.presentError(details);
  };

  try {
    // Initialize Firebase
    await _initFirebase();
    log('✅ Firebase initialized');

    // Initialize notification channel
    await NotificationUtils.initialize();
    log('✅ Notification channel initialized');

    // Initialize background service configuration
    await _initBackgroundService();
    log('✅ Background service configured');

    // Set up overlay manager
    OverlayManager.initialize();
    log('✅ Overlay manager initialized');

    log('🎉 App initialization completed successfully');

  } catch (e) {
    log('❌ Critical error during app initialization: $e');
    // Continue anyway - app might still work partially
  }

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

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _permissionsGranted = false;
  bool _serviceInitialized = false;
  String _initStatus = 'Initializing...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    OverlayManager.cleanup();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    log("App lifecycle state: $state");

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        log('App going background - service continues running');
        break;
      case AppLifecycleState.resumed:
        log('App resumed - checking service status');
        _checkServiceStatus();
        break;
      default:
        break;
    }
  }

  Future<void> _initializeApp() async {
    setState(() {
      _initStatus = 'Checking permissions...';
    });

    // Show permission education first if needed
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final hasPermissions = await _checkExistingPermissions();
      if (!hasPermissions && mounted) {
        await _showPermissionEducationDialog(context);
      }
      await _requestPermissionsAndInitialize();
    });
  }

  Future<bool> _checkExistingPermissions() async {
    try {
      final phoneStatus = await Permission.phone.status;
      final notificationStatus = await Permission.notification.status;
      final overlayStatus = await SystemAlertWindow.checkPermissions();

      log('Existing permissions - Phone: ${phoneStatus.isGranted}, Notifications: ${notificationStatus.isGranted}, Overlay: $overlayStatus');

      return phoneStatus.isGranted && (overlayStatus == true) && notificationStatus.isGranted;
    } catch (e) {
      log('Error checking existing permissions: $e');
      return false;
    }
  }

  Future<void> _requestPermissionsAndInitialize() async {
    try {
      setState(() {
        _initStatus = 'Requesting permissions...';
      });

      // Request all permissions
      final permissionsGranted = await _ensurePermissions();
      setState(() {
        _permissionsGranted = permissionsGranted;
        _initStatus = permissionsGranted ? 'Starting services...' : 'Missing permissions';
      });

      if (permissionsGranted) {
        // Start background service with better error handling
        setState(() {
          _initStatus = 'Initializing background service...';
        });

        await _startBackgroundService();

        setState(() {
          _initStatus = 'Setting up call tracking...';
        });

        // Initialize call tracking in foreground too
        await _initializeForegroundCallTracking();

        setState(() {
          _serviceInitialized = true;
          _initStatus = 'Ready!';
        });

        log('✅ App fully initialized with permissions and services');

        // Test overlay after everything is ready
        Future.delayed(const Duration(seconds: 8), () {
          if (mounted) _testOverlay();
        });
      } else {
        log('❌ App initialized but missing critical permissions');
        setState(() {
          _initStatus = 'Missing critical permissions - limited functionality';
        });
      }
    } catch (e) {
      log('❌ Error during app initialization: $e');
      setState(() {
        _initStatus = 'Initialization error: ${e.toString()}';
      });
    }
  }

  Future<void> _initializeForegroundCallTracking() async {
    try {
      final callService = CallEventService();
      await callService.init();
      log('✅ Foreground call tracking initialized');
    } catch (e) {
      log('❌ Failed to initialize foreground call tracking: $e');
    }
  }

  Future<void> _checkServiceStatus() async {
    try {
      final service = FlutterBackgroundService();
      final isRunning = await service.isRunning();
      log('🔍 Background service status check: $isRunning');

      if (!isRunning && _permissionsGranted) {
        log('🔄 Service not running, attempting restart...');
        setState(() {
          _initStatus = 'Restarting service...';
        });

        await _startBackgroundService();

        if (mounted) {
          setState(() {
            _initStatus = 'Service restarted';
          });
        }
      }
    } catch (e) {
      log('Error checking service status: $e');
    }
  }

  Future<void> _testOverlay() async {
    if (!_permissionsGranted) {
      log('❌ Cannot test overlay - permissions not granted');
      return;
    }

    try {
      log('🧪 Testing overlay system...');

      final success = await OverlayManager.showTestOverlay(
        message: 'System Test - All services initialized successfully!',
        autoCloseDuration: const Duration(seconds: 6),
      );

      if (success) {
        log('✅ Test overlay displayed successfully');
      } else {
        log('❌ Failed to display test overlay');
      }
    } catch (e) {
      log('❌ Failed to show test overlay: $e');
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
          builder: (context, child) {
            // Show initialization status overlay
            return Stack(
              children: [
                child ?? const SizedBox.shrink(),
                if (!_permissionsGranted || !_serviceInitialized)
                  _buildInitializationOverlay(),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildInitializationOverlay() {
    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_permissionsGranted && !_serviceInitialized)
                const CircularProgressIndicator()
              else if (!_permissionsGranted)
                const Icon(Icons.security, size: 48, color: Colors.orange)
              else
                const CircularProgressIndicator(),

              const SizedBox(height: 16),

              Text(
                _initStatus,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              if (!_permissionsGranted) ...[
                const Text(
                  'This app needs phone and notification permissions to work properly.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _requestPermissionsAndInitialize,
                  child: const Text('Grant Permissions'),
                ),
              ] else if (_serviceInitialized) ...[
                const Text(
                  'Initialization complete!',
                  style: TextStyle(fontSize: 14, color: Colors.green),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}