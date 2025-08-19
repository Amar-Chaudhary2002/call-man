// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';

// import 'model/call_record_model.dart';
// import 'widgets/call_list.dart';
// import 'widgets/call_tracking.dart';
// import 'widgets/filter_chip_card.dart';
// import 'widgets/section_tile.dart';

// class DashboardRecentCallsView extends StatelessWidget {
//   final bool isLoading;
//   final bool permissionsGranted;
//   final List<CallRecord> filteredCalls;
//   final Map<String, List<CallRecord>> groupedCalls;
//   final Future<void> Function() onRefresh;
//   final CallTrackingService callService;
//   final String selectedFilter;
//   final Function(String) onFilterChanged;

//   const DashboardRecentCallsView({
//     super.key,
//     required this.isLoading,
//     required this.permissionsGranted,
//     required this.filteredCalls,
//     required this.groupedCalls,
//     required this.onRefresh,
//     required this.callService,
//     required this.selectedFilter,
//     required this.onFilterChanged,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Divider(color: const Color(0xFFE5E7EB), thickness: 0.1.w),
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 9),
//           child: Row(
//             children: [
//               Expanded(
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceAround,
//                   children: [
//                     FilterChipWidget(
//                       label: 'All',
//                       selected: selectedFilter == 'All',
//                       onTap: () => onFilterChanged('All'),
//                     ),
//                     FilterChipWidget(
//                       label: 'Missed',
//                       selected: selectedFilter == 'Missed',
//                       onTap: () => onFilterChanged('Missed'),
//                     ),
//                     FilterChipWidget(
//                       label: 'Outgoing',
//                       selected: selectedFilter == 'Outgoing',
//                       onTap: () => onFilterChanged('Outgoing'),
//                     ),
//                     FilterChipWidget(
//                       label: 'Incoming',
//                       selected: selectedFilter == 'Incoming',
//                       onTap: () => onFilterChanged('Incoming'),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//         Divider(color: const Color(0xFFE5E7EB), thickness: 0.1.w),
//         Expanded(
//           child: RefreshIndicator(
//             onRefresh: onRefresh,
//             color: Colors.white,
//             backgroundColor: Colors.blue,
//             child: _buildContent(),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildContent() {
//     if (isLoading) {
//       return const Center(
//         child: CircularProgressIndicator(color: Colors.white),
//       );
//     }
//     if (!permissionsGranted) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.phone_disabled, size: 64, color: Colors.white54),
//             const SizedBox(height: 16),
//             const Text(
//               'Phone permission required',
//               style: TextStyle(color: Colors.white70, fontSize: 18),
//             ),
//             const SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: () {},
//               style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
//               child: const Text(
//                 'Grant Permission',
//                 style: TextStyle(color: Colors.blue),
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//     if (filteredCalls.isEmpty) {
//       return ListView(
//         children: const [
//           SizedBox(height: 100),
//           Center(
//             child: Column(
//               children: [
//                 Icon(Icons.call, size: 64, color: Colors.white54),
//                 SizedBox(height: 16),
//                 Text('No calls found', style: TextStyle(color: Colors.white70)),
//               ],
//             ),
//           ),
//         ],
//       );
//     }
//     return ListView(
//       physics: const AlwaysScrollableScrollPhysics(),
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       children: [
//         for (final entry in groupedCalls.entries) ...[
//           SectionTitle(title: entry.key),
//           for (final call in entry.value)
//             CallTile(
//               svgAsset: call.svgAsset,
//               iconColor: call.callTypeColor,
//               backgroundColor: call.callTypeBackgroundColor.withOpacity(0.2),
//               name: call.displayName,
//               number: call.phoneNumber,
//               time: call.formattedTime,
//               callType: call.callType,
//               duration: call.durationText,
//               onTap: () => callService.makeCall(call.phoneNumber),
//             ),
//         ],
//       ],
//     );
//   }
// }
