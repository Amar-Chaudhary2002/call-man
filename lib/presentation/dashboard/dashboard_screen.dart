import 'dart:async';
import 'dart:developer';
import 'package:call_app/core/constant/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

// Call state enum
enum CallState {
  idle,
  ringing,
  offhook, // Call connected
  disconnected,
}

// Call data model
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

    if (callDate == today) {
      return "${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')} ${startTime.hour >= 12 ? 'PM' : 'AM'}";
    } else if (callDate == yesterday) {
      return "${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')} ${startTime.hour >= 12 ? 'PM' : 'AM'}";
    } else {
      return "${_getMonthName(startTime.month)} ${startTime.day}, ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')} ${startTime.hour >= 12 ? 'PM' : 'AM'}";
    }
  }

  String _getMonthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
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
}

// Call tracking service
class CallTrackingService {
  static const MethodChannel _channel = MethodChannel('call_tracking');
  static const EventChannel _eventChannel = EventChannel('call_state_events');

  static CallTrackingService? _instance;
  static CallTrackingService get instance =>
      _instance ??= CallTrackingService._();

  CallTrackingService._();

  // Stream controllers
  final StreamController<CallRecord> _callStateController =
      StreamController<CallRecord>.broadcast();
  final StreamController<bool> _networkStatusController =
      StreamController<bool>.broadcast();
  final StreamController<List<CallRecord>> _callHistoryController =
      StreamController<List<CallRecord>>.broadcast();

  // Current call tracking
  CallRecord? _currentCall;
  bool _isNetworkConnected = true;
  StreamSubscription? _callStateSubscription;
  List<CallRecord> _callHistory = [];

  // Getters
  Stream<CallRecord> get callStateStream => _callStateController.stream;
  Stream<bool> get networkStatusStream => _networkStatusController.stream;
  Stream<List<CallRecord>> get callHistoryStream =>
      _callHistoryController.stream;
  CallRecord? get currentCall => _currentCall;
  bool get isNetworkConnected => _isNetworkConnected;
  List<CallRecord> get callHistory => List.unmodifiable(_callHistory);

  // Initialize the service
  Future<bool> initialize() async {
    try {
      // Request necessary permissions
      final permissionsGranted = await _requestPermissions();
      if (!permissionsGranted) {
        log('❌ Required permissions not granted');
        // Continue anyway for demo purposes
      }

      // Setup method channel handlers
      _channel.setMethodCallHandler(_handleMethodCall);

      // Listen to call state events
      _callStateSubscription = _eventChannel.receiveBroadcastStream().listen(
        _handleCallStateEvent,
        onError: (error) {
          log('❌ Call state event error: $error');
        },
      );

      // Load existing call history
      await _loadCallHistory();

      // Initialize native service (if available)
      try {
        final result = await _channel.invokeMethod('initialize');
        log('✅ Call tracking service initialized: $result');
      } catch (e) {
        log('⚠️ Native call tracking not available, using fallback mode');
        _addDemoCallHistory(); // Add some demo data for testing
      }

      return true;
    } catch (e) {
      log('❌ Failed to initialize call tracking service: $e');
      _addDemoCallHistory(); // Add demo data as fallback
      return true; // Continue with demo mode
    }
  }

  // Request required permissions
  Future<bool> _requestPermissions() async {
    final permissions = [
      Permission.phone,
      Permission.microphone,
      Permission.storage,
    ];

    Map<Permission, PermissionStatus> statuses = await permissions.request();

    return statuses.values.any(
      (status) =>
          status == PermissionStatus.granted ||
          status == PermissionStatus.limited,
    );
  }

  // Handle method calls from native
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onCallStateChanged':
        _handleCallStateChange(call.arguments);
        break;
      case 'onNetworkStatusChanged':
        _handleNetworkStatusChange(call.arguments);
        break;
      default:
        log('⚠️ Unknown method call: ${call.method}');
    }
  }

  // Handle call state events
  void _handleCallStateEvent(dynamic event) {
    if (event is Map) {
      _handleCallStateChange(event);
    }
  }

  // Handle call state changes
  void _handleCallStateChange(dynamic data) {
    try {
      final Map<String, dynamic> callData = Map<String, dynamic>.from(data);

      final phoneNumber = callData['phoneNumber'] as String? ?? '';
      final stateString = callData['state'] as String? ?? 'idle';
      final isOutgoing = callData['isOutgoing'] as bool? ?? false;
      final isConnected = callData['isConnected'] as bool? ?? false;

      final state = _parseCallState(stateString);
      final now = DateTime.now();

      // Create or update call record
      if (_currentCall == null || _currentCall!.phoneNumber != phoneNumber) {
        // New call
        _currentCall = CallRecord(
          phoneNumber: phoneNumber,
          startTime: now,
          state: state,
          isOutgoing: isOutgoing,
          isConnected: isConnected,
          contactName: _getContactName(phoneNumber),
        );
      } else {
        // Update existing call
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

      log(
        '📞 Call state changed: ${_currentCall!.phoneNumber} - ${_currentCall!.callType}',
      );
      _callStateController.add(_currentCall!);

      // Save call record if disconnected
      if (state == CallState.disconnected) {
        _addCallToHistory(_currentCall!);
        _currentCall = null;
      }
    } catch (e) {
      log('❌ Error handling call state change: $e');
    }
  }

  // Handle network status changes
  void _handleNetworkStatusChange(dynamic data) {
    if (data is bool) {
      _isNetworkConnected = data;
      _networkStatusController.add(_isNetworkConnected);
      log('🌐 Network status changed: $_isNetworkConnected');
    }
  }

  // Parse call state from string
  CallState _parseCallState(String stateString) {
    switch (stateString.toLowerCase()) {
      case 'ringing':
        return CallState.ringing;
      case 'offhook':
        return CallState.offhook;
      case 'disconnected':
        return CallState.disconnected;
      default:
        return CallState.idle;
    }
  }

  // Get contact name (placeholder - you can integrate with contacts)
  String _getContactName(String phoneNumber) {
    // You can integrate with flutter_contacts package here
    final contacts = {
      '+15551234567': 'Sarah Johnson',
      '+15559876543': 'John Doe',
      '+15555555555': 'Emergency Contact',
    };
    return contacts[phoneNumber] ?? '';
  }

  // Make a call and track it
  Future<bool> makeCall(String phoneNumber) async {
    try {
      log('📞 Making call to: $phoneNumber');

      // Track outgoing call
      _currentCall = CallRecord(
        phoneNumber: phoneNumber,
        startTime: DateTime.now(),
        state: CallState.ringing,
        isOutgoing: true,
        contactName: _getContactName(phoneNumber),
      );

      _callStateController.add(_currentCall!);

      // Use URL launcher to make call
      final Uri url = Uri.parse('tel:$phoneNumber');
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (launched) {
        // Simulate call state changes for demo
        _simulateCallStateChanges(phoneNumber);
      }

      return launched;
    } catch (e) {
      log('❌ Error making call: $e');
      return false;
    }
  }

  // Simulate call state changes for demo purposes
  void _simulateCallStateChanges(String phoneNumber) {
    Timer(const Duration(seconds: 2), () {
      _handleCallStateChange({
        'phoneNumber': phoneNumber,
        'state': 'offhook',
        'isOutgoing': true,
        'isConnected': true,
      });
    });

    Timer(const Duration(seconds: 10), () {
      _handleCallStateChange({
        'phoneNumber': phoneNumber,
        'state': 'disconnected',
        'isOutgoing': true,
        'isConnected': false,
      });
    });
  }

  // Add call to history
  void _addCallToHistory(CallRecord record) {
    _callHistory.insert(0, record);
    if (_callHistory.length > 100) {
      _callHistory = _callHistory.take(100).toList();
    }
    _callHistoryController.add(_callHistory);
    _saveCallHistory();
  }

  // Load call history from storage
  Future<void> _loadCallHistory() async {
    // In a real app, you'd load from SharedPreferences or SQLite
    _callHistory = [];
    _callHistoryController.add(_callHistory);
  }

  // Save call history to storage
  Future<void> _saveCallHistory() async {
    // In a real app, you'd save to SharedPreferences or SQLite
    log('💾 Saving call history: ${_callHistory.length} records');
  }

  // Add demo call history
  void _addDemoCallHistory() {
    final now = DateTime.now();
    final demoRecords = [
      CallRecord(
        phoneNumber: '+15551234567',
        startTime: now.subtract(const Duration(hours: 1)),
        endTime: now.subtract(const Duration(hours: 1, minutes: -25)),
        state: CallState.disconnected,
        isOutgoing: true,
        duration: const Duration(minutes: 25),
        contactName: 'Sarah Johnson',
      ),
      CallRecord(
        phoneNumber: '+15551234567',
        startTime: now.subtract(const Duration(hours: 2)),
        endTime: now.subtract(const Duration(hours: 2, minutes: -8)),
        state: CallState.disconnected,
        isOutgoing: false,
        duration: const Duration(minutes: 8),
        contactName: 'Sarah Johnson',
      ),
      CallRecord(
        phoneNumber: '+15551234567',
        startTime: now.subtract(const Duration(hours: 3)),
        endTime: now.subtract(const Duration(hours: 3)),
        state: CallState.disconnected,
        isOutgoing: false,
        duration: Duration.zero,
        contactName: 'Sarah Johnson',
      ),
      CallRecord(
        phoneNumber: '+15559876543',
        startTime: now.subtract(const Duration(days: 1, hours: 2)),
        endTime: now.subtract(const Duration(days: 1, hours: 2)),
        state: CallState.disconnected,
        isOutgoing: false,
        duration: Duration.zero,
        contactName: 'John Doe',
      ),
      CallRecord(
        phoneNumber: '+15555555555',
        startTime: now.subtract(const Duration(days: 1, hours: 4)),
        endTime: now.subtract(const Duration(days: 1, hours: 4)),
        state: CallState.disconnected,
        isOutgoing: true,
        duration: Duration.zero,
        contactName: 'Emergency Contact',
      ),
    ];

    _callHistory = demoRecords;
    _callHistoryController.add(_callHistory);
  }

  // Filter calls by type
  List<CallRecord> getFilteredCalls(String filter) {
    switch (filter.toLowerCase()) {
      case 'missed':
        return _callHistory
            .where(
              (call) =>
                  call.callType.toLowerCase().contains('missed') ||
                  call.callType.toLowerCase().contains('not picked'),
            )
            .toList();
      case 'outgoing':
        return _callHistory.where((call) => call.isOutgoing).toList();
      case 'incoming':
        return _callHistory
            .where(
              (call) =>
                  !call.isOutgoing &&
                  call.duration != null &&
                  call.duration!.inSeconds > 0,
            )
            .toList();
      default:
        return _callHistory;
    }
  }

  // Dispose resources
  void dispose() {
    _callStateSubscription?.cancel();
    _callStateController.close();
    _networkStatusController.close();
    _callHistoryController.close();
  }
}

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

  CallRecord? _currentCall;
  List<CallRecord> _callHistory = [];

  final pages = [const Page1(), const Page2(), const Page3(), const Page4()];

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

    // Load initial history
    setState(() {
      _callHistory = _callService.callHistory;
    });
  }

  void _showCallNotification(CallRecord call) {
    String message;
    switch (call.state) {
      case CallState.ringing:
        message = call.isOutgoing
            ? 'Calling ${call.displayName}...'
            : 'Incoming call from ${call.displayName}';
        break;
      case CallState.offhook:
        message = 'Call connected with ${call.displayName}';
        break;
      case CallState.disconnected:
        final duration = call.duration?.inMinutes ?? 0;
        message = 'Call ended. Duration: ${duration}m';
        break;
      default:
        return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: call.state == CallState.disconnected
            ? Colors.red
            : Colors.green,
        duration: const Duration(seconds: 2),
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
        leading: const Icon(Icons.arrow_back, color: Colors.white),
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
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8,
                ),
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
              // Expanded(
              //   child: CallList(
              //     callHistory: filteredCalls,
              //     onCallTap: (phoneNumber) =>
              //         _callService.makeCall(phoneNumber),
              //   ),
              // ),
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
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        boxShadow: [
          BoxShadow(
            color: Color.fromARGB(255, 62, 83, 135),
            offset: Offset(0, 1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
        borderRadius: const BorderRadius.only(
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
            icon: pageIndex == 1
                ? Icons.work_rounded
                : Icons.work_outline_outlined,
            label: "Task",
          ),
          const SizedBox(width: 25),
          buildNavItem(
            index: 2,
            icon: pageIndex == 2
                ? Icons.calendar_today
                : Icons.calendar_today_outlined,
            label: "Calendar",
          ),
          buildNavItem(
            index: 3,
            icon: pageIndex == 3
                ? Icons.leaderboard
                : Icons.leaderboard_outlined,
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
    super.dispose();
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Calling $phoneNumber...')));
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
          // Phone Number Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: Text(
              phoneNumber.isEmpty ? '+1 (555) 123' : phoneNumber,
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Empty space for balance
                const SizedBox(width: 70),
                // Call Button
                Expanded(
                  child: IconButton(
                    onPressed: _onCall,
                    icon: Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        color: Color(0xFF252424),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.phone,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),

                IconButton(
                  onPressed: _onBackspace,
                  icon: SvgPicture.asset('assets/icons/close.svg'),
                ),
                SizedBox(width: 20),
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
    return TextButton(
      onPressed: onTap,
      child: Center(
        child: Text(
          number,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
    );
  }
}

class Page1 extends StatelessWidget {
  const Page1({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Page Number 1",
        style: TextStyle(
          color: Colors.green[900],
          fontSize: 45,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class Page2 extends StatelessWidget {
  const Page2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Page Number 2",
        style: TextStyle(
          color: Colors.green[900],
          fontSize: 45,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class Page3 extends StatelessWidget {
  const Page3({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Page Number 3",
        style: TextStyle(
          color: Colors.green[900],
          fontSize: 45,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class Page4 extends StatelessWidget {
  const Page4({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Page Number 4",
        style: TextStyle(
          color: Colors.green[900],
          fontSize: 45,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

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

class CallList extends StatelessWidget {
  const CallList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionTitle(title: "Today"),
        CallTile(
          name: "Sarah Johnson",
          number: "+1 (555) 123-4567",
          time: "8:16 PM",
          callType: "Outgoing",
          duration: "25 min",
          icon: Icons.call_made,
          iconColor: Colors.green,
          onTap: () {
            // Handle call tile tap
          },
        ),
        CallTile(
          name: "Sarah Johnson",
          number: "+1 (555) 123-4567",
          time: "8:16 PM",
          callType: "Incoming",
          duration: "8 min",
          icon: Icons.call_received,
          iconColor: Colors.blue,
          onTap: () {
            // Handle call tile tap
          },
        ),
        CallTile(
          name: "Sarah Johnson",
          number: "+1 (555) 123-4567",
          time: "8:16 PM",
          callType: "Missed call",
          icon: Icons.call_missed,
          iconColor: Colors.red,
          onTap: () {
            // Handle call tile tap
          },
        ),
        const SectionTitle(title: "Yesterday"),
        CallTile(
          name: "Sarah Johnson",
          number: "+1 (555) 123-4567",
          time: "8:16 PM",
          callType: "Not picked",
          icon: Icons.access_time,
          iconColor: Colors.orange,
          onTap: () {
            // Handle call tile tap
          },
        ),
        CallTile(
          name: "Sarah Johnson",
          number: "+1 (555) 123-4567",
          time: "8:16 PM",
          callType: "Declined",
          icon: Icons.call_end,
          iconColor: Colors.red,
          onTap: () {
            // Handle call tile tap
          },
        ),
        CallTile(
          name: "Sarah Johnson",
          number: "+1 (555) 123-4567",
          time: "8:16 PM",
          callType: "Outgoing",
          duration: "25 min",
          icon: Icons.call_made,
          iconColor: Colors.green,
          onTap: () {
            // Handle call tile tap
          },
        ),
        const SectionTitle(title: "Earlier"),
        CallTile(
          name: "Sarah Johnson",
          number: "+1 (555) 123-4567",
          time: "July 14, 8:16 PM",
          callType: "Not picked",
          icon: Icons.access_time,
          iconColor: Colors.orange,
          onTap: () {
            // Handle call tile tap
          },
        ),
        CallTile(
          name: "Sarah Johnson",
          number: "+1 (555) 123-4567",
          time: "July 14, 8:16 PM",
          callType: "Missed call",
          icon: Icons.call_missed,
          iconColor: Colors.red,
          onTap: () {
            // Handle call tile tap
          },
        ),
      ],
    );
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
  final String name;
  final String number;
  final String time;
  final String callType;
  final String? duration;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  const CallTile({
    super.key,
    required this.name,
    required this.number,
    required this.time,
    required this.callType,
    this.duration,
    required this.icon,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF25316D),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Colors.white12),
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.2),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              number,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
            Text(
              duration != null ? "$callType • $duration" : callType,
              style: TextStyle(
                color:
                    callType.toLowerCase().contains("missed") ||
                        callType.toLowerCase().contains("declined")
                    ? Colors.redAccent
                    : Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Text(
          time,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ),
    );
  }
}

/// error notes for api's
