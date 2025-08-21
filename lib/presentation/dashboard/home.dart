import 'dart:async';
import 'dart:developer';
// import 'package:call_app/blocs/auth/auth_cubit.dart';
import 'package:call_app/core/constant/app_color.dart';
// import 'package:call_app/model/user_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'features/calender_screen.dart';
import 'features/lead_screen.dart';
import 'features/task_screen.dart';
import 'model/call_record_model.dart';
import 'widgets/call_list.dart';
import 'widgets/call_tracking.dart';
import 'widgets/filter_chip_card.dart';
import 'widgets/phone_keyboard_sheet.dart';
import 'widgets/section_tile.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isRefreshing = false;
  int _currentNavIndex = 0;
  int _homeTabIndex = 0;
  final CallTrackingService _callService = CallTrackingService.instance;
  StreamSubscription<List<CallRecord>>? _historySubscription;
  List<CallRecord> _callHistory = [];
  bool _isLoading = false;
  bool _permissionsGranted = false;
  //  UserModel? _userModel;
  // Dashboard specific variables
  String selectedFilter = 'All';
  String selectedPeriod = 'Today';

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

  Future<void> _onRefresh() async {
    if (_isRefreshing) return; // Prevent multiple simultaneous refreshes

    setState(() {
      _isRefreshing = true;
    });

    try {
      if (!_permissionsGranted) {
        await _requestPermissions();
      } else {
        await _callService.refreshCallLogs();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Call logs refreshed'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to refresh: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }
  // Future<void> _onRefresh() async {
  //   if (!_permissionsGranted) {
  //     await _requestPermissions();
  //     return;
  //   }
  //   try {
  //     await _callService.refreshCallLogs();
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('Call logs refreshed'),
  //           duration: Duration(seconds: 1),
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Failed to refresh: ${e.toString()}')),
  //       );
  //     }
  //   }
  // }

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

  // Get current page based on navigation
  Widget _getCurrentPage() {
    switch (_currentNavIndex) {
      case 0: // Home tab
        return _buildHomeContent();
      case 1: // Task tab
        return const TaskScreen();
      case 2: // Calendar tab
        return const CalendarScreen();
      case 3: // Lead tab
        return const LeadScreen();
      default:
        return _buildHomeContent();
    }
  }

  // Build home content with sub-navigation
  Widget _buildHomeContent() {
    switch (_homeTabIndex) {
      case 0: // Dashboard
        return _buildDashboardView();
      case 1: // Calling
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _openPhoneKeyboard();
        });
        return _buildCallingView();
      case 2: // Recent Calls
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _openPhoneKeyboard();
        });
        return _buildRecentCallsView();
      default:
        return _buildDashboardView();
    }
  }

  // Dashboard view (original home content)
  Widget _buildDashboardView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 15.h),
        // User Profile Section
        Container(
          height: 94.h,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          decoration: BoxDecoration(
            color: const Color(0xFF334155),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 0.1.w),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24.r,
                    backgroundImage: const NetworkImage(
                      "https://cdn1.vectorstock.com/i/1000x1000/49/50/calling-icon-blue-3d-vector-5834950.jpg",
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Welcome user",
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
                icon: const Icon(Icons.insights, size: 18, color: Colors.white),
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
          padding: const EdgeInsets.only(left: 10, right: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 15.h),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
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

        // Recent Activity Preview
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Activity',
                      style: GoogleFonts.roboto(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    // TextButton(
                    //   onPressed: () {
                    //     setState(() {
                    //       _homeTabIndex = 2;
                    //     });
                    //   },
                    //   child: Text(
                    //     'View All',
                    //     style: GoogleFonts.roboto(
                    //       fontSize: 12.sp,
                    //       color: const Color(0xFF60A5FA),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
                SizedBox(height: 10.h),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : filteredCalls.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.call, size: 48, color: Colors.white54),
                              SizedBox(height: 8),
                              Text(
                                'No recent calls',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredCalls.length > 3
                              ? 3
                              : filteredCalls.length,
                          itemBuilder: (context, index) {
                            final call = filteredCalls[index];
                            return CallTile(
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
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Calling view
  Widget _buildCallingView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10.h),
        Divider(color: const Color(0xFFE5E7EB), thickness: 0.1.w),
        SizedBox(height: 10.h),
        Padding(
          padding: const EdgeInsets.only(left: 12, right: 16),
          child: _buildHomeTabSelector(),
        ),
        SizedBox(height: 10.h),
        Expanded(
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(left: 16, right: 16),
            children: [
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
                    backgroundColor: call.callTypeBackgroundColor.withOpacity(
                      0.2,
                    ),
                    onTap: () => _callService.makeCall(call.phoneNumber),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // Recent calls view
  Widget _buildRecentCallsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: const Color(0xFFE5E7EB), thickness: 0.1.w),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 9),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    FilterChipWidget(
                      label: 'All',
                      selected: selectedFilter == 'All',
                      onTap: () => setState(() => selectedFilter = 'All'),
                    ),
                    FilterChipWidget(
                      label: 'Missed',
                      selected: selectedFilter == 'Missed',
                      onTap: () => setState(() => selectedFilter = 'Missed'),
                    ),
                    FilterChipWidget(
                      label: 'Outgoing',
                      selected: selectedFilter == 'Outgoing',
                      onTap: () => setState(() => selectedFilter = 'Outgoing'),
                    ),
                    FilterChipWidget(
                      label: 'Incoming',
                      selected: selectedFilter == 'Incoming',
                      onTap: () => setState(() => selectedFilter = 'Incoming'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(color: const Color(0xFFE5E7EB), thickness: 0.1.w),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            color: Colors.white,
            backgroundColor: AppColors.primaryColor,
            child: (_isLoading || _isRefreshing)
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : !_permissionsGranted
                ? _buildPermissionView()
                : filteredCalls.isEmpty
                ? _buildEmptyView()
                : _buildCallsList(),
          ),
        ),
      ],
    );
  }

  // Helper widget for permission view
  Widget _buildPermissionView() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.phone_disabled, size: 64, color: Colors.white54),
            const SizedBox(height: 16),
            const Text(
              'Phone permission required',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pull down to retry or grant permission',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await _requestPermissions();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryColor,
              ),
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      ],
    );
  }

  // Helper widget for empty view
  Widget _buildEmptyView() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        const Center(
          child: Column(
            children: [
              Icon(Icons.call, size: 64, color: Colors.white54),
              SizedBox(height: 16),
              Text(
                'No calls found',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Pull down to refresh',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper widget for calls list
  Widget _buildCallsList() {
    return ListView(
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
              backgroundColor: call.callTypeBackgroundColor.withOpacity(0.2),
              onTap: () => _callService.makeCall(call.phoneNumber),
            ),
        ],
      ],
    );
  }

  // Home tab selector (Recent, Favorites, Team)
  Widget _buildHomeTabSelector() {
    List<String> tabs = ['Recent', 'Favorites', 'Team'];
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.asMap().entries.map((entry) {
            int index = entry.key + 1;
            String tab = entry.value;
            bool isSelected = _homeTabIndex == index;

            return Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _homeTabIndex = index;
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 21.w,
                    vertical: 7.h,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF172033)
                        : const Color(0xFF334155),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    tab,
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
        color: const Color(0xFFE5E7EB),
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
                        : const Color(0xFF334155),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 0.1,
                    ),
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
          const Color(0xFF20C997),
          Icons.phone,
        ),
        _buildDashboardCard(
          '12',
          'Active Leads',
          const Color(0xFFFFD700),
          Icons.person_add,
        ),
        _buildDashboardCard(
          '8',
          'Follow-Ups',
          const Color(0xFFFFB347),
          Icons.schedule,
        ),
        _buildDashboardCard(
          '68%',
          'Conversion',
          const Color(0xFF40E0D0),
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

  Widget _buildAppBarLeading() {
    if (_currentNavIndex == 0) {
      return IconButton(
        icon: _homeTabIndex == 0
            ? const Icon(Icons.menu, color: Color(0xFF4B5563))
            : const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          if (_homeTabIndex != 0) {
            setState(() => _homeTabIndex = 0);
          } else {
            // Handle menu button press
            // Scaffold.of(context).openDrawer();
          }
        },
      );
    }
    return const SizedBox.shrink();
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
          leading: _buildAppBarLeading(),
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
                // IconButton(
                //   onPressed: () {
                //     context.read<AuthCubit>().signOut();
                //   },
                //   icon: const Icon(Icons.logout, color: Colors.white),
                // ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 8,
                    height: 8,
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
        body: _getCurrentPage(),
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
              if (_currentNavIndex == 0) {
                if (_homeTabIndex == 2) {
                  _openPhoneKeyboard();
                } else {
                  setState(() {
                    _homeTabIndex = 1;
                  });
                }
              } else {
                _openPhoneKeyboard();
              }
            },
            backgroundColor: const Color(0xFF32CD32),
            elevation: 0,
            shape: const CircleBorder(),
            child: const Icon(Icons.phone, color: Colors.white, size: 30),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: _buildNavBar(context),
      ),
    );
  }

  Widget _buildNavBar(BuildContext context) {
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
          _buildNavItem(
            index: 0,
            icons: "assets/icons/home.svg",
            label: "Home",
          ),
          _buildNavItem(
            index: 1,
            icons: "assets/icons/task.svg",
            label: "Task",
          ),
          const SizedBox(width: 25),
          _buildNavItem(
            index: 2,
            icons: "assets/icons/calender.svg",
            label: "Calendar",
          ),
          _buildNavItem(
            index: 3,
            icons: "assets/icons/lead.svg",
            label: "Lead",
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String icons,
    required String label,
  }) {
    final isSelected = _currentNavIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentNavIndex = index;
          // Reset home tab to dashboard when navigating away and back
          if (index == 0) {
            _homeTabIndex = 0;
          }
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            icons,
            color: isSelected ? Colors.white : const Color(0xFFBDBDBD),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 12.sp,
              color: isSelected ? Colors.white : const Color(0xFFBDBDBD),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
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
