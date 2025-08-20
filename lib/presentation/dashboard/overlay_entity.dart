//
// // lib/presentation/dashboard/overlay_entity.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_overlay_window/flutter_overlay_window.dart';
//
// @pragma('vm:entry-point')
// void overlayMain() {
//   runApp(const _OverlayApp());
// }
//
// class _OverlayApp extends StatelessWidget {
//   const _OverlayApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: const _OverlayPage(),
//     );
//   }
// }
//
// class _OverlayPage extends StatefulWidget {
//   const _OverlayPage({super.key});
//
//   @override
//   State<_OverlayPage> createState() => _OverlayPageState();
// }
//
// class _OverlayPageState extends State<_OverlayPage> with SingleTickerProviderStateMixin {
//   String title = 'Call';
//   String subtitle = '';
//   String callState = 'unknown';
//   late AnimationController _animationController;
//   late Animation<double> _scaleAnimation;
//
//   @override
//   void initState() {
//     super.initState();
//
//     // Initialize animation
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 300),
//       vsync: this,
//     );
//     _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
//       CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
//     );
//     _animationController.forward();
//
//     // Listen for data from main app
//     FlutterOverlayWindow.overlayListener.listen((data) {
//       debugPrint('📡 Overlay received data: $data');
//
//       if (data is Map) {
//         setState(() {
//           title = data['title']?.toString() ?? title;
//           subtitle = data['subtitle']?.toString() ?? subtitle;
//           callState = data['callState']?.toString() ?? callState;
//         });
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }
//
//   Color _getStateColor() {
//     switch (callState.toLowerCase()) {
//       case 'ringing':
//         return Colors.blue;
//       case 'active':
//         return Colors.green;
//       case 'dialing':
//         return Colors.orange;
//       case 'disconnected':
//         return Colors.red;
//       default:
//         return Colors.grey;
//     }
//   }
//
//   IconData _getStateIcon() {
//     switch (callState.toLowerCase()) {
//       case 'ringing':
//         return Icons.phone_in_talk;
//       case 'active':
//         return Icons.phone;
//       case 'dialing':
//         return Icons.phone_callback;
//       case 'disconnected':
//         return Icons.phone_disabled;
//       default:
//         return Icons.phone;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black26,
//       body: Center(
//         child: AnimatedBuilder(
//           animation: _scaleAnimation,
//           builder: (context, child) {
//             return Transform.scale(
//               scale: _scaleAnimation.value,
//               child: Container(
//                 margin: const EdgeInsets.symmetric(horizontal: 16),
//                 padding: const EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF1F2937),
//                   borderRadius: BorderRadius.circular(20),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.3),
//                       blurRadius: 20,
//                       spreadRadius: 5,
//                     ),
//                   ],
//                   border: Border.all(
//                     color: _getStateColor(),
//                     width: 2,
//                   ),
//                 ),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     // Status indicator with icon
//                     Container(
//                       width: 60,
//                       height: 60,
//                       decoration: BoxDecoration(
//                         color: _getStateColor(),
//                         shape: BoxShape.circle,
//                       ),
//                       child: Icon(
//                         _getStateIcon(),
//                         color: Colors.white,
//                         size: 30,
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//
//                     // Title
//                     Text(
//                       title,
//                       style: const TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//
//                     // Subtitle
//                     Text(
//                       subtitle,
//                       textAlign: TextAlign.center,
//                       style: const TextStyle(
//                         fontSize: 14,
//                         color: Colors.white70,
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//
//                     // Action buttons
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                       children: [
//                         TextButton.icon(
//                           onPressed: () async {
//                             debugPrint('🚫 Overlay dismissed');
//                             await FlutterOverlayWindow.closeOverlay();
//                           },
//                           icon: const Icon(Icons.close, color: Colors.white70),
//                           label: const Text(
//                             'Dismiss',
//                             style: TextStyle(color: Colors.white70),
//                           ),
//                         ),
//                         ElevatedButton.icon(
//                           onPressed: () async {
//                             debugPrint('📱 Opening main app');
//                             // TODO: Implement deep link to main app
//                             await FlutterOverlayWindow.closeOverlay();
//                           },
//                           icon: const Icon(Icons.open_in_new),
//                           label: const Text('Open App'),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: _getStateColor(),
//                             foregroundColor: Colors.white,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }