// ============================================================================
// Enhanced CallTrackingService with real-time call state monitoring
// ============================================================================

import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:call_app/presentation/dashboard/model/call_record_model.dart';
import 'package:call_log/call_log.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:phone_state/phone_state.dart';
import '../recent_call_screen.dart';

class CallTrackingService {
  static CallTrackingService? _instance;
  static CallTrackingService get instance =>
      _instance ??= CallTrackingService._();

  CallTrackingService._();

  final StreamController<CallRecord> _callStateController =
  StreamController<CallRecord>.broadcast();
  final StreamController<List<CallRecord>> _callHistoryController =
  StreamController<List<CallRecord>>.broadcast();

  List<CallRecord> _callHistory = [];
  bool _isInitialized = false;
  bool _isLoadingCallLogs = false;
  bool _isMonitoring = false;

  // Call state monitoring
  StreamSubscription<PhoneState>? _phoneStateSubscription;
  String? _currentCallNumber;
  DateTime? _callStartTime;
  CallState? _lastCallState;

  Stream<List<CallRecord>> get callHistoryStream =>
      _callHistoryController.stream;
  Stream<CallRecord> get callStateStream => _callStateController.stream;
  List<CallRecord> get callHistory => List.unmodifiable(_callHistory);

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    log('🔄 Initializing CallTrackingService...');

    try {
      await _requestPermissions();
      await _loadCallLogs();
      _isInitialized = true;
      log('✅ Call tracking service initialized');
      return true;
    } catch (e) {
      log('❌ Failed to initialize call tracking service: $e');
      return false;
    }
  }

  Future<void> startCallStateMonitoring() async {
    if (_isMonitoring) {
      log('⚠️ Call state monitoring already active');
      return;
    }

    log('🔄 Starting call state monitoring...');

    try {
      // Check permissions first
      final phonePermission = await Permission.phone.status;
      if (!phonePermission.isGranted) {
        log('❌ Phone permission not granted, cannot start monitoring');
        return;
      }

      // Listen to phone state changes
      _phoneStateSubscription = PhoneState.stream.listen(
        _onPhoneStateChanged,
        onError: (error) {
          log('❌ Phone state stream error: $error');
        },
      );

      _isMonitoring = true;
      log('✅ Call state monitoring started successfully');
    } catch (e) {
      log('❌ Failed to start call state monitoring: $e');
      // Don't throw error, just log it
    }
  }

  void stopCallStateMonitoring() {
    log('🛑 Stopping call state monitoring...');

    _phoneStateSubscription?.cancel();
    _phoneStateSubscription = null;
    _isMonitoring = false;
    _currentCallNumber = null;
    _callStartTime = null;
    _lastCallState = null;

    log('✅ Call state monitoring stopped');
  }

  void _onPhoneStateChanged(PhoneState state) {
    log('📞 Phone state changed: ${state.status} - Number: ${state.number}');

    switch (state.status) {
      case PhoneStateStatus.CALL_INCOMING:
        _handleIncomingCall(state.number);
        break;
      case PhoneStateStatus.CALL_STARTED:
        _handleCallStarted(state.number);
        break;
      case PhoneStateStatus.CALL_ENDED:
        _handleCallEnded();
        break;
      case PhoneStateStatus.NOTHING:
        _handleCallIdle();
        break;
    }
  }

  void _handleIncomingCall(String? number) {
    log('📱 Incoming call from: ${number ?? "Unknown"}');

    _currentCallNumber = number ?? 'Unknown';
    _callStartTime = DateTime.now();
    _lastCallState = CallState.ringing;

    // Show overlay for incoming call
    _showCallOverlay(
      title: 'Incoming Call',
      subtitle: 'From: $_currentCallNumber',
      callState: 'ringing', // Use string instead of enum
    );

    // Emit call state
    final callRecord = CallRecord(
      phoneNumber: _currentCallNumber!,
      startTime: _callStartTime!,
      state: CallState.ringing,
      isOutgoing: false,
    );
    _callStateController.add(callRecord);
  }

  void _handleCallStarted(String? number) {
    log('✅ Call started with: ${number ?? _currentCallNumber ?? "Unknown"}');

    _currentCallNumber = number ?? _currentCallNumber ?? 'Unknown';
    _callStartTime = _callStartTime ?? DateTime.now();
    _lastCallState = CallState.ringing; // Use existing enum value

    // Show overlay for active call
    _showCallOverlay(
      title: 'Call Active',
      subtitle: 'With: $_currentCallNumber',
      callState: 'active', // Use string instead of enum
    );

    // Emit call state
    final callRecord = CallRecord(
      phoneNumber: _currentCallNumber!,
      startTime: _callStartTime!,
      state: CallState.ringing, // Use existing enum value
      isOutgoing: _lastCallState == CallState.ringing,
    );
    _callStateController.add(callRecord);
  }

  void _handleCallEnded() {
    log('📴 Call ended');

    if (_currentCallNumber != null && _callStartTime != null) {
      final duration = DateTime.now().difference(_callStartTime!);

      // Show overlay for call ended
      _showCallOverlay(
        title: 'Call Ended',
        subtitle: 'Duration: ${_formatDuration(duration)}\nWith: $_currentCallNumber',
        callState: 'disconnected', // Use string instead of enum
      );

      // Emit final call state
      final callRecord = CallRecord(
        phoneNumber: _currentCallNumber!,
        startTime: _callStartTime!,
        endTime: DateTime.now(),
        duration: duration,
        state: CallState.disconnected,
        isOutgoing: _lastCallState == CallState.ringing,
      );
      _callStateController.add(callRecord);

      // Refresh call logs after call ends
      Future.delayed(const Duration(seconds: 2), () {
        refreshCallLogs();
      });
    }

    _resetCallState();
  }

  void _handleCallIdle() {
    if (_lastCallState != null) {
      log('📵 Phone returned to idle state');
      _resetCallState();
    }
  }

  void _resetCallState() {
    _currentCallNumber = null;
    _callStartTime = null;
    _lastCallState = null;
  }

  Future<void> _showCallOverlay({
    required String title,
    required String subtitle,
    required String callState, // Changed from CallState to String
  }) async {
    try {
      log('🔔 Showing overlay: $title - $subtitle');

      // Check if overlay permission is granted
      final hasPermission = await FlutterOverlayWindow.isPermissionGranted();
      if (!hasPermission) {
        log('⚠️ Overlay permission not granted');
        return;
      }

      // Close existing overlay first
      if (await FlutterOverlayWindow.isActive()) {
        await FlutterOverlayWindow.closeOverlay();
        await Future.delayed(const Duration(milliseconds: 200));
      }

      // Show new overlay
      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        overlayTitle: title,
        overlayContent: subtitle,
        flag: OverlayFlag.defaultFlag,
        alignment: OverlayAlignment.topCenter,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.auto,
        height: 200,
        width: WindowSize.matchParent,
      );

      // Send data to overlay
      await FlutterOverlayWindow.shareData({
        'title': title,
        'subtitle': subtitle,
        'callState': callState,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      log('✅ Overlay displayed successfully');

      // Auto-hide overlay after some time for certain states
      if (callState == 'disconnected') {
        Future.delayed(const Duration(seconds: 5), () {
          FlutterOverlayWindow.closeOverlay();
        });
      }
    } catch (e) {
      log('❌ Failed to show overlay: $e');
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  // Rest of your existing methods remain the same...
  Future<void> refreshCallLogs() async {
    if (_isLoadingCallLogs) return;
    log('🔄 Refreshing call logs...');

    try {
      await _loadCallLogs();
      log('✅ Call logs refreshed');
    } catch (e) {
      log('❌ Failed to refresh call logs: $e');
      rethrow;
    }
  }

  List<CallRecord> getFilteredCalls(String filter) {
    log('📊 Filtering calls by: $filter');

    switch (filter.toLowerCase()) {
      case 'missed':
        return _callHistory.where((call) {
          return call.callType.toLowerCase().contains('missed') ||
              call.callType.toLowerCase().contains('not picked');
        }).toList();
      case 'outgoing':
        return _callHistory.where((call) => call.isOutgoing).toList();
      case 'incoming':
        return _callHistory.where((call) {
          return !call.isOutgoing &&
              call.duration != null &&
              call.duration!.inSeconds > 0;
        }).toList();
      default:
        return List.from(_callHistory);
    }
  }

  Future<void> _requestPermissions() async {
    log('🔐 Requesting permissions...');

    try {
      final currentStatus = await Permission.phone.status;
      log('Current phone permission status: $currentStatus');

      if (currentStatus.isGranted) {
        log('📱 Phone permission already granted');
        return;
      }

      if (!currentStatus.isGranted && !currentStatus.isPermanentlyDenied) {
        final status = await Permission.phone.request();
        log('📱 Phone permission status after request: $status');

        if (!status.isGranted) {
          throw Exception('Phone permission is required to access call logs');
        }
      } else if (currentStatus.isPermanentlyDenied) {
        throw Exception(
          'Phone permission is permanently denied. Please enable it in app settings.',
        );
      }
    } catch (e) {
      log('⚠️ Permission request failed: $e');
      rethrow;
    }
  }

  Future<void> _loadCallLogs() async {
    if (_isLoadingCallLogs) return;
    _isLoadingCallLogs = true;

    log('📋 Loading call logs...');

    try {
      final Iterable<CallLogEntry> entries = await CallLog.get();
      final List<CallRecord> records = [];

      log('📋 Found ${entries.length} call log entries');

      for (var entry in entries) {
        records.add(_mapCallLogToRecord(entry));
      }

      _callHistory = records;
      _callHistoryController.add(_callHistory);

      log('✅ Loaded ${records.length} call records');
    } catch (e) {
      log('❌ Error loading call logs: $e');
      _callHistory = [];
      _callHistoryController.add(_callHistory);
      rethrow;
    } finally {
      _isLoadingCallLogs = false;
    }
  }

  CallRecord _mapCallLogToRecord(CallLogEntry entry) {
    return CallRecord(
      phoneNumber: entry.number ?? 'Unknown',
      startTime: DateTime.fromMillisecondsSinceEpoch(entry.timestamp ?? 0),
      endTime: entry.duration == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
        (entry.timestamp ?? 0) + (entry.duration ?? 0) * 1000,
      ),
      state: _getCallStateFromEntry(entry),
      isOutgoing: entry.callType == CallType.outgoing,
      duration: entry.duration == null
          ? null
          : Duration(seconds: entry.duration!),
      contactName: entry.name ?? '',
    );
  }

  CallState _getCallStateFromEntry(CallLogEntry entry) {
    if (entry.callType == CallType.missed) {
      return CallState.disconnected;
    } else if (entry.duration != null && entry.duration! > 0) {
      return CallState.disconnected;
    } else if (entry.callType == CallType.outgoing) {
      return CallState.disconnected;
    }
    return CallState.disconnected;
  }

  Future<bool> makeCall(String phoneNumber) async {
    log('📞 Attempting to make call to: $phoneNumber');

    try {
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      if (cleanNumber.isEmpty) {
        throw Exception('Invalid phone number');
      }

      // Set state for outgoing call
      _currentCallNumber = cleanNumber;
      _callStartTime = DateTime.now();
      _lastCallState = CallState.ringing; // Use existing enum value

      // Show overlay for outgoing call
      _showCallOverlay(
        title: 'Calling...',
        subtitle: 'To: $cleanNumber',
        callState: 'dialing', // Use string instead of enum
      );

      log('📞 Making call to: $cleanNumber');

      if (Platform.isAndroid) {
        try {
          final intent = AndroidIntent(
            action: 'android.intent.action.CALL',
            data: 'tel:$cleanNumber',
            flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
          );
          await intent.launch();
          log('✅ Call initiated via Android Intent');
          return true;
        } catch (e) {
          log('Android Intent CALL failed, trying DIAL: $e');

          try {
            final intent = AndroidIntent(
              action: 'android.intent.action.DIAL',
              data: 'tel:$cleanNumber',
              flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
            );
            await intent.launch();
            log('✅ Dialer opened via Android Intent');
            return true;
          } catch (e) {
            log('Android Intent DIAL failed: $e');
          }
        }
      }

      final url = Uri(scheme: 'tel', path: cleanNumber);
      if (await canLaunchUrl(url)) {
        try {
          final launched = await launchUrl(
            url,
            mode: LaunchMode.externalApplication,
          );
          if (launched) {
            log('✅ Call initiated via URL launcher');
            return true;
          }
        } catch (e) {
          log('Standard URL launch failed: $e');
        }
      }

      try {
        const platform = MethodChannel('phone_dialer');
        await platform.invokeMethod('dialPhoneNumber', {'number': cleanNumber});
        log('✅ Call initiated via native channel');
        return true;
      } catch (e) {
        log('Native channel failed: $e');
      }

      return false;
    } catch (e) {
      log('❌ Error making call: $e');
      return false;
    }
  }

  void dispose() {
    log('🗑️ Disposing CallTrackingService...');

    stopCallStateMonitoring();
    _callStateController.close();
    _callHistoryController.close();

    log('✅ CallTrackingService disposed');
  }
}