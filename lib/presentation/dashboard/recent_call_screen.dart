import 'dart:async';
import 'dart:developer';
import 'package:call_app/blocs/auth/auth_cubit.dart';
import 'package:call_app/core/constant/app_color.dart';
import 'package:call_app/presentation/dashboard/home.dart';
import 'package:call_app/presentation/dashboard/widgets/section_tile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import 'features/calender_screen.dart';
import 'features/call_logs_screen.dart';
import 'features/lead_screen.dart';
import 'features/task_screen.dart';
import 'model/call_record_model.dart';
import 'widgets/call_list.dart';
import 'widgets/call_tracking.dart';
import 'widgets/filter_chip_card.dart';
import 'widgets/phone_keyboard_sheet.dart';

// Call state enum
enum CallState {
  idle,
  ringing,
  offhook, // Call connected
  disconnected,
}

// Call data model
class RecentCallScreen extends StatefulWidget {
  const RecentCallScreen({super.key});
  @override
  State<RecentCallScreen> createState() => _RecentCallScreenState();
}

class _RecentCallScreenState extends State<RecentCallScreen> {
  int pageIndex = 0;
  String selectedFilter = 'All';
  final CallTrackingService _callService = CallTrackingService.instance;
  StreamSubscription<List<CallRecord>>? _historySubscription;

  List<CallRecord> _callHistory = [];
  bool _isLoading = false;
  bool _permissionsGranted = false;
  final pages = [const Page1(), const Page2(), const Page3(), const Page4()];
  @override
  void initState() {
    super.initState();
    _initializeCallTracking();
  }

  Future<void> _initializeCallTracking() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // Check permissions first
      final phoneStatus = await Permission.phone.status;

      if (!phoneStatus.isGranted) {
        // Request permissions if not granted
        await _requestPermissions();
      } else {
        _permissionsGranted = true;
        await _callService.initialize();
        _setupHistoryListener();
      }
    } catch (e) {
      log('❌ Error initializing call tracking: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermissions() async {
    try {
      final status = await Permission.phone.request();

      if (status.isGranted) {
        setState(() {
          _permissionsGranted = true;
        });
        await _callService.initialize();
        _setupHistoryListener();
      } else if (status.isPermanentlyDenied) {
        if (mounted) {
          _showPermissionDeniedDialog();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Phone permissions are required to view call logs'),
              // action: SnackBarAction(label: 'Retry', onPressed:=>),
            ),
          );
        }
      }
    } catch (e) {
      log('❌ Permission request error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Permission error: ${e.toString()}')),
        );
      }
    }
  }

  void _setupHistoryListener() {
    _historySubscription = _callService.callHistoryStream.listen((history) {
      if (mounted) {
        setState(() {
          _callHistory = history;
        });
      }
    });

    // Load initial history
    setState(() {
      _callHistory = _callService.callHistory;
    });
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'Phone permission is required to access call logs. Please enable it in app settings.',
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
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _onRefresh() async {
    if (!_permissionsGranted) {
      await _requestPermissions();
      return;
    }

    try {
      await _callService.refreshCallLogs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Call logs refreshed'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to refresh: ${e.toString()}')),
        );
      }
    }
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          surfaceTintColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => DashboardScreen()),
              );
            },
          ),
          titleSpacing: 0,
          title: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              prefixIcon: const Icon(
                CupertinoIcons.search,
                color: Colors.white54,
                size: 20,
              ),
              prefixIconConstraints: BoxConstraints(
                minHeight: 35.h,
                minWidth: 35.w,
              ),
              suffixIconConstraints: BoxConstraints(
                maxHeight: 30.h,
                maxWidth: 30.w,
              ),
              suffixIcon: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(
                  CupertinoIcons.mic_fill,
                  color: Color(0xFF60A5FA),
                  size: 20,
                ),
                onPressed: () {},
              ),
              hintText: "Search contacts or enter number...",
              hintStyle: GoogleFonts.roboto(
                color: Color(0xFFADAEBC),
                fontSize: 11.sp,
                fontWeight: FontWeight.w400,
              ),
              // Border styles
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFE5E7EB),
                  width: 0.1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFE5E7EB),
                  width: 0.1,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFE5E7EB),
                  width: 0.1,
                ),
              ),
            ),
          ),
          actions: [
            // Notification bell with red dot
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.white),
                  onPressed: () {
                    // Handle notifications
                  },
                ),

                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: () {
                context.read<AuthCubit>().signOut();
              },
              icon: Icon(Icons.logout,color: Colors.white,),
            ),
            IconButton(
              icon: const Icon(Icons.filter_list, color: Colors.white),
              onPressed: () {
                // Handle filter
              },
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter chips
            IconButton(
              onPressed: () {
                context.read<AuthCubit>().signOut();
              },
              icon: Icon(Icons.logout),
            ),
            Divider(color: Color(0xFFE5E7EB), thickness: 0.1.w),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 9,
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
            Divider(color: Color(0xFFE5E7EB), thickness: 0.1.w),

            // Call logs list with RefreshIndicator
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                color: Colors.white,
                backgroundColor: AppColors.primaryColor,
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : !_permissionsGranted
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.phone_disabled,
                              size: 64,
                              color: Colors.white54,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Phone permission required',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Pull down to retry or grant permission',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _requestPermissions,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primaryColor,
                              ),
                              child: const Text('Grant Permission'),
                            ),
                          ],
                        ),
                      )
                    : filteredCalls.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 100),
                          Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.call,
                                  size: 64,
                                  color: Colors.white54,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No calls found',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Pull down to refresh',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(left: 16, right: 16),
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
                                svgAsset: call.svgAsset,
                                iconColor: call.callTypeColor,
                                backgroundColor: call.callTypeBackgroundColor
                                    .withOpacity(0.2),
                                onTap: () =>
                                    _callService.makeCall(call.phoneNumber),
                              ),
                          ],
                        ],
                      ),
              ),
            ),
          ],
        ),
        floatingActionButton: Container(
          height: 70,
          width: 70,
          decoration: BoxDecoration(
            color: Color(0xFF32CD32),
            shape: BoxShape.circle,
            border: Border.all(color: Color(0xFFE5E7EB), width: 1),
            // boxShadow: [
            //   BoxShadow(
            //     color: Color.fromARGB(255, 62, 83, 135),
            //     offset: Offset(0, 1),
            //     blurRadius: 3,
            //     spreadRadius: 2,
            //   ),
            // ],
          ),
          child: FloatingActionButton(
            onPressed: _openPhoneKeyboard,
            backgroundColor: Color(0xFF32CD32),
            elevation: 0,
            shape: const CircleBorder(),
            child: const Icon(Icons.phone, color: Colors.white, size: 30),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: buildMyNavBar(context),
      ),
    );
  }

  Container buildMyNavBar(BuildContext context) {
    return Container(
      height: 84.h,
      decoration: const BoxDecoration(
        color: Color(0xFF334155),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          buildNavItem(index: 0, icons: "assets/icons/home.svg", label: "Home"),
          buildNavItem(index: 1, icons: "assets/icons/task.svg", label: "Task"),
          const SizedBox(width: 25),
          buildNavItem(
            index: 2,
            icons: "assets/icons/calender.svg",
            label: "Calendar",
          ),
          buildNavItem(index: 3, icons: "assets/icons/lead.svg", label: "Lead"),
        ],
      ),
    );
  }

  Widget buildNavItem({
    required int index,
    required String icons,
    required String label,
  }) {
    // final isSelected = pageIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          pageIndex = index;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(icons),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.roboto(
              // color: isSelected ? Colors.white : Colors.white60,
              fontSize: 12.sp,
              color: Color(0xFFBDBDBD),
              fontWeight: FontWeight.w400,
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
