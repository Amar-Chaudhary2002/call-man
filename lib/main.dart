// main.dart
import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:system_alert_window/system_alert_window.dart';

import 'background_service.dart';
import 'ioslate_managet.dart';

// === Overlay isolate entry point ===
@pragma("vm:entry-point")
void overlayMain() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Material(color: Colors.transparent, child: OverlayWidget()),
  ));
}

class OverlayWidget extends StatefulWidget {
  const OverlayWidget({Key? key}) : super(key: key);
  @override
  State<OverlayWidget> createState() => _OverlayWidgetState();
}

class _OverlayWidgetState extends State<OverlayWidget> {
  String currentTime = '';
  int overlayCount = 0;
  Timer? _tick;
  static const _BG_PORT_NAME = 'bg_port';

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => currentTime = DateTime.now().toString().substring(11, 19));
    });

    // Messages from app/service
    SystemAlertWindow.overlayListener.listen((data) {
      dev.log("Overlay received: $data");
      if (data is Map && data['type'] == 'update_count') {
        if (!mounted) return;
        setState(() => overlayCount = (data['count'] ?? 0) as int);
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
      // Inform background to stop re-spawning overlays
      final SendPort? bg = IsolateNameServer.lookupPortByName(_BG_PORT_NAME);
      bg?.send({'action': 'close_overlay'});
      await SystemAlertWindow.closeSystemWindow(prefMode: SystemWindowPrefMode.OVERLAY);
    } catch (e) {
      dev.log("Error closing overlay: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Compact, overflow-proof UI (fits MIUI tiny windows)
    return Center(
      child: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue, width: 1),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.schedule, size: 16, color: Colors.blue),
                        const SizedBox(height: 2),
                        Text(
                          currentTime,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Overlay #$overlayCount',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: _closeOverlay,
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.close, size: 16, color: Colors.red),
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
}

// === App ===
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BackgroundServiceManager.initializeService();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Background Overlay Demo',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const OverlayDemoPage(),
    );
  }
}

class OverlayDemoPage extends StatefulWidget {
  const OverlayDemoPage({super.key});
  @override
  State<OverlayDemoPage> createState() => _OverlayDemoPageState();
}

class _OverlayDemoPageState extends State<OverlayDemoPage> with WidgetsBindingObserver {
  final FlutterBackgroundService _service = FlutterBackgroundService();

  Timer? _fgTimer;
  bool _isOverlayActive = false; // foreground loop flag
  bool _isBackgroundServiceActive = false;
  int _overlayCount = 0;
  late ReceivePort _port;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupForegroundPort();
    _checkServiceStatus();
  }

  Future<void> _setupForegroundPort() async {
    final ok = await SystemAlertWindow.requestPermissions() ?? false;
    if (!ok && mounted) {
      _showPermissionDialog();
      return;
    }
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
      await SystemAlertWindow.closeSystemWindow(prefMode: SystemWindowPrefMode.OVERLAY);
    } catch (e) {
      dev.log("Error closing overlay: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fgTimer?.cancel();
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
        if (_isOverlayActive) {
          SystemAlertWindow.closeSystemWindow(prefMode: SystemWindowPrefMode.OVERLAY);
        }
        if (_isBackgroundServiceActive) _service.invoke("app_going_inactive");
        break;
      case AppLifecycleState.paused:
        if (_isOverlayActive) {
          SystemAlertWindow.closeSystemWindow(prefMode: SystemWindowPrefMode.OVERLAY);
        }
        break;
      case AppLifecycleState.resumed:
        _checkServiceStatus();
        break;
      case AppLifecycleState.hidden:
        if (_isOverlayActive) {
          SystemAlertWindow.closeSystemWindow(prefMode: SystemWindowPrefMode.OVERLAY);
        }
        break;
    }
  }

  Future<void> _checkServiceStatus() async {
    final isRunning = await _service.isRunning();
    if (!mounted) return;
    setState(() => _isBackgroundServiceActive = isRunning);
  }

  Future<bool> _checkPermissions() async =>
      (await SystemAlertWindow.checkPermissions()) ?? false;

  // ===== Foreground overlay demo (app open) =====
  void _startForegroundOverlay() async {
    if (!await _checkPermissions()) {
      _showPermissionDialog();
      return;
    }
    setState(() {
      _isOverlayActive = true;
      _overlayCount = 0;
    });

    _fgTimer?.cancel();
    _fgTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!_isOverlayActive) return;
      setState(() => _overlayCount++);
      await _showDirectOverlay(count: _overlayCount, autoClose: true);
    });
  }

  void _stopForegroundOverlay() {
    _fgTimer?.cancel();
    SystemAlertWindow.closeSystemWindow(prefMode: SystemWindowPrefMode.OVERLAY);
    setState(() => _isOverlayActive = false);
  }

  // ===== Background overlay loop (survives app termination) =====
  Future<void> _startBackgroundOverlay() async {
    if (!await _checkPermissions()) {
      _showPermissionDialog();
      return;
    }
    await BackgroundServiceManager.startService();
    _service.invoke("start_overlay");
    setState(() => _isBackgroundServiceActive = true);

    // poll status briefly
    Timer.periodic(const Duration(seconds: 2), (t) async {
      if (!mounted) return t.cancel();
      final running = await _service.isRunning();
      if (!mounted) return t.cancel();
      setState(() => _isBackgroundServiceActive = running);
      if (!running) t.cancel();
    });
  }

  Future<void> _stopBackgroundOverlay() async {
    _service.invoke("stop_overlay");
    await BackgroundServiceManager.stopService();
    setState(() => _isBackgroundServiceActive = false);
  }

  Future<void> _showDirectOverlay({required int count, bool autoClose = false}) async {
    try {
      await SystemAlertWindow.sendMessageToOverlay({'type': 'update_count', 'count': count});
      await SystemAlertWindow.showSystemWindow(
        height: 100, // compact
        width: 280,  // compact
        gravity: SystemWindowGravity.CENTER,
        prefMode: SystemWindowPrefMode.OVERLAY,
        layoutParamFlags: const [
          SystemWindowFlags.FLAG_NOT_FOCUSABLE,
          SystemWindowFlags.FLAG_NOT_TOUCH_MODAL,
        ],
      );
      if (autoClose) {
        Timer(const Duration(seconds: 3), () {
          if (_isOverlayActive) {
            SystemAlertWindow.closeSystemWindow(prefMode: SystemWindowPrefMode.OVERLAY);
          }
        });
      }
    } catch (e) {
      dev.log("Error showing overlay: $e");
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(children: const [
          Icon(Icons.warning, color: Colors.orange),
          SizedBox(width: 8),
          Flexible(child: Text('Permissions Required')),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('For background overlay to work reliably, enable:'),
            SizedBox(height: 8),
            Text('1. Display over other apps'),
            Text('2. Background activity'),
            Text('3. Disable battery optimization for this app'),
            Text('4. (MIUI) Allow pop-up windows while in background'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await SystemAlertWindow.requestPermissions();
            },
            child: const Text('Grant Permissions'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Background Overlay Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Row(children: [
            Expanded(
              child: Card(
                color: _isOverlayActive ? Colors.green.shade50 : Colors.grey.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    Icon(Icons.layers, color: _isOverlayActive ? Colors.green : Colors.grey, size: 40),
                    const SizedBox(height: 8),
                    Text('Foreground\nOverlay',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold, color: _isOverlayActive ? Colors.green : Colors.grey)),
                    Text(_isOverlayActive ? 'ACTIVE' : 'INACTIVE',
                        style: TextStyle(fontSize: 12, color: _isOverlayActive ? Colors.green : Colors.grey)),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Card(
                color: _isBackgroundServiceActive ? Colors.blue.shade50 : Colors.grey.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    Icon(Icons.cloud, color: _isBackgroundServiceActive ? Colors.blue : Colors.grey, size: 40),
                    const SizedBox(height: 8),
                    Text('Background\nService',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: _isBackgroundServiceActive ? Colors.blue : Colors.grey)),
                    Text(_isBackgroundServiceActive ? 'RUNNING' : 'STOPPED',
                        style: TextStyle(fontSize: 12, color: _isBackgroundServiceActive ? Colors.blue : Colors.grey)),
                  ]),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 30),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Text('Foreground Overlay (App Running)', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isOverlayActive ? null : _startForegroundOverlay,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isOverlayActive ? _stopForegroundOverlay : null,
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                    ),
                  ),
                ]),
                if (_isOverlayActive)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Count: $_overlayCount',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Row(children: [
                  const Icon(Icons.star, color: Colors.amber),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text('Background Service (Works When App Closed)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.blue.shade700)),
                  ),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isBackgroundServiceActive ? null : _startBackgroundOverlay,
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('Start Background'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isBackgroundServiceActive ? _stopBackgroundOverlay : null,
                      icon: const Icon(Icons.cloud_off),
                      label: const Text('Stop Background'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                    ),
                  ),
                ]),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
