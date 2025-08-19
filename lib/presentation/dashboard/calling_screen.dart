// import 'dart:async';
// import 'package:call_app/presentation/dashboard/recent_call_screen.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'model/call_record_model.dart';
// import 'widgets/call_list.dart';
// import 'widgets/call_tracking.dart';

// class CallingScreen extends StatefulWidget {
//   const CallingScreen({super.key});
//   @override
//   State<CallingScreen> createState() => _CallingScreenState();
// }

// class _CallingScreenState extends State<CallingScreen> {
//   int pageIndex = 0;
//   String selectedFilter = 'All';
//   final CallTrackingService _callService = CallTrackingService.instance;
//   StreamSubscription<List<CallRecord>>? _historySubscription;
//   String selectedPeriod = 'Today';
//   String selectedTab = 'Recent';

//   @override
//   void initState() {
//     super.initState();
//     // _initializeCallTracking();
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
//       String dateKey;

//       if (callDate == today) {
//         dateKey = 'Today';
//       } else if (callDate == yesterday) {
//         dateKey = 'Yesterday';
//       } else {
//         dateKey = 'Earlier';
//       }

//       grouped[dateKey] = grouped[dateKey] ?? [];
//       grouped[dateKey]!.add(call);
//     }

//     return grouped;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
//           begin: Alignment.centerLeft,
//           end: Alignment.centerRight,
//         ),
//       ),
//       child: Scaffold(
//         backgroundColor: Colors.transparent,
//         appBar: AppBar(
//           surfaceTintColor: Colors.transparent,
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//           leading: IconButton(
//             icon: const Icon(Icons.arrow_back, color: Colors.white),
//             onPressed: () {
//               Navigator.pop(context);
//             },
//           ),
//           titleSpacing: 0,
//           title: TextField(
//             style: const TextStyle(color: Colors.white),
//             decoration: InputDecoration(
//               isDense: true,
//               contentPadding: EdgeInsets.zero,
//               prefixIcon: const Icon(
//                 CupertinoIcons.search,
//                 color: Colors.white54,
//                 size: 20,
//               ),
//               prefixIconConstraints: BoxConstraints(
//                 minHeight: 35.h,
//                 minWidth: 35.w,
//               ),
//               suffixIconConstraints: BoxConstraints(
//                 maxHeight: 30.h,
//                 maxWidth: 30.w,
//               ),
//               suffixIcon: IconButton(
//                 padding: EdgeInsets.zero,
//                 icon: const Icon(
//                   CupertinoIcons.mic_fill,
//                   color: Color(0xFF60A5FA),
//                   size: 20,
//                 ),
//                 onPressed: () {},
//               ),
//               hintText: "Search contacts or enter number...",
//               hintStyle: GoogleFonts.roboto(
//                 color: const Color(0xFFADAEBC),
//                 fontSize: 11.sp,
//                 fontWeight: FontWeight.w400,
//               ),
//               enabledBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(16),
//                 borderSide: const BorderSide(
//                   color: Color(0xFFE5E7EB),
//                   width: 0.1,
//                 ),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(16),
//                 borderSide: const BorderSide(
//                   color: Color(0xFFE5E7EB),
//                   width: 0.1,
//                 ),
//               ),
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(16),
//                 borderSide: const BorderSide(
//                   color: Color(0xFFE5E7EB),
//                   width: 0.1,
//                 ),
//               ),
//             ),
//           ),
//           actions: [
//             Stack(
//               clipBehavior: Clip.none,
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.notifications, color: Colors.white),
//                   onPressed: () {},
//                 ),
//                 Positioned(
//                   right: 10,
//                   top: 10,
//                   child: Container(
//                     width: 10,
//                     height: 10,
//                     decoration: const BoxDecoration(
//                       color: Colors.red,
//                       shape: BoxShape.circle,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             IconButton(
//               icon: const Icon(Icons.filter_list, color: Colors.white),
//               onPressed: () {},
//             ),
//           ],
//         ),
//         body: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             SizedBox(height: 10.h),
//             // Call Logs Section
//             Divider(color: Color(0xFFE5E7EB), thickness: 0.1.w),
//             SizedBox(height: 10.h),
//             Padding(
//               padding: const EdgeInsets.only(left: 12, right: 16),
//               child: _buildNavigationFeature(),
//             ),
//             SizedBox(height: 10.h),

//             Expanded(
//               child: ListView(
//                 physics: const AlwaysScrollableScrollPhysics(),
//                 padding: const EdgeInsets.only(left: 16, right: 16),
//                 children: [
//                   SizedBox(height: 10.h),
//                   for (final entry in groupedCalls.entries) ...[
//                     for (final call in entry.value)
//                       CallTile(
//                         name: call.displayName,
//                         number: call.phoneNumber,
//                         time: call.formattedTime,
//                         callType: call.callType,
//                         duration: call.durationText,
//                         svgAsset: call.svgAsset,
//                         iconColor: call.callTypeColor,
//                         backgroundColor: call.callTypeBackgroundColor
//                             .withOpacity(0.2),
//                         onTap: () => _callService.makeCall(call.phoneNumber),
//                       ),
//                   ],
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _historySubscription?.cancel();
//     super.dispose();
//   }

//   Widget _buildNavigationFeature() {
//     final Map<String, Widget> pages = {
//       'Recent': const RecentCallScreen(),
//       'Favorites': const RecentCallScreen(),
//       'Team': const RecentCallScreen(),
//     };

//     List<String> periods = ['Recent', 'Favorites', 'Team'];
//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: 4.w),
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: Row(
//           children: periods.map((period) {
//             return Padding(
//               padding: EdgeInsets.only(right: 12.w),
//               child: InkWell(
//                 onTap: () {
//                   Navigator.of(context).push(
//                     PageRouteBuilder(
//                       pageBuilder: (context, animation, secondaryAnimation) =>
//                           pages[period]!,
//                       transitionsBuilder:
//                           (context, animation, secondaryAnimation, child) {
//                             const begin = Offset(1.0, 0.0);
//                             const end = Offset.zero;
//                             const curve = Curves.ease;
//                             var tween = Tween(
//                               begin: begin,
//                               end: end,
//                             ).chain(CurveTween(curve: curve));

//                             return SlideTransition(
//                               position: animation.drive(tween),
//                               child: child,
//                             );
//                           },
//                     ),
//                   );
//                 },
//                 child: Container(
//                   padding: EdgeInsets.symmetric(
//                     horizontal: 21.w,
//                     vertical: 7.h,
//                   ),
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF334155),
//                     border: Border.all(
//                       color: const Color(0xFFE5E7EB),
//                       width: 0.1,
//                     ),
//                     borderRadius: BorderRadius.circular(30),
//                   ),
//                   child: Text(
//                     period,
//                     style: GoogleFonts.roboto(
//                       color: Colors.white,
//                       fontSize: 12.sp,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),
//               ),
//             );
//           }).toList(),
//         ),
//       ),
//     );
//   }
// }
