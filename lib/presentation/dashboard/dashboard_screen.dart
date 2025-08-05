// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'dart:developer';
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const CallTrackingApp());
}

class CallTrackingApp extends StatelessWidget {
  const CallTrackingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Call Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: AppColors.primaryColor,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// app_colors.dart
class AppColors {
  static const Color primaryColor = Color(0xFF1E3A8A);
  static const Color secondaryColor = Color(0xFF3B82F6);
  static const Color accentColor = Color(0xFF60A5FA);
  static const Color cardColor = Color(0xFF25316D);
  static const Color backgroundColor = Color(0xFF0F172A);
}

// call_models.dart

enum CallState {
  idle,
  ringing,
  offhook,
  disconnected,
}

class CallRecord {
  final String phoneNumber;
  final DateTime startTime;
  final DateTime? endTime;
  final CallState state;
  final bool isOutgoing;
  final Duration? duration;
  final bool isConnected;
  final String contactName;

  CallRecord({
    required this.phoneNumber,
    required this.startTime,
    this.endTime,
    required this.state,
    required this.isOutgoing,
    this.duration,
    this.isConnected = false,
    this.contactName = '',
  });

  CallRecord copyWith({
    String? phoneNumber,
    DateTime? startTime,
    DateTime? endTime,
    CallState? state,
    bool? isOutgoing,
    Duration? duration,
    bool? isConnected,
    String? contactName,
  }) {
    return CallRecord(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      state: state ?? this.state,
      isOutgoing: isOutgoing ?? this.isOutgoing,
      duration: duration ?? this.duration,
      isConnected: isConnected ?? this.isConnected,
      contactName: contactName ?? this.contactName,
    );
  }

  String get callType {
    if (state == CallState.disconnected &&
        duration != null &&
        duration!.inSeconds > 0) {
      return isOutgoing ? "Outgoing" : "Incoming";
    } else if (state == CallState.disconnected &&
        (duration == null || duration!.inSeconds == 0)) {
      return isOutgoing ? "Not picked" : "Missed call";
    } else if (state == CallState.ringing) {
      return isOutgoing ? "Calling..." : "Incoming call";
    } else if (state == CallState.offhook) {
      return "Connected";
    }
    return "Unknown";
  }

  IconData get icon {
    if (state == CallState.disconnected &&
        duration != null &&
        duration!.inSeconds > 0) {
      return isOutgoing ? Icons.call_made : Icons.call_received;
    } else if (state == CallState.disconnected &&
        (duration == null || duration!.inSeconds == 0)) {
      return isOutgoing ? Icons.access_time : Icons.call_missed;
    } else if (state == CallState.ringing) {
      return isOutgoing ? Icons.call_made : Icons.call_received;
    } else if (state == CallState.offhook) {
      return Icons.phone_in_talk;
    }
    return Icons.phone;
  }

  Color get iconColor {
    if (state == CallState.disconnected &&
        duration != null &&
        duration!.inSeconds > 0) {
      return isOutgoing ? Colors.green : Colors.blue;
    } else if (state == CallState.disconnected &&
        (duration == null || duration!.inSeconds == 0)) {
      return isOutgoing ? Colors.orange : Colors.red;
    } else if (state == CallState.ringing) {
      return Colors.orange;
    } else if (state == CallState.offhook) {
      return Colors.green;
    }
    return Colors.grey;
  }

  String get displayName => contactName.isNotEmpty ? contactName : phoneNumber;

  String get formattedTime {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final callDate = DateTime(startTime.year, startTime.month, startTime.day);

    String timeStr = "${startTime.hour % 12 == 0 ? 12 : startTime.hour % 12}:${startTime.minute.toString().padLeft(2, '0')} ${startTime.hour >= 12 ? 'PM' : 'AM'}";

    if (callDate == today) {
      return timeStr;
    } else if (callDate == yesterday) {
      return "Yesterday $timeStr";
    } else {
      return "${_getMonthName(startTime.month)} ${startTime.day}, $timeStr";
    }
  }

  String _getMonthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month];
  }

  String get durationText {
    if (duration == null || duration!.inSeconds == 0) return '';
    final minutes = duration!.inMinutes;
    final seconds = duration!.inSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'phoneNumber': phoneNumber,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'state': state.index,
      'isOutgoing': isOutgoing,
      'duration': duration?.inMilliseconds,
      'isConnected': isConnected,
      'contactName': contactName,
    };
  }

  factory CallRecord.fromJson(Map<String, dynamic> json) {
    return CallRecord(
      phoneNumber: json['phoneNumber'] ?? '',
      startTime: DateTime.fromMillisecondsSinceEpoch(json['startTime'] ?? 0),
      endTime: json['endTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['endTime'])
          : null,
      state: CallState.values[json['state'] ?? 0],
      isOutgoing: json['isOutgoing'] ?? false,
      duration: json['duration'] != null
          ? Duration(milliseconds: json['duration'])
          : null,
      isConnected: json['isConnected'] ?? false,
      contactName: json['contactName'] ?? '',
    );
  }
}

// permission_manager.dart


class CallPermissionManager {
  static Future<bool> requestAllPermissions() async {
    final permissions = [
      Permission.phone,
      Permission.microphone,
      Permission.contacts,
      Permission.storage,
    ];

    Map<Permission, PermissionStatus> statuses = {};
    for (Permission permission in permissions) {
      statuses[permission] = await permission.status;
    }

    statuses.forEach((permission, status) {
      log('Permission ${permission.toString()}: ${status.toString()}');
    });

    List<Permission> toRequest = [];
    for (Permission permission in permissions) {
      if (statuses[permission] != PermissionStatus.granted) {
        toRequest.add(permission);
      }
    }

    if (toRequest.isNotEmpty) {
      Map<Permission, PermissionStatus> results = await toRequest.request();

      results.forEach((permission, status) {
        statuses[permission] = status;
        log('Permission ${permission.toString()} result: ${status.toString()}');
      });
    }

    bool phonePermission = statuses[Permission.phone] == PermissionStatus.granted;
    bool micPermission = statuses[Permission.microphone] == PermissionStatus.granted;

    return phonePermission || micPermission; // Allow app to work with at least one permission
  }

  static Future<void> showPermissionDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permissions Required'),
          content: const Text(
            'This app needs phone and microphone permissions to track calls. '
                'Please grant these permissions in Settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }
}



class CallTrackingService {
  static const MethodChannel _channel = MethodChannel('call_tracking');
  static const EventChannel _eventChannel = EventChannel('call_state_events');

  static CallTrackingService? _instance;
  static CallTrackingService get instance =>
      _instance ??= CallTrackingService._();

  CallTrackingService._();

  final StreamController<CallRecord> _callStateController =
  StreamController<CallRecord>.broadcast();
  final StreamController<List<CallRecord>> _callHistoryController =
  StreamController<List<CallRecord>>.broadcast();
  final StreamController<bool> _permissionStatusController =
  StreamController<bool>.broadcast();
  final StreamController<bool> _networkStatusController =
  StreamController<bool>.broadcast();

  CallRecord? _currentCall;
  List<CallRecord> _callHistory = [];
  StreamSubscription? _callStateSubscription;
  bool _isInitialized = false;
  bool _isNetworkConnected = true;

  Stream<CallRecord> get callStateStream => _callStateController.stream;
  Stream<List<CallRecord>> get callHistoryStream => _callHistoryController.stream;
  Stream<bool> get permissionStatusStream => _permissionStatusController.stream;
  Stream<bool> get networkStatusStream => _networkStatusController.stream;
  CallRecord? get currentCall => _currentCall;
  List<CallRecord> get callHistory => List.unmodifiable(_callHistory);
  bool get isNetworkConnected => _isNetworkConnected;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      log('🚀 Initializing Call Tracking Service');

      final hasPermissions = await CallPermissionManager.requestAllPermissions();
      _permissionStatusController.add(hasPermissions);

      _channel.setMethodCallHandler(_handleMethodCall);

      _callStateSubscription = _eventChannel.receiveBroadcastStream().listen(
        _handleCallStateEvent,
        onError: (error) {
          log('❌ Call state event error: $error');
        },
      );

      await _loadCallHistory();

      try {
        final result = await _channel.invokeMethod('initialize');
        log('✅ Native call tracking initialized: $result');
      } catch (e) {
        log('⚠️ Native call tracking unavailable, using demo mode: $e');
        _addDemoCallHistory();
      }

      _isInitialized = true;
      return true;
    } catch (e) {
      log('❌ Failed to initialize call tracking: $e');
      _addDemoCallHistory();
      return false;
    }
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    log('📨 Method call received: ${call.method}');

    switch (call.method) {
      case 'onIncomingCall':
        _handleIncomingCall(call.arguments);
        break;
      case 'onOutgoingCall':
        _handleOutgoingCall(call.arguments);
        break;
      case 'onCallAnswered':
        _handleCallAnswered(call.arguments);
        break;
      case 'onCallEnded':
        _handleCallEnded(call.arguments);
        break;
      case 'onCallStateChanged':
        _handleCallStateChange(call.arguments);
        break;
      case 'onNetworkStatusChanged':
        _handleNetworkStatusChange(call.arguments);
        break;
      case 'onPermissionChanged':
        _handlePermissionChange(call.arguments);
        break;
      default:
        log('⚠️ Unknown method call: ${call.method}');
    }
  }

  void _handleIncomingCall(dynamic data) {
    try {
      final Map<String, dynamic> callData = Map<String, dynamic>.from(data);
      final phoneNumber = callData['phoneNumber'] as String? ?? '';
      final contactName = callData['contactName'] as String? ?? '';

      log('📞 Incoming call detected: $phoneNumber');

      _currentCall = CallRecord(
        phoneNumber: phoneNumber,
        startTime: DateTime.now(),
        state: CallState.ringing,
        isOutgoing: false,
        contactName: contactName.isNotEmpty ? contactName : _getContactName(phoneNumber),
      );

      _callStateController.add(_currentCall!);
    } catch (e) {
      log('❌ Error handling incoming call: $e');
    }
  }

  void _handleOutgoingCall(dynamic data) {
    try {
      final Map<String, dynamic> callData = Map<String, dynamic>.from(data);
      final phoneNumber = callData['phoneNumber'] as String? ?? '';

      log('📞 Outgoing call detected: $phoneNumber');

      _currentCall = CallRecord(
        phoneNumber: phoneNumber,
        startTime: DateTime.now(),
        state: CallState.ringing,
        isOutgoing: true,
        contactName: _getContactName(phoneNumber),
      );

      _callStateController.add(_currentCall!);
    } catch (e) {
      log('❌ Error handling outgoing call: $e');
    }
  }

  void _handleCallAnswered(dynamic data) {
    if (_currentCall != null) {
      log('📞 Call answered: ${_currentCall!.phoneNumber}');

      _currentCall = _currentCall!.copyWith(
        state: CallState.offhook,
        isConnected: true,
      );

      _callStateController.add(_currentCall!);
    }
  }

  void _handleCallEnded(dynamic data) {
    if (_currentCall != null) {
      final endTime = DateTime.now();
      final duration = endTime.difference(_currentCall!.startTime);

      log('📞 Call ended: ${_currentCall!.phoneNumber}, Duration: ${duration.inSeconds}s');

      _currentCall = _currentCall!.copyWith(
        state: CallState.disconnected,
        endTime: endTime,
        duration: duration,
        isConnected: false,
      );

      _callStateController.add(_currentCall!);
      _addCallToHistory(_currentCall!);
      _currentCall = null;
    }
  }

  void _handleCallStateChange(dynamic data) {
    try {
      final Map<String, dynamic> callData = Map<String, dynamic>.from(data);

      final phoneNumber = callData['phoneNumber'] as String? ?? '';
      final stateString = callData['state'] as String? ?? 'idle';
      final isOutgoing = callData['isOutgoing'] as bool? ?? false;
      final isConnected = callData['isConnected'] as bool? ?? false;

      final state = _parseCallState(stateString);
      final now = DateTime.now();

      if (_currentCall == null || _currentCall!.phoneNumber != phoneNumber) {
        _currentCall = CallRecord(
          phoneNumber: phoneNumber,
          startTime: now,
          state: state,
          isOutgoing: isOutgoing,
          isConnected: isConnected,
          contactName: _getContactName(phoneNumber),
        );
      } else {
        final duration = state == CallState.disconnected
            ? now.difference(_currentCall!.startTime)
            : null;

        _currentCall = _currentCall!.copyWith(
          state: state,
          endTime: state == CallState.disconnected ? now : null,
          duration: duration,
          isConnected: isConnected,
        );
      }

      log('📞 Call state changed: ${_currentCall!.phoneNumber} - ${_currentCall!.callType}');
      _callStateController.add(_currentCall!);

      if (state == CallState.disconnected) {
        _addCallToHistory(_currentCall!);
        _currentCall = null;
      }
    } catch (e) {
      log('❌ Error handling call state change: $e');
    }
  }

  void _handleNetworkStatusChange(dynamic data) {
    if (data is bool) {
      _isNetworkConnected = data;
      _networkStatusController.add(_isNetworkConnected);
      log('🌐 Network status changed: $_isNetworkConnected');
    }
  }

  void _handlePermissionChange(dynamic data) {
    if (data is bool) {
      _permissionStatusController.add(data);
      log('🔐 Permission status changed: $data');
    }
  }

  void _handleCallStateEvent(dynamic event) {
    if (event is Map) {
      final eventType = event['type'] as String?;

      switch (eventType) {
        case 'incoming':
          _handleIncomingCall(event);
          break;
        case 'outgoing':
          _handleOutgoingCall(event);
          break;
        case 'answered':
          _handleCallAnswered(event);
          break;
        case 'ended':
          _handleCallEnded(event);
          break;
        default:
          _handleCallStateChange(event);
      }
    }
  }

  Future<bool> makeCall(String phoneNumber) async {
    try {
      log('📞 Making call to: $phoneNumber');

      try {
        await _channel.invokeMethod('willMakeCall', {'phoneNumber': phoneNumber});
      } catch (e) {
        log('⚠️ Could not notify native layer: $e');
      }

      _currentCall = CallRecord(
        phoneNumber: phoneNumber,
        startTime: DateTime.now(),
        state: CallState.ringing,
        isOutgoing: true,
        contactName: _getContactName(phoneNumber),
      );

      _callStateController.add(_currentCall!);

      final Uri url = Uri.parse('tel:$phoneNumber');
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (launched) {
        _simulateCallStateChanges(phoneNumber);
      } else {
        _currentCall = _currentCall!.copyWith(state: CallState.disconnected);
        _callStateController.add(_currentCall!);
        _currentCall = null;
      }

      return launched;
    } catch (e) {
      log('❌ Error making call: $e');
      return false;
    }
  }

  void _simulateCallStateChanges(String phoneNumber) {
    Timer(const Duration(seconds: 2), () {
      if (_currentCall?.phoneNumber == phoneNumber) {
        _handleCallStateChange({
          'phoneNumber': phoneNumber,
          'state': 'offhook',
          'isOutgoing': true,
          'isConnected': true,
        });
      }
    });

    Timer(const Duration(seconds: 10), () {
      if (_currentCall?.phoneNumber == phoneNumber) {
        _handleCallStateChange({
          'phoneNumber': phoneNumber,
          'state': 'disconnected',
          'isOutgoing': true,
          'isConnected': false,
        });
      }
    });
  }

  String _getContactName(String phoneNumber) {
    final contacts = {
      '+15551234567': 'Sarah Johnson',
      '+15559876543': 'John Doe',
      '+15555555555': 'Emergency Contact',
      '+15551111111': 'Mom',
      '+15552222222': 'Dad',
      '+15553333333': 'Work',
      '+15554444444': 'Boss',
      '+15556666666': 'Doctor',
    };
    return contacts[phoneNumber] ?? '';
  }

  CallState _parseCallState(String stateString) {
    switch (stateString.toLowerCase()) {
      case 'ringing':
      case 'incoming':
        return CallState.ringing;
      case 'offhook':
      case 'answered':
      case 'connected':
        return CallState.offhook;
      case 'disconnected':
      case 'ended':
      case 'idle':
        return CallState.disconnected;
      default:
        return CallState.idle;
    }
  }

  void _addCallToHistory(CallRecord record) {
    _callHistory.removeWhere((call) =>
    call.phoneNumber == record.phoneNumber &&
        call.startTime.difference(record.startTime).abs().inMinutes < 1);

    _callHistory.insert(0, record);

    if (_callHistory.length > 200) {
      _callHistory = _callHistory.take(200).toList();
    }

    _callHistoryController.add(_callHistory);
    _saveCallHistory();
  }

  Future<void> _loadCallHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('call_history');

      if (historyJson != null) {
        final List<dynamic> historyList = json.decode(historyJson);
        _callHistory = historyList.map((item) =>
            CallRecord.fromJson(Map<String, dynamic>.from(item))).toList();

        log('📚 Loaded ${_callHistory.length} call records from storage');
      }

      _callHistoryController.add(_callHistory);
    } catch (e) {
      log('❌ Error loading call history: $e');
      _callHistory = [];
    }
  }

  Future<void> _saveCallHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = json.encode(_callHistory.map((call) => call.toJson()).toList());
      await prefs.setString('call_history', historyJson);
      log('💾 Saved ${_callHistory.length} call records to storage');
    } catch (e) {
      log('❌ Error saving call history: $e');
    }
  }

  List<CallRecord> getFilteredCalls(String filter) {
    switch (filter.toLowerCase()) {
      case 'missed':
        return _callHistory.where((call) =>
        !call.isOutgoing &&
            (call.duration == null || call.duration!.inSeconds == 0)).toList();
      case 'outgoing':
        return _callHistory.where((call) => call.isOutgoing).toList();
      case 'incoming':
        return _callHistory.where((call) =>
        !call.isOutgoing &&
            call.duration != null &&
            call.duration!.inSeconds > 0).toList();
      case 'today':
        final today = DateTime.now();
        return _callHistory.where((call) =>
        call.startTime.day == today.day &&
            call.startTime.month == today.month &&
            call.startTime.year == today.year).toList();
      default:
        return _callHistory;
    }
  }

  void _addDemoCallHistory() {
    final now = DateTime.now();
    final demoRecords = [
      CallRecord(
        phoneNumber: '+15551234567',
        startTime: now.subtract(const Duration(minutes: 30)),
        endTime: now.subtract(const Duration(minutes: 5)),
        state: CallState.disconnected,
        isOutgoing: false,
        duration: const Duration(minutes: 25),
        contactName: 'Sarah Johnson',
      ),
      CallRecord(
        phoneNumber: '+15551111111',
        startTime: now.subtract(const Duration(hours: 2)),
        endTime: now.subtract(const Duration(hours: 2)),
        state: CallState.disconnected,
        isOutgoing: false,
        duration: Duration.zero,
        contactName: 'Mom',
      ),
      CallRecord(
        phoneNumber: '+15552222222',
        startTime: now.subtract(const Duration(days: 1, hours: 3)),
        endTime: now.subtract(const Duration(days: 1, hours: 3, minutes: -15)),
        state: CallState.disconnected,
        isOutgoing: true,
        duration: const Duration(minutes: 15),
        contactName: 'Dad',
      ),
      CallRecord(
        phoneNumber: '+15553333333',
        startTime: now.subtract(const Duration(days: 1, hours: 8)),
        endTime: now.subtract(const Duration(days: 1, hours: 8)),
        state: CallState.disconnected,
        isOutgoing: true,
        duration: Duration.zero,
        contactName: 'Work',
      ),
      CallRecord(
        phoneNumber: '+15554444444',
        startTime: now.subtract(const Duration(days: 2, hours: 1)),
        endTime: now.subtract(const Duration(days: 2, hours: 1, minutes: -5)),
        state: CallState.disconnected,
        isOutgoing: false,
        duration: const Duration(minutes: 5),
        contactName: 'Boss',
      ),
      CallRecord(
        phoneNumber: '+15556666666',
        startTime: now.subtract(const Duration(days: 3)),
        endTime: now.subtract(const Duration(days: 3)),
        state: CallState.disconnected,
        isOutgoing: false,
        duration: Duration.zero,
        contactName: 'Doctor',
      ),
    ];

    _callHistory = demoRecords;
    _callHistoryController.add(_callHistory);
    log('📞 Added ${demoRecords.length} demo call records');
  }

  void dispose() {
    _callStateSubscription?.cancel();
    _callStateController.close();
    _callHistoryController.close();
    _permissionStatusController.close();
    _networkStatusController.close();
    _isInitialized = false;
  }
}

// home_screen.dart


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int pageIndex = 0;
  String selectedFilter = 'All';
  final CallTrackingService _callService = CallTrackingService.instance;
  StreamSubscription<CallRecord>? _callSubscription;
  StreamSubscription<List<CallRecord>>? _historySubscription;
  StreamSubscription<bool>? _permissionSubscription;

  CallRecord? _currentCall;
  List<CallRecord> _callHistory = [];
  bool _hasPermissions = false;

  @override
  void initState() {
    super.initState();
    _initializeCallTracking();
  }

  Future<void> _initializeCallTracking() async {
    await _callService.initialize();

    _callSubscription = _callService.callStateStream.listen((call) {
      setState(() {
        _currentCall = call;
      });
      _showCallNotification(call);
    });

    _historySubscription = _callService.callHistoryStream.listen((history) {
      setState(() {
        _callHistory = history;
      });
    });

    _permissionSubscription = _callService.permissionStatusStream.listen((hasPermissions) {
      setState(() {
        _hasPermissions = hasPermissions;
      });
    });

    setState(() {
      _callHistory = _callService.callHistory;
    });
  }

  void _showCallNotification(CallRecord call) {
    String message;
    Color backgroundColor;

    switch (call.state) {
      case CallState.ringing:
        message = call.isOutgoing
            ? 'Calling ${call.displayName}...'
            : 'Incoming call from ${call.displayName}';
        backgroundColor = Colors.orange;
        break;
      case CallState.offhook:
        message = 'Call connected with ${call.displayName}';
        backgroundColor = Colors.green;
        break;
      case CallState.disconnected:
        final duration = call.durationText;
        message = duration.isNotEmpty
            ? 'Call ended. Duration: $duration'
            : 'Call ended';
        backgroundColor = Colors.red;
        break;
      default:
        return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _openPhoneKeyboard() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PhoneKeyboardSheet(callService: _callService),
    );
  }

  void _onFilterTap(String filter) {
    setState(() {
      selectedFilter = filter;
    });
  }

  List<CallRecord> get filteredCalls {
    return _callService.getFilteredCalls(selectedFilter);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        leading: const Icon(Icons.menu, color: Colors.white),
        title: const Text(
          'Recent Calls',
          style: TextStyle(color: Colors.white),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.search, color: Colors.white),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Permission warning banner
              if (!_hasPermissions)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Some permissions are missing. Call tracking may be limited.',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _callService.initialize(),
                        child: const Text('Grant', style: TextStyle(color: Colors.orange)),
                      ),
                    ],
                  ),
                ),

              // Filter chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FilterChipWidget(
                      label: 'All',
                      selected: selectedFilter == 'All',
                      onTap: () => _onFilterTap('All'),
                    ),
                    FilterChipWidget(
                      label: 'Missed',
                      selected: selectedFilter == 'Missed',
                      onTap: () => _onFilterTap('Missed'),
                    ),
                    FilterChipWidget(
                      label: 'Outgoing',
                      selected: selectedFilter == 'Outgoing',
                      onTap: () => _onFilterTap('Outgoing'),
                    ),
                    FilterChipWidget(
                      label: 'Incoming',
                      selected: selectedFilter == 'Incoming',
                      onTap: () => _onFilterTap('Incoming'),
                    ),
                  ],
                ),
              ),

              // Call list
              Expanded(
                child: CallList(
                  callHistory: filteredCalls,
                  onCallTap: (phoneNumber) => _callService.makeCall(phoneNumber),
                ),
              ),
            ],
          ),

          // Current call overlay
          if (_currentCall != null && _currentCall!.state != CallState.idle)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    Icon(
                      _currentCall!.icon,
                      color: _currentCall!.iconColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentCall!.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _currentCall!.callType,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_callService.isNetworkConnected)
                      const Icon(
                        Icons.signal_wifi_off,
                        color: Colors.red,
                        size: 16,
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Container(
        height: 70,
        width: 70,
        decoration: const BoxDecoration(
          color: Color(0xFF252424),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color.fromARGB(255, 62, 83, 135),
              offset: Offset(0, 1),
              blurRadius: 3,
              spreadRadius: 2,
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _openPhoneKeyboard,
          backgroundColor: Colors.black,
          elevation: 0,
          shape: const CircleBorder(),
          child: const Icon(Icons.phone, color: Colors.white, size: 30),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: buildMyNavBar(context),
    );
  }

  Container buildMyNavBar(BuildContext context) {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: AppColors.primaryColor,
        boxShadow: [
          BoxShadow(
            color: Color.fromARGB(255, 62, 83, 135),
            offset: Offset(0, 1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          buildNavItem(
            index: 0,
            icon: pageIndex == 0 ? Icons.home_filled : Icons.home_outlined,
            label: "Home",
          ),
          buildNavItem(
            index: 1,
            icon: pageIndex == 1 ? Icons.work_rounded : Icons.work_outline_outlined,
            label: "Task",
          ),
          const SizedBox(width: 25),
          buildNavItem(
            index: 2,
            icon: pageIndex == 2 ? Icons.calendar_today : Icons.calendar_today_outlined,
            label: "Calendar",
          ),
          buildNavItem(
            index: 3,
            icon: pageIndex == 3 ? Icons.leaderboard : Icons.leaderboard_outlined,
            label: "Lead",
          ),
        ],
      ),
    );
  }

  Widget buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = pageIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          pageIndex = index;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 30),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _callSubscription?.cancel();
    _historySubscription?.cancel();
    _permissionSubscription?.cancel();
    super.dispose();
  }
}

// widgets/filter_chip_widget.dart

class FilterChipWidget extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const FilterChipWidget({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          border: Border.all(color: Colors.white),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}


class PhoneKeyboardSheet extends StatefulWidget {
  final CallTrackingService callService;

  const PhoneKeyboardSheet({super.key, required this.callService});

  @override
  State<PhoneKeyboardSheet> createState() => _PhoneKeyboardSheetState();
}

class _PhoneKeyboardSheetState extends State<PhoneKeyboardSheet> {
  String phoneNumber = '';

  final List<Map<String, String>> keypadButtons = [
    {'number': '1', 'letters': ''},
    {'number': '2', 'letters': 'ABC'},
    {'number': '3', 'letters': 'DEF'},
    {'number': '4', 'letters': 'GHI'},
    {'number': '5', 'letters': 'JKL'},
    {'number': '6', 'letters': 'MNO'},
    {'number': '7', 'letters': 'PQRS'},
    {'number': '8', 'letters': 'TUV'},
    {'number': '9', 'letters': 'WXYZ'},
    {'number': '*', 'letters': ''},
    {'number': '0', 'letters': '+'},
    {'number': '#', 'letters': ''},
  ];

  void _onKeypadTap(String value) {
    setState(() {
      phoneNumber += value;
    });
  }

  void _onBackspace() {
    if (phoneNumber.isNotEmpty) {
      setState(() {
        phoneNumber = phoneNumber.substring(0, phoneNumber.length - 1);
      });
    }
  }

  void _onCall() async {
    log('📞 Attempting to call: $phoneNumber');

    if (phoneNumber.isNotEmpty) {
      final success = await widget.callService.makeCall(phoneNumber);

      Navigator.pop(context);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Calling $phoneNumber...')),
        );
      } else {
        _showDialerError();
      }
    } else {
      log('⚠️ phoneNumber is empty, no action taken');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a phone number')),
      );
    }
  }

  void _showDialerError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Could not launch phone dialer. Please check if you have a phone app installed.',
        ),
        action: SnackBarAction(
          label: 'Copy Number',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: phoneNumber));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Phone number copied to clipboard')),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Phone Number Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: Text(
              phoneNumber.isEmpty ? 'Enter phone number' : phoneNumber,
              style: TextStyle(
                color: phoneNumber.isEmpty
                    ? Colors.white.withOpacity(0.7)
                    : Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w300,
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Keypad
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 40,
                  mainAxisSpacing: 9,
                ),
                itemCount: keypadButtons.length,
                itemBuilder: (context, index) {
                  final button = keypadButtons[index];
                  return KeypadButton(
                    number: button['number']!,
                    letters: button['letters']!,
                    onTap: () => _onKeypadTap(button['number']!),
                  );
                },
              ),
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.only(bottom: 30, left: 40, right: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Empty space for balance
                const SizedBox(width: 60),

                // Call Button
                GestureDetector(
                  onTap: _onCall,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.phone,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),

                // Backspace Button
                GestureDetector(
                  onTap: _onBackspace,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.backspace,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class KeypadButton extends StatelessWidget {
  final String number;
  final String letters;
  final VoidCallback onTap;

  const KeypadButton({
    super.key,
    required this.number,
    required this.letters,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                ),
              ),
              if (letters.isNotEmpty)
                Text(
                  letters,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


class CallList extends StatelessWidget {
  final List<CallRecord> callHistory;
  final Function(String) onCallTap;

  const CallList({
    super.key,
    required this.callHistory,
    required this.onCallTap,
  });

  @override
  Widget build(BuildContext context) {
    if (callHistory.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.phone_disabled,
              size: 64,
              color: Colors.white54,
            ),
            SizedBox(height: 16),
            Text(
              'No calls yet',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your call history will appear here',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: callHistory.length + _getSectionCount(),
      itemBuilder: (context, index) {
        final adjustedIndex = _getAdjustedIndex(index);

        if (_isSectionHeader(index)) {
          return SectionTitle(title: _getSectionTitle(index));
        }

        final call = callHistory[adjustedIndex];
        return CallTile(
          call: call,
          onTap: () => onCallTap(call.phoneNumber),
        );
      },
    );
  }

  int _getSectionCount() {
    if (callHistory.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    bool hasToday = false;
    bool hasYesterday = false;
    bool hasEarlier = false;

    for (final call in callHistory) {
      final callDate = DateTime(call.startTime.year, call.startTime.month, call.startTime.day);

      if (callDate == today) {
        hasToday = true;
      } else if (callDate == yesterday) {
        hasYesterday = true;
      } else {
        hasEarlier = true;
      }
    }

    return (hasToday ? 1 : 0) + (hasYesterday ? 1 : 0) + (hasEarlier ? 1 : 0);
  }

  bool _isSectionHeader(int index) {
    if (callHistory.isEmpty) return false;

    if (index == 0) return true;

    final call = callHistory[_getCallIndexForPosition(index)];
    final prevCall = callHistory[_getCallIndexForPosition(index - 1)];

    return _getSectionForCall(call) != _getSectionForCall(prevCall);
  }

  int _getAdjustedIndex(int index) {
    int callIndex = 0;
    int currentIndex = 0;

    while (currentIndex < index) {
      if (!_isSectionHeader(currentIndex)) {
        callIndex++;
      }
      currentIndex++;
    }

    return callIndex;
  }

  int _getCallIndexForPosition(int position) {
    int callIndex = 0;
    int currentPosition = 0;

    while (currentPosition <= position && callIndex < callHistory.length) {
      if (currentPosition == position && !_isSectionHeader(currentPosition)) {
        return callIndex;
      }

      if (!_isSectionHeader(currentPosition)) {
        callIndex++;
      }
      currentPosition++;
    }

    return callIndex - 1;
  }

  String _getSectionTitle(int index) {
    if (callHistory.isEmpty) return '';

    final call = callHistory[_getCallIndexForPosition(index)];
    return _getSectionForCall(call);
  }

  String _getSectionForCall(CallRecord call) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final callDate = DateTime(call.startTime.year, call.startTime.month, call.startTime.day);

    if (callDate == today) {
      return 'Today';
    } else if (callDate == yesterday) {
      return 'Yesterday';
    } else {
      return 'Earlier';
    }
  }
}

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}

class CallTile extends StatelessWidget {
  final CallRecord call;
  final VoidCallback? onTap;

  const CallTile({
    super.key,
    required this.call,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.cardColor,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Colors.white12),
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: call.iconColor.withOpacity(0.2),
          child: Icon(call.icon, color: call.iconColor),
        ),
        title: Text(
          call.displayName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              call.phoneNumber,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  call.callType,
                  style: TextStyle(
                    color: call.callType.toLowerCase().contains("missed") ||
                        call.callType.toLowerCase().contains("not picked")
                        ? Colors.redAccent
                        : Colors.white70,
                    fontSize: 12,
                  ),
                ),
                if (call.durationText.isNotEmpty) ...[
                  Text(
                    ' • ${call.durationText}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              call.formattedTime,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.phone,
                  color: Colors.green,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}