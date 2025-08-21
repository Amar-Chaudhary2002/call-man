// main.dart - Updated with navigation handling
import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:call_app/permission_manager.dart';
import 'package:call_app/presentation/dashboard/call_event_service.dart';
import 'package:call_app/presentation/dashboard/call_features/call_end_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:system_alert_window/system_alert_window.dart';

import 'blocs/auth/auth_cubit.dart';
import 'notification_utils.dart';
import 'overlay_manager.dart';
import 'routes/app_routes.dart';
import 'core/theme.dart';

// === Overlay isolate entry point ===
@pragma("vm:entry-point")
void overlayMain() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(color: Colors.transparent, child: CallOverlayWidget()),
    ),
  );
}

// Enhanced overlay widget with responsive design
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
  String callId = '';
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
          callId = data['callId']?.toString() ?? '';
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
      final sendPort = IsolateNameServer.lookupPortByName(
        'overlay_to_app_port',
      );
      sendPort?.send({'action': 'overlay_closed_by_user', 'callId': callId});

      // Use overlay manager to close properly
      OverlayManager.closeOverlay();
    } catch (e) {
      log("Error closing overlay: $e");
    }
  }

  Future<void> _openCallInteraction() async {
    try {
      log("🔄 Opening call interaction screen...");

      // Send message to main app to navigate
      final sendPort = IsolateNameServer.lookupPortByName(
        'overlay_to_app_port',
      );

      if (sendPort != null) {
        sendPort.send({
          'action': 'open_call_interaction',
          'phoneNumber': phoneNumber,
          'callState': callState,
          'callId': callId,
          'timestamp': DateTime.now().toIso8601String(),
        });

        log("✅ Navigation message sent to main app");

        // Close overlay after sending navigation request
        await Future.delayed(const Duration(milliseconds: 300));
        await _closeOverlay();
      } else {
        log("❌ Could not find overlay_to_app_port");

        // Fallback: try to bring app to foreground
        try {
          // This might work on some Android versions
          await SystemAlertWindow.closeSystemWindow();
        } catch (e) {
          log("Failed to close system window: $e");
        }
      }
    } catch (e) {
      log("❌ Error opening call interaction: $e");
    }
  }

  Color _getCallStateColor() {
    switch (callState.toLowerCase()) {
      case 'ringing':
      case 'incoming':
        return Colors.blue;
      case 'ended':
      case 'disconnected':
        return Colors.red;
      case 'active':
      case 'started':
        return Colors.green;
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

    // Get screen dimensions for responsive design
    final screenSize = MediaQuery.of(context).size;
    final maxWidth = screenSize.width * 0.9; // 90% of screen width
    final maxHeight = screenSize.height * 0.6; // 60% of screen height

    return SafeArea(
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: maxWidth.clamp(280.0, 380.0), // Min 280, Max 380
            constraints: BoxConstraints(
              maxHeight: maxHeight.clamp(300.0, 500.0), // Min 300, Max 500
            ),
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with close button
                  Row(
                    children: [
                      Icon(
                        _getCallStateIcon(),
                        color: stateColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
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

                  // Phone number
                  if (phoneNumber.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Subtitle
                  if (subtitle.isNotEmpty) ...[
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Current time
                  Text(
                    'Time: $currentTime',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),

                  const SizedBox(height: 16),

                  // Action Buttons - Responsive layout
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 300) {
                        // Vertical layout for narrow screens
                        return Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _openCallInteraction,
                                icon: const Icon(Icons.edit_note, size: 16),
                                label: const Text('View Details'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _closeOverlay,
                                icon: const Icon(Icons.close, size: 16),
                                label: const Text('Dismiss'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[300],
                                  foregroundColor: Colors.black87,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      } else {
                        // Horizontal layout for wider screens
                        return Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _openCallInteraction,
                                icon: const Icon(Icons.edit_note, size: 16),
                                label: const Text(
                                  'Details',
                                  style: TextStyle(fontSize: 12),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _closeOverlay,
                                icon: const Icon(Icons.close, size: 16),
                                label: const Text(
                                  'Dismiss',
                                  style: TextStyle(fontSize: 12),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[300],
                                  foregroundColor: Colors.black87,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// === Main App Setup ===
Future<void> _initFirebase() async => Firebase.initializeApp();

BuildContext? _globalContext;

// Add this global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ... (rest of your permission functions remain the same)

Future<bool> _ensurePermissions() async {
  log('🔐 Checking permissions...');

  if (!Platform.isAndroid) return true;

  // Check basic permissions first
  final phoneStatus = await Permission.phone.status;
  final notificationStatus = await Permission.notification.status;

  final allBasicGranted = phoneStatus.isGranted && notificationStatus.isGranted;

  if (!allBasicGranted) {
    log('⚠️ Some basic permissions missing, requesting...');

    // Request basic permissions first
    if (!phoneStatus.isGranted) {
      final phoneResult = await Permission.phone.request();
      if (!phoneResult.isGranted) {
        log('❌ Phone permission denied');
        return false;
      }
    }

    if (!notificationStatus.isGranted) {
      final notificationResult = await Permission.notification.request();
      if (!notificationResult.isGranted) {
        log('❌ Notification permission denied');
      }
    }
  }

  // Handle overlay permission with proper user guidance
  final overlayPermission = await SystemAlertWindow.checkPermissions();

  if (overlayPermission != true) {
    log('⚠️ System overlay permission not granted, requesting...');

    // Show explanation dialog first
    if (_globalContext != null) {
      final shouldRequest = await showDialog<bool>(
        context: _globalContext!,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.layers, color: Colors.blue),
              SizedBox(width: 8),
              Text('Display Over Other Apps'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('This app needs permission to display call overlays.'),
              SizedBox(height: 12),
              Text('Steps:'),
              Text('1. Tap "Continue" below'),
              Text('2. Find "CallMan" in the app list'),
              Text('3. Enable "Display over other apps"'),
              Text('4. Return to the app'),
              SizedBox(height: 12),
              Text(
                'Note: On MIUI/Xiaomi devices, also enable "Display pop-up windows while running in background"',
                style: TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );

      if (shouldRequest != true) {
        log('❌ User cancelled overlay permission request');
        return false;
      }
    }

    try {
      // Request the permission
      final granted = await SystemAlertWindow.requestPermissions();

      if (granted != true) {
        log('❌ System overlay permission denied by user');

        // Show guidance for manual enabling
        if (_globalContext != null) {
          await showDialog(
            context: _globalContext!,
            builder: (context) => AlertDialog(
              title: const Text('Permission Required'),
              content: const Text(
                  'Please enable overlay permission manually:\n\n'
                      '1. Go to Settings > Apps > Special app access\n'
                      '2. Find "Display over other apps"\n'
                      '3. Find "CallMan" and enable it\n'
                      '4. Restart the app\n\n'
                      'Alternative path:\n'
                      'Settings > Apps > CallMan > Permissions > Display over other apps'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    // Try to open app settings
                    await openAppSettings();
                  },
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );
        }
        return false;
      }

      log('✅ System overlay permission granted');
    } catch (e) {
      log('❌ Error requesting system overlay permission: $e');
      return false;
    }
  }

  // Final verification
  final finalPhoneStatus = await Permission.phone.status;
  final finalNotificationStatus = await Permission.notification.status;
  final finalOverlayStatus = await SystemAlertWindow.checkPermissions();

  final finalResult = finalPhoneStatus.isGranted &&
      finalNotificationStatus.isGranted &&
      (finalOverlayStatus == true);

  log('🔍 Final permission status - Phone: ${finalPhoneStatus.isGranted}, Notification: ${finalNotificationStatus.isGranted}, Overlay: $finalOverlayStatus');

  await PermissionManager.setPermissionsGranted(finalResult);
  return finalResult;
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
          Text(
            'For call tracking and overlay features to work properly, please enable:',
          ),
          SizedBox(height: 12),
          Text('1. Phone permissions - to detect call states'),
          Text('2. Notifications - for background service alerts'),
          Text('3. Display over other apps - for call overlays'),
          Text('4. Background activity - keep service running'),
          Text('5. Disable battery optimization - prevent killing'),
          SizedBox(height: 8),
          Text(
            '(MIUI users: Enable "Display pop-up windows while running in background")',
            style: TextStyle(fontSize: 12, color: Colors.orange),
          ),
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

// Rest of your existing background service code remains the same...
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
        await OverlayManager.closeOverlay();
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
      await OverlayManager.closeOverlay();
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

Future<void> _initBackgroundService() async {
  log('🚀 Initializing background service configuration...');

  final service = FlutterBackgroundService();

  try {
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onBackgroundServiceStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'call_tracking_service_channel',
        initialNotificationTitle: 'Call Tracking Service',
        initialNotificationContent: 'Preparing to monitor calls...',
        foregroundServiceNotificationId: 999,
        autoStartOnBoot: false,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onBackgroundServiceStart,
      ),
    );

    log('✅ Background service configured successfully');

    final isConfigured = await service.isRunning();
    log('🔍 Service configuration test - IsRunning: $isConfigured');
  } catch (e) {
    log('❌ Failed to configure background service: $e');
  }
}

Future<void> _startBackgroundService() async {
  log('🚀 Starting background service...');

  try {
    final service = FlutterBackgroundService();

    final isCurrentlyRunning = await service.isRunning();
    log('📊 Current service status: $isCurrentlyRunning');

    if (!isCurrentlyRunning) {
      log('🔄 Service not running, starting now...');

      await Future.delayed(const Duration(milliseconds: 1000));

      final startResult = await service.startService();
      log('📋 Service start result: $startResult');

      if (startResult) {
        log('✅ Background service started successfully');

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

  FlutterError.onError = (details) {
    final msg = details.exception.toString();

    final nonFatalErrors = [
      'GraphicBuffer', 'qdgralloc', 'AdrenoUtils', 'Gralloc4',
      'AHardwareBuffer', 'format 56', 'Unknown Format',
      'AccessibilityNodeInfo', 'AccessibilityRecord', 'LongArray',
      'incremental_prop', 'miuilog', 'data_log_file',
    ];

    if (nonFatalErrors.any((error) => msg.contains(error))) {
      log('Non-fatal system warning: ${details.exception}');
      return;
    }

    log('Flutter Error: ${details.exception}');
    log('Stack trace: ${details.stack}');
    FlutterError.presentError(details);
  };

  try {
    await _initFirebase();
    log('✅ Firebase initialized');

    await NotificationUtils.initialize();
    log('✅ Notification channel initialized');

    await _initBackgroundService();
    log('✅ Background service configured');

    OverlayManager.initialize();
    log('✅ Overlay manager initialized');

    // Set up port for receiving messages from overlay
    _setupOverlayMessageListener();

    log('🎉 App initialization completed successfully');
  } catch (e) {
    log('❌ Critical error during app initialization: $e');
  }

  runApp(
    BlocProvider(
      create: (_) => AuthCubit()..checkAuthStatus(),
      child: const MyApp(),
    ),
  );
}

// Add this function to handle messages from overlay
void _setupOverlayMessageListener() {
  try {
    final receivePort = ReceivePort();
    IsolateNameServer.registerPortWithName(
      receivePort.sendPort,
      'overlay_to_app_port',
    );

    receivePort.listen((message) {
      log('📥 Received message from overlay: $message');

      if (message is Map<String, dynamic>) {
        final action = message['action'] as String?;

        switch (action) {
          case 'open_call_interaction':
            _handleOpenCallInteraction(message);
            break;
          case 'overlay_closed_by_user':
            log('✅ Overlay closed by user');
            break;
          default:
            log('⚠️ Unknown action from overlay: $action');
        }
      }
    });

    log('✅ Overlay message listener set up successfully');
  } catch (e) {
    log('❌ Error setting up overlay message listener: $e');
  }
}

// Add this function to handle navigation to CallInteractionScreen
void _handleOpenCallInteraction(Map<String, dynamic> data) {
  try {
    final context = navigatorKey.currentContext;
    if (context != null) {
      log('🔄 Navigating to CallInteractionScreen...');

      // Navigate to the CallInteractionScreen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CallInteractionScreen(
            phoneNumber: data['phoneNumber'] ?? '',
            callState: data['callState'] ?? '',
            callId: data['callId'] ?? '',
            timestamp: data['timestamp'] ?? '',
          ),
        ),
      );

      log('✅ Successfully navigated to CallInteractionScreen');
    } else {
      log('❌ No context available for navigation');
    }
  } catch (e) {
    log('❌ Error navigating to CallInteractionScreen: $e');
  }
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
    _globalContext = context; // Set global context for permission dialogs
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

      log(
        'Existing permissions - Phone: ${phoneStatus.isGranted}, Notifications: ${notificationStatus.isGranted}, Overlay: $overlayStatus',
      );

      return phoneStatus.isGranted &&
          (overlayStatus == true) &&
          notificationStatus.isGranted;
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

      final permissionsGranted = await _ensurePermissions();
      setState(() {
        _permissionsGranted = permissionsGranted;
        _initStatus = permissionsGranted
            ? 'Starting services...'
            : 'Missing permissions';
      });

      if (permissionsGranted) {
        setState(() {
          _initStatus = 'Initializing background service...';
        });

        await _startBackgroundService();

        setState(() {
          _initStatus = 'Setting up call tracking...';
        });

        await _initializeForegroundCallTracking();

        setState(() {
          _serviceInitialized = true;
          _initStatus = 'Ready!';
        });

        log('✅ App fully initialized with permissions and services');

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
    _globalContext = context; // Update global context

    return ScreenUtilInit(
      designSize: const Size(404.47, 889),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'CallMan',
          theme: appTheme,
          navigatorKey: navigatorKey, // Add this line to use global navigator key
          initialRoute: '/',
          routes: AppRoutes.routes,
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
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
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              if (!_permissionsGranted) ...[
                const Text(
                  'This app needs phone, notification and overlay permissions to work properly.',
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