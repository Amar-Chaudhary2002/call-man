// import 'dart:async';
// import 'dart:developer';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:permission_handler/permission_handler.dart';

// import 'dashboard_home.dart';
// import 'features/calender_screen.dart';
// import 'features/lead_screen.dart';
// import 'features/task_screen.dart';
// import 'model/call_record_model.dart';
// import 'widgets/call_tracking.dart';
// import 'widgets/phone_keyboard_sheet.dart';

// class DashboardScreen extends StatefulWidget {
//   const DashboardScreen({super.key});
//   @override
//   State<DashboardScreen> createState() => _DashboardScreenState();
// }

// class _DashboardScreenState extends State<DashboardScreen> {
//   int _currentNavIndex = 0;
//   int _homeTabIndex = 0;
//   final CallTrackingService _callService = CallTrackingService.instance;
//   StreamSubscription<List<CallRecord>>? _historySubscription;
//   List<CallRecord> _callHistory = [];
//   bool _isLoading = false;
//   bool _permissionsGranted = false;
//   String selectedFilter = 'All';
//   String selectedPeriod = 'Today';

//   @override
//   void initState() {
//     super.initState();
//     _initializeCallTracking();
//   }

//   Future<void> _initializeCallTracking() async {
//     setState(() => _isLoading = true);
//     try {
//       final phoneStatus = await Permission.phone.status;
//       if (!phoneStatus.isGranted) {
//         await _requestPermissions();
//       } else {
//         _permissionsGranted = true;
//         await _callService.initialize();
//         _setupHistoryListener();
//       }
//     } catch (e) {
//       log('Error initializing call tracking: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
//       }
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _requestPermissions() async {
//     try {
//       final status = await Permission.phone.request();
//       if (status.isGranted) {
//         setState(() => _permissionsGranted = true);
//         await _callService.initialize();
//         _setupHistoryListener();
//       } else if (status.isPermanentlyDenied && mounted) {
//         _showPermissionDeniedDialog();
//       } else if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Phone permissions are required')),
//         );
//       }
//     } catch (e) {
//       log('Permission request error: $e');
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Permission error: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   void _setupHistoryListener() {
//     _historySubscription = _callService.callHistoryStream.listen((history) {
//       if (mounted) {
//         setState(() => _callHistory = history);
//       }
//     });
//     setState(() => _callHistory = _callService.callHistory);
//   }

//   void _showPermissionDeniedDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Permission Required'),
//         content: const Text(
//           'Phone permission is required to access call logs.',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               openAppSettings();
//             },
//             child: const Text('Settings'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _openPhoneKeyboard() {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => PhoneKeyboardSheet(callService: _callService),
//     );
//   }

//   Future<void> _onRefresh() async {
//     if (!_permissionsGranted) {
//       await _requestPermissions();
//       return;
//     }
//     try {
//       await _callService.refreshCallLogs();
//       if (mounted) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(const SnackBar(content: Text('Call logs refreshed')));
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to refresh: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   List<CallRecord> get filteredCalls {
//     return _callService.getFilteredCalls(selectedFilter);
//   }

//   Map<String, List<CallRecord>> get groupedCalls {
//     final Map<String, List<CallRecord>> grouped = {};
//     final now = DateTime.now();
//     final today = DateTime(now.year, now.month, now.day);
//     final yesterday = today.subtract(const Duration(days: 1));

//     for (final call in filteredCalls) {
//       final callDate = DateTime(
//         call.startTime.year,
//         call.startTime.month,
//         call.startTime.day,
//       );
//       String dateKey = callDate == today
//           ? 'Today'
//           : callDate == yesterday
//           ? 'Yesterday'
//           : 'Earlier';
//       grouped[dateKey] = grouped[dateKey] ?? [];
//       grouped[dateKey]!.add(call);
//     }
//     return grouped;
//   }

//   Widget _getCurrentPage() {
//     switch (_currentNavIndex) {
//       case 0:
//         return _buildHomeContent();
//       case 1:
//         return const TaskScreen();
//       case 2:
//         return const CalendarScreen();
//       case 3:
//         return const LeadScreen();
//       default:
//         return _buildHomeContent();
//     }
//   }

//   Widget _buildHomeContent() {
//     switch (_homeTabIndex) {
//       case 0:
//         return DashboardHomeView(
//           callHistory: _callHistory,
//           isLoading: _isLoading,
//           permissionsGranted: _permissionsGranted,
//           filteredCalls: filteredCalls,
//           onRefresh: _onRefresh,
//           callService: _callService,
//         );
//       case 1:
//         WidgetsBinding.instance.addPostFrameCallback(
//           (_) => _openPhoneKeyboard(),
//         );
//         return DashboardCallsView(
//           groupedCalls: groupedCalls,
//           callService: _callService,
//         );
//       case 2:
//         WidgetsBinding.instance.addPostFrameCallback(
//           (_) => _openPhoneKeyboard(),
//         );
//         return DashboardRecentCallsView(
//           isLoading: _isLoading,
//           permissionsGranted: _permissionsGranted,
//           filteredCalls: filteredCalls,
//           groupedCalls: groupedCalls,
//           onRefresh: _onRefresh,
//           callService: _callService,
//           selectedFilter: selectedFilter,
//           onFilterChanged: (filter) => setState(() => selectedFilter = filter),
//         );
//       default:
//         return DashboardHomeView(
//           callHistory: _callHistory,
//           isLoading: _isLoading,
//           permissionsGranted: _permissionsGranted,
//           filteredCalls: filteredCalls,
//           onRefresh: _onRefresh,
//           callService: _callService,
//         );
//     }
//   }

//   PreferredSizeWidget _buildAppBar() {
//     return AppBar(
//       surfaceTintColor: Colors.transparent,
//       backgroundColor: Colors.transparent,
//       elevation: 0,
//       leading: _currentNavIndex == 0
//           ? IconButton(
//               icon: Icon(
//                 _homeTabIndex == 0 ? Icons.menu : Icons.arrow_back,
//                 color: const Color(0xFF4B5563),
//               ),
//               onPressed: () {
//                 if (_homeTabIndex != 0) setState(() => _homeTabIndex = 0);
//               },
//             )
//           : null,
//       title: TextField(
//         style: const TextStyle(color: Colors.white),
//         decoration: InputDecoration(
//           isDense: true,
//           contentPadding: EdgeInsets.zero,
//           prefixIcon: const Icon(CupertinoIcons.search, color: Colors.white54),
//           hintText: "Search contacts...",
//           hintStyle: GoogleFonts.roboto(color: const Color(0xFFADAEBC)),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(16),
//             borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 0.1),
//           ),
//         ),
//       ),
//       actions: [
//         Stack(
//           children: [
//             IconButton(
//               icon: const Icon(Icons.notifications, color: Colors.white),
//               onPressed: () {},
//             ),
//             Positioned(
//               right: 10,
//               top: 10,
//               child: Container(
//                 width: 8,
//                 height: 8,
//                 decoration: const BoxDecoration(
//                   color: Colors.red,
//                   shape: BoxShape.circle,
//                 ),
//               ),
//             ),
//           ],
//         ),
//         IconButton(
//           icon: const Icon(Icons.filter_list, color: Colors.white),
//           onPressed: () {},
//         ),
//       ],
//     );
//   }

//   Widget _buildFloatingActionButton() {
//     return Container(
//       height: 70,
//       width: 70,
//       decoration: BoxDecoration(
//         color: const Color(0xFF32CD32),
//         shape: BoxShape.circle,
//         border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
//       ),
//       child: FloatingActionButton(
//         onPressed: () {
//           if (_currentNavIndex == 0) {
//             setState(() => _homeTabIndex = _homeTabIndex == 2 ? 1 : 1);
//           }
//           _openPhoneKeyboard();
//         },
//         backgroundColor: const Color(0xFF32CD32),
//         child: const Icon(Icons.phone, color: Colors.white, size: 30),
//       ),
//     );
//   }

//   Widget _buildNavBar() {
//     return Container(
//       height: 84.h,
//       decoration: const BoxDecoration(
//         color: Color(0xFF334155),
//         borderRadius: BorderRadius.only(
//           topLeft: Radius.circular(10),
//           topRight: Radius.circular(10),
//         ),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           _buildNavItem(index: 0, icon: Icons.home, label: "Home"),
//           _buildNavItem(index: 1, icon: Icons.task, label: "Task"),
//           const SizedBox(width: 25),
//           _buildNavItem(
//             index: 2,
//             icon: Icons.calendar_today,
//             label: "Calendar",
//           ),
//           _buildNavItem(index: 3, icon: Icons.people, label: "Lead"),
//         ],
//       ),
//     );
//   }

//   Widget _buildNavItem({
//     required int index,
//     required IconData icon,
//     required String label,
//   }) {
//     final isSelected = _currentNavIndex == index;
//     return GestureDetector(
//       onTap: () => setState(() {
//         _currentNavIndex = index;
//         if (index == 0) _homeTabIndex = 0;
//       }),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             icon,
//             color: isSelected ? Colors.white : const Color(0xFFBDBDBD),
//           ),
//           Text(
//             label,
//             style: GoogleFonts.roboto(
//               fontSize: 12.sp,
//               color: isSelected ? Colors.white : const Color(0xFFBDBDBD),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _historySubscription?.cancel();
//     super.dispose();
//   }
// }
