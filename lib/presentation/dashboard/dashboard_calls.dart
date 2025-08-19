// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';

// import 'model/call_record_model.dart';
// import 'widgets/call_tracking.dart';

// class DashboardCallsView extends StatelessWidget {
//   final Map<String, List<CallRecord>> groupedCalls;
//   final CallTrackingService callService;

//   const DashboardCallsView({
//     super.key,
//     required this.groupedCalls,
//     required this.callService,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         SizedBox(height: 10.h),
//         Divider(color: const Color(0xFFE5E7EB), thickness: 0.1.w),
//         SizedBox(height: 10.h),
//         _buildHomeTabSelector(),
//         SizedBox(height: 10.h),
//         Expanded(
//           child: ListView(
//             physics: const AlwaysScrollableScrollPhysics(),
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             children: [
//               SizedBox(height: 10.h),
//               for (final entry in groupedCalls.entries)
//                 for (final call in entry.value)
//                   CallTile(

//                     svgAsset: call.svgAsset,
//                     iconColor: call.callTypeColor,
//                     backgroundColor: call.callTypeBackgroundColor.withOpacity(
//                       0.2,
//                     ),
//                     name: call.displayName,
//                     number: call.phoneNumber,
//                     time: call.formattedTime,
//                     callType: call.callType,
//                     duration: call.durationText,
//                     onTap: () => callService.makeCall(call.phoneNumber),
//                   ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildHomeTabSelector() {
//     const tabs = ['Recent', 'Favorites', 'Team'];
//     return Padding(
//       padding: const EdgeInsets.only(left: 12, right: 16),
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: Row(
//           children: tabs.map((tab) {
//             return Padding(
//               padding: EdgeInsets.only(right: 12.w),
//               child: Container(
//                 padding: EdgeInsets.symmetric(horizontal: 21.w, vertical: 7.h),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF334155),
//                   border: Border.all(
//                     color: const Color(0xFFE5E7EB),
//                     width: 0.1,
//                   ),
//                   borderRadius: BorderRadius.circular(30),
//                 ),
//                 child: Text(
//                   tab,
//                   style: TextStyle(color: Colors.white, fontSize: 12.sp),
//                 ),
//               ),
//             );
//           }).toList(),
//         ),
//       ),
//     );
//   }
// }
