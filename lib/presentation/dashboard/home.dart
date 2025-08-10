import 'dart:async';
import 'dart:developer';
import 'package:call_app/core/constant/app_color.dart';
import 'package:call_app/presentation/dashboard/calling_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
import 'widgets/phone_keyboard_sheet.dart';

// Call state enum
enum CallState { idle, ringing, offhook, disconnected }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<DashboardScreen> {
  int pageIndex = 0;
  String selectedFilter = 'All';
  final CallTrackingService _callService = CallTrackingService.instance;
  StreamSubscription<List<CallRecord>>? _historySubscription;

  List<CallRecord> _callHistory = [];
  bool _isLoading = false;
  bool _permissionsGranted = false;
  String selectedPeriod = 'Today';

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
      final phoneStatus = await Permission.phone.status;

      if (!phoneStatus.isGranted) {
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

  void _openPhoneKeyboard() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PhoneKeyboardSheet(callService: _callService),
    );
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
      decoration: const BoxDecoration(
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
            icon: const Icon(Icons.menu, color: Color(0xFF4B5563)),
            onPressed: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (context) => CallingScreen()),
              // );
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
                color: const Color(0xFFADAEBC),
                fontSize: 11.sp,
                fontWeight: FontWeight.w400,
              ),
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
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.white),
                  onPressed: () {},
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
              icon: const Icon(Icons.filter_list, color: Colors.white),
              onPressed: () {},
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 15.h),
            // User Profile Section
            Container(
              height: 94.h,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: const Color(0xFF334155),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                  width: 0.1.w,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24.r,
                        backgroundImage: const NetworkImage(
                          "https://via.placeholder.com/150",
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Welcome, Alex",
                            style: GoogleFonts.roboto(
                              color: Colors.white,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            "+1 (555) 123-4567",
                            style: GoogleFonts.roboto(
                              color: Colors.white60,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.insights,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: Text(
                      "Insights",
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: const Color(0xFFE5E7EB),
                          width: 0.1.w,
                        ),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Dashboard Analytics Section
            Padding(
              padding: EdgeInsets.only(left: 10, right: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 15.h),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Color(0xFFE5E7EB),
                        width: 0.1.w,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildHeader(),
                        SizedBox(height: 20.h),
                        _buildTimePeriodSelector(),
                      ],
                    ),
                  ),

                  SizedBox(height: 20.h),
                  SizedBox(height: 200.h, child: _buildDashboardCards()),
                ],
              ),
            ),

            // Call Logs Section
            Expanded(
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
                              Icon(Icons.call, size: 64, color: Colors.white54),
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
                        Text(
                          'Recent Activity',
                          style: GoogleFonts.roboto(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        for (final entry in groupedCalls.entries) ...[
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
          ],
        ),
        floatingActionButton: Container(
          height: 70,
          width: 70,
          decoration: BoxDecoration(
            color: const Color(0xFF32CD32),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          ),
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CallingScreen()),
              );
              _openPhoneKeyboard();
            },
            backgroundColor: const Color(0xFF32CD32),
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

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.white, size: 20.sp),
              SizedBox(width: 6.w),
              Text(
                'Today, Dec 15',
                style: GoogleFonts.roboto(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildNavigationButton(Icons.chevron_left),
              SizedBox(width: 7.w),
              _buildNavigationButton(Icons.chevron_right),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton(IconData icon) {
    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Icon(icon, color: Colors.black, size: 20.sp),
    );
  }

  Widget _buildTimePeriodSelector() {
    List<String> periods = ['Today', 'Week', 'Month', 'Custom'];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: periods.map((period) {
            bool isSelected = period == selectedPeriod;
            return Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    selectedPeriod = period;
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 19.w,
                    vertical: 5.h,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF172033)
                        : Color(0xFF334155),
                    border: Border.all(color: Color(0xFFE5E7EB), width: 0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    period,
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDashboardCards() {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 16.h,
      crossAxisSpacing: 16.w,
      childAspectRatio: 2.1,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildDashboardCard(
          '24',
          'Calls Handled',
          Color(0xFF20C997),
          Icons.phone,
        ),
        _buildDashboardCard(
          '12',
          'Active Leads',
          Color(0xFFFFD700),
          Icons.person_add,
        ),
        _buildDashboardCard(
          '8',
          'Follow-Ups',
          Color(0xFFFFB347),
          Icons.schedule,
        ),
        _buildDashboardCard(
          '68%',
          'Conversion',
          Color(0xFF40E0D0),
          Icons.trending_up,
        ),
      ],
    );
  }

  Widget _buildDashboardCard(
    String value,
    String label,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.73),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 0.1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 0.1.w,
                  ),
                ),
                child: Icon(icon, color: color, size: 18.sp),
              ),
            ],
          ),
          Text(
            label,
            style: GoogleFonts.roboto(
              color: color,
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _historySubscription?.cancel();
    super.dispose();
  }
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
  return GestureDetector(
    onTap: () {
      // Navigation logic here
    },
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(icons),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 12.sp,
            color: const Color(0xFFBDBDBD),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    ),
  );
}
