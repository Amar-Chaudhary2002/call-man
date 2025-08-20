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

  Stream<List<CallRecord>> get callHistoryStream =>
      _callHistoryController.stream;
  List<CallRecord> get callHistory => List.unmodifiable(_callHistory);

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      await _requestPermissions();
      await _loadCallLogs();
      _isInitialized = true;
      log('✅ Call tracking service initialized with real call logs');
      return true;
    } catch (e) {
      log('❌ Failed to initialize call tracking service: $e');
      return false;
    }
  }

  Future<void> refreshCallLogs() async {
    if (_isLoadingCallLogs) return;

    try {
      await _loadCallLogs();
    } catch (e) {
      log('❌ Failed to refresh call logs: $e');
      rethrow;
    }
  }

  List<CallRecord> getFilteredCalls(String filter) {
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
      default: // 'All' or any other value
        return List.from(_callHistory);
    }
  }

  Future<void> _requestPermissions() async {
    try {
      // Check if permission is already granted
      final currentStatus = await Permission.phone.status;
      if (currentStatus.isGranted) {
        log('📱 Phone permission already granted');
        return;
      }

      // Request permission only if not already granted
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

    try {
      final Iterable<CallLogEntry> entries = await CallLog.get();
      final List<CallRecord> records = [];
      for (var entry in entries) {
        records.add(_mapCallLogToRecord(entry));
      }

      _callHistory = records;
      _callHistoryController.add(_callHistory);
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
    try {
      // Clean the phone number (remove all non-digit characters except '+')
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      if (cleanNumber.isEmpty) {
        throw Exception('Invalid phone number');
      }

      log('📞 Making call to: $cleanNumber');

      // Android-specific implementation for direct call
      if (Platform.isAndroid) {
        try {
          // Use CALL action instead of DIAL for direct calling
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

          // Fallback to DIAL action
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

      // Standard URL launch fallback
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

      // Native platform channel as last resort
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
    _callStateController.close();
    _callHistoryController.close();
  }
}