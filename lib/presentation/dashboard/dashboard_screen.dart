import 'dart:async';
import 'dart:developer';
import 'package:call_app/core/constant/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      final hour = startTime.hour == 0
          ? 12
          : (startTime.hour > 12 ? startTime.hour - 12 : startTime.hour);
      return "$hour:${startTime.minute.toString().padLeft(2, '0')} ${startTime.hour >= 12 ? 'PM' : 'AM'}";
    } else if (callDate == yesterday) {
      final hour = startTime.hour == 0
          ? 12
          : (startTime.hour > 12 ? startTime.hour - 12 : startTime.hour);
      return "Yesterday ${hour}:${startTime.minute.toString().padLeft(2, '0')} ${startTime.hour >= 12 ? 'PM' : 'AM'}";
    } else {
      final hour = startTime.hour == 0
          ? 12
          : (startTime.hour > 12 ? startTime.hour - 12 : startTime.hour);
      return "${_getMonthName(startTime.month)} ${startTime.day}, $hour:${startTime.minute.toString().padLeft(2, '0')} ${startTime.hour >= 12 ? 'PM' : 'AM'}";
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

// Simplified Call tracking service without native channels
class CallTrackingService {
  static CallTrackingService? _instance;
  static CallTrackingService get instance =>
      _instance ??= CallTrackingService._();

  CallTrackingService._();

  // Stream controllers
  final StreamController<CallRecord> _callStateController =
      StreamController<CallRecord>.broadcast();
  final StreamController<List<CallRecord>> _callHistoryController =
      StreamController<List<CallRecord>>.broadcast();

  // Current call tracking
  CallRecord? _currentCall;
  List<CallRecord> _callHistory = [];

  // Getters
  Stream<CallRecord> get callStateStream => _callStateController.stream;
  Stream<List<CallRecord>> get callHistoryStream =>
      _callHistoryController.stream;
  CallRecord? get currentCall => _currentCall;
  List<CallRecord> get callHistory => List.unmodifiable(_callHistory);

  // Initialize the service
  Future<bool> initialize() async {
    try {
      // Request phone permission
      await _requestPermissions();

      // Load demo call history
      _addDemoCallHistory();

      log('✅ Call tracking service initialized in demo mode');
      return true;
    } catch (e) {
      log('❌ Failed to initialize call tracking service: $e');
      _addDemoCallHistory(); // Add demo data as fallback
      return true;
    }
  }

  // Request required permissions
  Future<void> _requestPermissions() async {
    try {
      final status = await Permission.phone.request();
      log('📱 Phone permission status: $status');
    } catch (e) {
      log('⚠️ Permission request failed: $e');
    }
  }

  // Make a call using URL launcher
  Future<bool> makeCall(String phoneNumber) async {
    try {
      log('📞 Making call to: $phoneNumber');

      // Clean phone number (remove any formatting)
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      // Create URI for phone call
      final Uri url = Uri(scheme: 'tel', path: cleanNumber);

      // Check if can launch
      if (await canLaunchUrl(url)) {
        final launched = await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );

        if (launched) {
          // Add call record to history
          _addCallRecord(cleanNumber, true);
          return true;
        }
      }

      return false;
    } catch (e) {
      log('❌ Error making call: $e');
      return false;
    }
  }

  // Add call record when call is made
  void _addCallRecord(String phoneNumber, bool isOutgoing) {
    final now = DateTime.now();
    final record = CallRecord(
      phoneNumber: phoneNumber,
      startTime: now,
      endTime: now.add(const Duration(seconds: 30)), // Demo duration
      state: CallState.disconnected,
      isOutgoing: isOutgoing,
      duration: const Duration(seconds: 30),
      contactName: _getContactName(phoneNumber),
    );

    _addCallToHistory(record);
  }

  // Get contact name (placeholder - you can integrate with contacts)
  String _getContactName(String phoneNumber) {
    final contacts = {
      '+15551234567': 'Sarah Johnson',
      '+15559876543': 'John Doe',
      '+15555555555': 'Emergency Contact',
      '5551234567': 'Sarah Johnson',
      '5559876543': 'John Doe',
      '5555555555': 'Emergency Contact',
    };
    return contacts[phoneNumber] ?? '';
  }

  // Add call to history
  void _addCallToHistory(CallRecord record) {
    _callHistory.insert(0, record);
    if (_callHistory.length > 100) {
      _callHistory = _callHistory.take(100).toList();
    }
    _callHistoryController.add(_callHistory);
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
      CallRecord(
        phoneNumber: '+15551111111',
        startTime: now.subtract(const Duration(days: 2, hours: 1)),
        endTime: now.subtract(const Duration(days: 2, hours: 1, minutes: -15)),
        state: CallState.disconnected,
        isOutgoing: true,
        duration: const Duration(minutes: 15),
        contactName: 'Mom',
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
    _callStateController.close();
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

  // Group calls by date
  Map<String, List<CallRecord>> get groupedCalls {
    final Map<String, List<CallRecord>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final call in filteredCalls) {
      final callDate = DateTime(
        call.startTime.year,
        call.startTime.month,
        call.startTime.day,
      );
      String dateKey;

      if (callDate == today) {
        dateKey = 'Today';
      } else if (callDate == yesterday) {
        dateKey = 'Yesterday';
      } else {
        dateKey = 'Earlier';
      }

      grouped[dateKey] = grouped[dateKey] ?? [];
      grouped[dateKey]!.add(call);
    }

    return grouped;
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

          // Call logs list
          Expanded(
            child: filteredCalls.isEmpty
                ? const Center(
                    child: Text(
                      'No calls found',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (final entry in groupedCalls.entries) ...[
                        SectionTitle(title: entry.key),
                        for (final call in entry.value)
                          CallTile(
                            name: call.displayName,
                            number: call.phoneNumber,
                            time: call.formattedTime,
                            callType: call.callType,
                            duration: call.durationText,
                            icon: call.icon,
                            iconColor: call.iconColor,
                            onTap: () =>
                                _callService.makeCall(call.phoneNumber),
                          ),
                      ],
                    ],
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

// Phone keyboard sheet (kept the same as your original)
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
                  icon: const Icon(
                    Icons.backspace_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 20),
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

// Helper widgets (same as your original)
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
              duration != null && duration!.isNotEmpty
                  ? "$callType • $duration"
                  : callType,
              style: TextStyle(
                color:
                    callType.toLowerCase().contains("missed") ||
                        callType.toLowerCase().contains("declined") ||
                        callType.toLowerCase().contains("not picked")
                    ? Colors.redAccent
                    : Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              time,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.phone, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
