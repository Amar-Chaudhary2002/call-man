import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

@pragma("vm:entry-point")
void overlayMain() {
  runApp(const CallOverlayApp());
}

class CallOverlayApp extends StatelessWidget {
  const CallOverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    log('📱 Building overlay app');
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const CallOverlayWidget(),
    );
  }
}

class CallOverlayWidget extends StatefulWidget {
  const CallOverlayWidget({Key? key}) : super(key: key);

  @override
  State<CallOverlayWidget> createState() => _CallOverlayWidgetState();
}

class _CallOverlayWidgetState extends State<CallOverlayWidget>
    with TickerProviderStateMixin {
  String _title = "Call Overlay";
  String _subtitle = "Initializing...";
  String _callState = "unknown";
  String _phoneNumber = "";

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  StreamSubscription? _dataSubscription;
  Timer? _autoCloseTimer;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutBack,
          ),
        );

    // Start animation
    _animationController.forward();

    // Listen for overlay data
    _listenToOverlayData();

    // Set auto-close timer for certain states
    _setAutoCloseTimer();
  }

  void _listenToOverlayData() {
    _dataSubscription = FlutterOverlayWindow.overlayListener.listen((data) {
      print("📨 Overlay received data: $data");

      if (data is Map) {
        setState(() {
          _title = data['title'] ?? _title;
          _subtitle = data['subtitle'] ?? _subtitle;
          _callState = data['callState'] ?? _callState;
          _phoneNumber = data['phoneNumber'] ?? _phoneNumber;
        });

        // Reset auto-close timer when new data arrives
        _setAutoCloseTimer();

        // Restart animation for new data
        _animationController.reset();
        _animationController.forward();
      }
    });
  }

  void _setAutoCloseTimer() {
    _autoCloseTimer?.cancel();

    // Auto close for ended calls
    if (_callState == 'ended' || _callState == 'disconnected') {
      _autoCloseTimer = Timer(const Duration(seconds: 5), () {
        _closeOverlay();
      });
    } else if (_callState == 'test') {
      _autoCloseTimer = Timer(const Duration(seconds: 3), () {
        _closeOverlay();
      });
    }
  }

  void _closeOverlay() {
    _animationController.reverse().then((_) {
      FlutterOverlayWindow.closeOverlay();
    });
  }

  Color _getStateColor() {
    switch (_callState) {
      case 'ringing':
        return Colors.blue;
      case 'active':
        return Colors.green;
      case 'ended':
      case 'disconnected':
        return Colors.red;
      case 'dialing':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStateIcon() {
    switch (_callState) {
      case 'ringing':
        return Icons.phone_in_talk;
      case 'active':
        return Icons.phone;
      case 'ended':
      case 'disconnected':
        return Icons.phone_disabled;
      case 'dialing':
        return Icons.phone_forwarded;
      default:
        return Icons.phone;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: _getStateColor(), width: 2),
                ),
                child: _buildOverlayContent(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverlayContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with icon and close button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getStateColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_getStateIcon(), color: _getStateColor(), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              IconButton(
                onPressed: _closeOverlay,
                icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Content
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                if (_phoneNumber.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 16, color: _getStateColor()),
                      const SizedBox(width: 4),
                      Text(
                        _phoneNumber,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _getStateColor(),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Action buttons (only for certain states)
          if (_callState == 'ringing') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // You can implement answer call functionality here
                      print("Answer call pressed");
                    },
                    icon: const Icon(Icons.phone, size: 18),
                    label: const Text("Answer"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // You can implement decline call functionality here
                      print("Decline call pressed");
                      _closeOverlay();
                    },
                    icon: const Icon(Icons.phone_disabled, size: 18),
                    label: const Text("Decline"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Status indicator
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStateColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _callState.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _getStateColor(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _dataSubscription?.cancel();
    _autoCloseTimer?.cancel();
    super.dispose();
  }
}
