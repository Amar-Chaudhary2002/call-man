// import 'package:flutter/cupertino.dart';
//
// class CallOverlayWidget extends StatefulWidget {
//   const CallOverlayWidget({super.key});
//
//   @override
//   State<CallOverlayWidget> createState() => _CallOverlayWidgetState();
// }
//
// class _CallOverlayWidgetState extends State<CallOverlayWidget>
//     with SingleTickerProviderStateMixin {
//   String _type = 'unknown';
//   String _title = 'Call';
//   String _subtitle = '';
//   String _phoneNumber = '';
//   String _backgroundColor = '#6b7280';
//
//   late AnimationController _animationController;
//   late Animation<double> _slideAnimation;
//   late Animation<double> _fadeAnimation;
//
//   @override
//   void initState() {
//     super.initState();
//
//     _animationController = AnimationController(
//       duration: const Duration(milliseconds: 400),
//       vsync: this,
//     );
//
//     _slideAnimation = Tween<double>(
//       begin: -100.0,
//       end: 0.0,
//     ).animate(CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeOutBack,
//     ));
//
//     _fadeAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeOut,
//     ));
//
//     _animationController.forward();
//
//     // Listen for data updates
//     FlutterOverlayWindow.overlayListener.listen((data) {
//       debugPrint('📡 Overlay received: $data');
//       if (data is Map) {
//         setState(() {
//           _type = data['type']?.toString() ?? _type;
//           _title = data['title']?.toString() ?? _title;
//           _subtitle = data['subtitle']?.toString() ?? _subtitle;
//           _phoneNumber = data['phoneNumber']?.toString() ?? _phoneNumber;
//           _backgroundColor = data['backgroundColor']?.toString() ?? _backgroundColor;
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
//   IconData _getIcon() {
//     switch (_type) {
//       case 'incoming_call':
//         return Icons.call_received;
//       case 'active_call':
//         return Icons.call;
//       case 'call_ended':
//         return Icons.call_end;
//       default:
//         return Icons.phone;
//     }
//   }
//
//   Color _getBackgroundColor() {
//     try {
//       return Color(int.parse(_backgroundColor.replaceFirst('#', '0xff')));
//     } catch (e) {
//       return Colors.grey[800]!;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.transparent,
//       body: AnimatedBuilder(
//         animation: _animationController,
//         builder: (context, child) {
//           return Transform.translate(
//             offset: Offset(0, _slideAnimation.value),
//             child: Opacity(
//               opacity: _fadeAnimation.value,
//               child: Container(
//                 margin: const EdgeInsets.all(16),
//                 child: Material(
//                   elevation: 16,
//                   borderRadius: BorderRadius.circular(20),
//                   color: Colors.transparent,
//                   child: Container(
//                     padding: const EdgeInsets.all(20),
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         colors: [
//                           _getBackgroundColor().withOpacity(0.95),
//                           _getBackgroundColor().withOpacity(0.8),
//                         ],
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                       ),
//                       borderRadius: BorderRadius.circular(20),
//                       border: Border.all(
//                         color: Colors.white.withOpacity(0.2),
//                         width: 1,
//                       ),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.3),
//                           blurRadius: 20,
//                           spreadRadius: 5,
//                           offset: const Offset(0, 10),
//                         ),
//                       ],
//                     ),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         // Icon with pulse animation
//                         Container(
//                           width: 60,
//                           height: 60,
//                           decoration: BoxDecoration(
//                             color: Colors.white.withOpacity(0.2),
//                             shape: BoxShape.circle,
//                           ),
//                           child: Icon(
//                             _getIcon(),
//                             color: Colors.white,
//                             size: 30,
//                           ),
//                         ),
//                         const SizedBox(height: 16),
//
//                         // Title
//                         Text(
//                           _title,
//                           style: const TextStyle(
//                             fontSize: 22,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                         const SizedBox(height: 8),
//
//                         // Subtitle
//                         if (_subtitle.isNotEmpty)
//                           Text(
//                             _subtitle,
//                             style: const TextStyle(
//                               fontSize: 16,
//                               color: Colors.white70,
//                               height: 1.3,
//                             ),
//                             textAlign: TextAlign.center,
//                           ),
//                         const SizedBox(height: 20),
//
//                         // Action buttons
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                           children: [
//                             if (_type == 'call_ended')
//                               _buildActionButton(
//                                 icon: Icons.note_add,
//                                 label: 'Add Note',
//                                 onPressed: () {
//                                   debugPrint('📝 Add note for $_phoneNumber');
//                                   // TODO: Open note-taking interface
//                                   _closeOverlay();
//                                 },
//                                 isPrimary: false,
//                               ),
//                             _buildActionButton(
//                               icon: Icons.close,
//                               label: 'Dismiss',
//                               onPressed: _closeOverlay,
//                               isPrimary: false,
//                             ),
//                             _buildActionButton(
//                               icon: Icons.open_in_new,
//                               label: 'Open App',
//                               onPressed: () {
//                                 debugPrint('📱 Opening main app');
//                                 // TODO: Implement deep link to main app
//                                 _closeOverlay();
//                               },
//                               isPrimary: true,
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildActionButton({
//     required IconData icon,
//     required String label,
//     required VoidCallback onPressed,
//     required bool isPrimary,
//   }) {
//     return ElevatedButton.icon(
//       onPressed: onPressed,
//       icon: Icon(icon, size: 18),
//       label: Text(label),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: isPrimary
//             ? Colors.white.withOpacity(0.2)
//             : Colors.white.withOpacity(0.1),
//         foregroundColor: Colors.white,
//         elevation: 0,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(25),
//           side: BorderSide(
//             color: Colors.white.withOpacity(0.3),
//             width: 1,
//           ),
//         ),
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       ),
//     );
//   }
//
//   Future<void> _closeOverlay() async {
//     try {
//       await _animationController.reverse();
//       await FlutterOverlayWindow.closeOverlay();
//     } catch (e) {
//       debugPrint('Error closing overlay: $e');
//     }
//   }
// }
//
