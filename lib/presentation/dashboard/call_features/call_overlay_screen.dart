// // call_overlay_service.dart
// import 'dart:async';
// import 'dart:developer';
// import 'package:flutter/services.dart';
// import 'package:flutter_overlay_window/flutter_overlay_window.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:flutter_background_service/flutter_background_service.dart';

// class CallOverlayService {
//   static final CallOverlayService _instance = CallOverlayService._internal();
//   factory CallOverlayService() => _instance;
//   CallOverlayService._internal();

//   static const MethodChannel _methodChannel = MethodChannel(
//     'call_overlay_channel',
//   );

//   StreamSubscription<dynamic>? _callStateSubscription;
//   bool _isOverlayActive = false;
//   String? _currentCallNumber;

//   // Initialize the service
//   Future<bool> initialize() async {
//     try {
//       // Check and request system alert window permission
//       if (!await Permission.systemAlertWindow.isGranted) {
//         final status = await Permission.systemAlertWindow.request();
//         if (!status.isGranted) {
//           log('❌ System alert window permission denied');
//           return false;
//         }
//       }

//       // Initialize background service
//       await initializeBackgroundService();

//       // Setup call state monitoring
//       _setupCallStateListener();

//       return true;
//     } catch (e) {
//       log('❌ Error initializing overlay service: $e');
//       return false;
//     }
//   }

//   Future<void> initializeBackgroundService() async {
//     final service = FlutterBackgroundService();

//     await service.configure(
//       androidConfiguration: AndroidConfiguration(
//         onStart: onBackgroundStart,
//         autoStart: true,
//         isForegroundMode: true,
//         notificationChannelId: 'call_overlay_channel',
//         initialNotificationTitle: 'Call Overlay Service',
//         initialNotificationContent: 'Monitoring call states',
//         foregroundServiceNotificationId: 888,
//       ),
//       iosConfiguration: IosConfiguration(
//         autoStart: true,
//         onForeground: onBackgroundStart,
//         onBackground: onIosBackground,
//       ),
//     );
//   }

//   void _setupCallStateListener() {
//     // Listen to method channel for call state changes
//     _methodChannel.setMethodCallHandler((call) async {
//       switch (call.method) {
//         case 'onCallStateChanged':
//           final state = call.arguments['state'] as String;
//           final phoneNumber = call.arguments['phoneNumber'] as String?;
//           await _handleCallStateChange(state, phoneNumber);
//           break;
//         case 'onIncomingCall':
//           final phoneNumber = call.arguments['phoneNumber'] as String;
//           await _showIncomingCallOverlay(phoneNumber);
//           break;
//         case 'onCallEnded':
//           await _hideCallOverlay();
//           break;
//       }
//     });
//   }

//   Future<void> _handleCallStateChange(String state, String? phoneNumber) async {
//     log('📞 Call state changed: $state, number: $phoneNumber');

//     switch (state) {
//       case 'RINGING':
//         if (phoneNumber != null) {
//           await _showIncomingCallOverlay(phoneNumber);
//         }
//         break;
//       case 'OFFHOOK':
//         await _showActiveCallOverlay(phoneNumber ?? 'Unknown');
//         break;
//       case 'IDLE':
//         await _hideCallOverlay();
//         break;
//     }
//   }

//   Future<void> _showIncomingCallOverlay(String phoneNumber) async {
//     if (_isOverlayActive) return;

//     try {
//       _currentCallNumber = phoneNumber;
//       _isOverlayActive = true;

//       await FlutterOverlayWindow.showOverlay(
//         height: 200,
//         width: 300,
//         alignment: OverlayAlignment.center,
//         visibility: NotificationVisibility.visibilityPublic,
//         overlayTitle: "Incoming Call",
//         overlayContent: phoneNumber,
//         enableDrag: true,
//         positionGravity: PositionGravity.auto,
//       );

//       log('✅ Incoming call overlay shown for: $phoneNumber');
//     } catch (e) {
//       log('❌ Error showing incoming call overlay: $e');
//       _isOverlayActive = false;
//     }
//   }

//   Future<void> _showActiveCallOverlay(String phoneNumber) async {
//     if (!_isOverlayActive) {
//       try {
//         _currentCallNumber = phoneNumber;
//         _isOverlayActive = true;

//         await FlutterOverlayWindow.showOverlay(
//           height: 150,
//           width: 280,
//           alignment: OverlayAlignment.topCenter,
//           visibility: NotificationVisibility.visibilityPublic,
//           overlayTitle: "Call Active",
//           overlayContent: "Connected to $phoneNumber",
//           enableDrag: true,
//           positionGravity: PositionGravity.auto,
//         );

//         log('✅ Active call overlay shown for: $phoneNumber');
//       } catch (e) {
//         log('❌ Error showing active call overlay: $e');
//         _isOverlayActive = false;
//       }
//     }
//   }

//   Future<void> _hideCallOverlay() async {
//     if (!_isOverlayActive) return;

//     try {
//       await FlutterOverlayWindow.closeOverlay();
//       _isOverlayActive = false;
//       _currentCallNumber = null;
//       log('✅ Call overlay hidden');
//     } catch (e) {
//       log('❌ Error hiding call overlay: $e');
//     }
//   }

//   // Check if overlay permission is granted
//   Future<bool> hasOverlayPermission() async {
//     return await Permission.systemAlertWindow.isGranted;
//   }

//   // Request overlay permission
//   Future<bool> requestOverlayPermission() async {
//     final status = await Permission.systemAlertWindow.request();
//     return status.isGranted;
//   }

//   void dispose() {
//     _callStateSubscription?.cancel();
//     _hideCallOverlay();
//   }
// }

// // Background service entry point
// @pragma('vm:entry-point')
// void onBackgroundStart(ServiceInstance service) async {
//   // This will be called when the background service starts
//   service.on('stopService').listen((event) {
//     service.stopSelf();
//   });

//   // Monitor call states in background
//   Timer.periodic(const Duration(seconds: 1), (timer) async {
//     if (service is AndroidServiceInstance) {
//       // Update notification to show service is running
//       service.setForegroundNotificationInfo(
//         title: "Call Overlay Active",
//         content: "Monitoring call states...",
//       );
//     }
//   });
// }

// @pragma('vm:entry-point')
// Future<bool> onIosBackground(ServiceInstance service) async {
//   // iOS background handling
//   return true;
// }
