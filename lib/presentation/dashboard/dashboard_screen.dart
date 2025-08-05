import 'dart:async';
import 'dart:developer';
import 'package:android_intent_plus/flag.dart';
import 'package:call_app/blocs/auth/auth_cubit.dart';
import 'package:call_app/core/constant/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:call_log/call_log.dart';
import 'package:flutter/services.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' show Platform;

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

  Stream<List<CallRecord>> get callHistoryStream =>
      _callHistoryController.stream;
  List<CallRecord> get callHistory => List.unmodifiable(_callHistory);

  Future<bool> initialize() async {
    try {
      await _requestPermissions();
      await _loadCallLogs();
      log('✅ Call tracking service initialized with real call logs');
      return true;
    } catch (e) {
      log('❌ Failed to initialize call tracking service: $e');
      return false;
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
      final status = await Permission.phone.request();
      if (!status.isGranted) {
        await Permission.phone.request();
      }
      log('📱 Phone permission status: $status');
    } catch (e) {
      log('⚠️ Permission request failed: $e');
    }
  }

  Future<void> _loadCallLogs() async {
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

      // First try standard URL launch
      final url = Uri(scheme: 'tel', path: cleanNumber);

      // Check if device can handle tel: URIs
      if (await canLaunchUrl(url)) {
        try {
          final launched = await launchUrl(
            url,
            mode: LaunchMode.externalApplication,
          );
          if (launched) return true;
        } catch (e) {
          log('Standard URL launch failed: $e');
        }
      }

      // Android-specific fallback
      if (Platform.isAndroid) {
        try {
          // Method 1: Use Android Intent directly
          final intent = AndroidIntent(
            action: 'android.intent.action.DIAL',
            data: 'tel:$cleanNumber',
            flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
          );
          await intent.launch();
          return true;
        } catch (e) {
          log('Android Intent failed: $e');

          // Method 2: Try native platform channel as last resort
          try {
            const platform = MethodChannel('phone_dialer');
            await platform.invokeMethod('dialPhoneNumber', {
              'number': cleanNumber,
            });
            return true;
          } catch (e) {
            log('Native channel failed: $e');
          }
        }
      }

      // If all else fails
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int pageIndex = 0;
  String selectedFilter = 'All';
  final CallTrackingService _callService = CallTrackingService.instance;
  StreamSubscription<List<CallRecord>>? _historySubscription;

  List<CallRecord> _callHistory = [];

  final pages = [const Page1(), const Page2(), const Page3(), const Page4()];

  @override
  void initState() {
    super.initState();
    _initializeCallTracking();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissions();
    });
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.phone.request();
    if (status.isGranted) {
      await _callService.initialize();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone permissions are required')),
      );
    }
  }

  Future<void> _initializeCallTracking() async {
    await _callService.initialize();

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
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.search, color: Colors.white),
          ),
          IconButton(
            onPressed: () {
              context.read<AuthCubit>().signOut();
            },
            icon: Icon(Icons.logout),
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
    _historySubscription?.cancel();
    _callService.dispose();
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w300,
            ),
          ),
          if (letters.isNotEmpty)
            Text(
              letters,
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
        ],
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
        "Call Logs",
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
        "Tasks",
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
        "Calendar",
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
        "Leads",
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
