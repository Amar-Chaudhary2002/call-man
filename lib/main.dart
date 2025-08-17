// main.dart
import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:system_alert_window/system_alert_window.dart';
import 'package:phone_state/phone_state.dart';

import 'background_service.dart';
import 'ioslate_managet.dart';

// === Overlay isolate entry point ===
@pragma("vm:entry-point")
void overlayMain(_) {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(color: Colors.transparent, child: OverlayWidget()),
    ),
  );
}

class OverlayWidget extends StatefulWidget {
  const OverlayWidget({Key? key}) : super(key: key);

  @override
  State<OverlayWidget> createState() => _OverlayWidgetState();
}

class _OverlayWidgetState extends State<OverlayWidget> {
  String currentTime = '';
  int callEventCount = 0;
  String callEventType = '';
  String? callerNumber;
  String? callerName;
  Timer? _tick;

  static const _BG_PORT_NAME = 'bg_port';
  static bool _overlayVisible = false; // prevent duplicates

  @override
  void initState() {
    super.initState();

    // Update clock
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => currentTime = DateTime.now().toString().substring(11, 19));
    });

    // Listen for messages from background
    SystemAlertWindow.overlayListener.listen((data) {
      dev.log("Overlay received: $data");

      if (data is Map && data['type'] == 'call_event') {
        if (!mounted) return;

        // show only on incoming/outgoing
        final eventType = (data['event_type'] ?? '').toString().toLowerCase();
        if (eventType == 'incoming' || eventType == 'outgoing') {
          if (_overlayVisible) {
            dev.log("⚠️ Overlay already visible, skipping duplicate");
            return;
          }

          setState(() {
            callEventCount = (data['count'] ?? 0) as int;
            callEventType = eventType;
            callerNumber = data['number'] as String?;
            callerName = data['contact_name'] as String?;
          });

          _overlayVisible = true;
          dev.log("🔥 Showing overlay: $eventType (#$callEventCount)");

          // Auto close after 5s
          Future.delayed(const Duration(seconds: 5), _closeOverlay);
        }
      }
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _closeOverlay() async {
    try {
      _overlayVisible = false;
      final SendPort? bg = IsolateNameServer.lookupPortByName(_BG_PORT_NAME);
      bg?.send({'action': 'close_overlay'});

      await SystemAlertWindow.closeSystemWindow(
        prefMode: SystemWindowPrefMode.OVERLAY,
      );
      dev.log("🔒 Overlay hidden");
    } catch (e) {
      dev.log("Error closing overlay: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _getEventColor(), width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Call icon
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _getEventColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getEventIcon(),
                      size: 20,
                      color: _getEventColor(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Call info
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          callerName ?? callerNumber ?? "Unknown Caller",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Call $callEventType • #$callEventCount • $currentTime',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _closeOverlay,
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.close, size: 18, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getEventColor() {
    switch (callEventType.toLowerCase()) {
      case 'incoming':
        return Colors.blue;
      case 'answered':
      case 'started':
        return Colors.green;
      case 'outgoing':
        return Colors.orange;
      case 'ended':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getEventIcon() {
    switch (callEventType.toLowerCase()) {
      case 'incoming':
        return Icons.call_received;
      case 'answered':
      case 'started':
        return Icons.call;
      case 'outgoing':
        return Icons.call_made;
      case 'ended':
        return Icons.call_end;
      default:
        return Icons.phone;
    }
  }
}

// === App main ===
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request overlay permission once
  await SystemAlertWindow.requestPermissions();

  await BackgroundServiceManager.initializeService();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Call Overlay Demo',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const CallOverlayPage(),
    );
  }
}

class CallOverlayPage extends StatefulWidget {
  const CallOverlayPage({super.key});

  @override
  State<CallOverlayPage> createState() => _CallOverlayPageState();
}

class _CallOverlayPageState extends State<CallOverlayPage>
    with WidgetsBindingObserver {
  final FlutterBackgroundService _service = FlutterBackgroundService();

  bool _isCallMonitoringActive = false;
  bool _isBackgroundServiceActive = false;
  bool _isAppInForeground = true;
  late ReceivePort _port;
  PhoneState? _currentPhoneState;
  StreamSubscription<PhoneState>? _phoneStateSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupForegroundPort();
    _checkServiceStatus();
  }

  Future<void> _setupForegroundPort() async {
    _port = ReceivePort();
    IsolateManager.registerPortWithName(_port.sendPort);
    _port.listen((msg) {
      dev.log("Message from overlay (via foreground port): $msg");
      if (msg is Map && msg['action'] == 'close_overlay') {
        _closeOnce();
      }
    });
  }

  Future<void> _closeOnce() async {
    try {
      await SystemAlertWindow.closeSystemWindow(
        prefMode: SystemWindowPrefMode.OVERLAY,
      );
    } catch (e) {
      dev.log("Error closing overlay: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _phoneStateSubscription?.cancel();
    SystemAlertWindow.closeSystemWindow(prefMode: SystemWindowPrefMode.OVERLAY);
    IsolateManager.removePortNameMapping(IsolateManager.FOREGROUND_PORT_NAME);
    _port.close();

    if (_isBackgroundServiceActive) {
      _service.invoke("cleanup_on_app_exit");
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    dev.log("App lifecycle state: $state");
    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        setState(() => _isAppInForeground = false);
        if (_isBackgroundServiceActive) {
          _service.invoke("app_going_inactive");
        }
        break;
      case AppLifecycleState.resumed:
        setState(() => _isAppInForeground = true);
        if (_isBackgroundServiceActive) {
          _service.invoke("app_going_active");
        }
        _checkServiceStatus();
        break;
    }
  }

  Future<void> _checkServiceStatus() async {
    final isRunning = await _service.isRunning();
    if (!mounted) return;
    setState(() => _isBackgroundServiceActive = isRunning);
  }

  // ===== Call monitoring controls =====
  Future<void> _startCallMonitoring() async {
    try {
      await BackgroundServiceManager.startService();
      _service.invoke("enable_call_monitoring");
      setState(() {
        _isBackgroundServiceActive = true;
        _isCallMonitoringActive = true;
      });

      _phoneStateSubscription = PhoneState.stream.listen((PhoneState state) {
        if (!mounted) return;
        setState(() => _currentPhoneState = state);
        dev.log("📱 Foreground phone state: ${state.status}");
      });
    } catch (e) {
      dev.log("Error starting call monitoring: $e");
    }
  }

  Future<void> _stopCallMonitoring() async {
    _phoneStateSubscription?.cancel();
    _service.invoke("disable_call_monitoring");
    await BackgroundServiceManager.stopService();
    setState(() {
      _isBackgroundServiceActive = false;
      _isCallMonitoringActive = false;
    });
  }

  // === Test overlay (now spawns OverlayWidget isolate) ===
  Future<void> _testOverlay() async {
    try {
      dev.log("🧪 Spawning overlay isolate...");
      Isolate.spawn(overlayMain, null);
    } catch (e) {
      dev.log("🧪 Error starting overlay isolate: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Overlay Monitor'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Monitoring buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isCallMonitoringActive
                        ? null
                        : _startCallMonitoring,
                    icon: const Icon(Icons.play_circle),
                    label: const Text('Start Monitoring'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isCallMonitoringActive
                        ? _stopCallMonitoring
                        : null,
                    icon: const Icon(Icons.stop_circle),
                    label: const Text('Stop Monitoring'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _testOverlay,
              icon: const Icon(Icons.bug_report),
              label: const Text('Test Overlay'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            ),
          ],
        ),
      ),
    );
  }
}
