// import 'package:flutter/material.dart';
// import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
// import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
// import 'package:overlay_support/overlay_support.dart';
//
// class CallOverlayManager {
//   static void showIncomingCallOverlay(CallKitParams params) {
//     final name = params.nameCaller ?? 'Unknown';
//     final number = params.handle ?? 'Unknown number';
//     final callId = params.id ?? 'default_id'; // Provide a default ID if null
//
//     showOverlayNotification((context) {
//       return Card(
//         margin: const EdgeInsets.symmetric(horizontal: 4),
//         child: SafeArea(
//           child: ListTile(
//             leading: const Icon(Icons.call_received, color: Colors.green),
//             title: Text('Incoming call: $name'),
//             subtitle: Text(number),
//             trailing: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.call_end, color: Colors.red),
//                   onPressed: () {
//                     FlutterCallkitIncoming.endCall(callId);
//                     OverlaySupportEntry.of(context)?.dismiss();
//                   },
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.call, color: Colors.green),
//                   onPressed: () {
//                     FlutterCallkitIncoming.endCall(callId);
//                     OverlaySupportEntry.of(context)?.dismiss();
//                     // Handle call acceptance here
//                   },
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     }, duration: Duration.zero);
//   }
//
//   static void showCallEndedOverlay(String number, int duration) {
//     showOverlayNotification((context) {
//       return Card(
//         margin: const EdgeInsets.symmetric(horizontal: 4),
//         child: SafeArea(
//           child: ListTile(
//             leading: const Icon(Icons.call_end, color: Colors.red),
//             title: Text('Call ended: $number'),
//             subtitle: Text('Duration: $duration seconds'),
//             trailing: IconButton(
//               icon: const Icon(Icons.close),
//               onPressed: () {
//                 OverlaySupportEntry.of(context)?.dismiss();
//               },
//             ),
//           ),
//         ),
//       );
//     });
//   }
// }