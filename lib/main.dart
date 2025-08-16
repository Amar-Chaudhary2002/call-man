// main.dart - Fixed version
import 'package:flutter/material.dart';
import 'package:system_alert_window/system_alert_window.dart';
import 'dart:async';
import 'dart:isolate';
import 'dart:developer' as dev;
import 'package:flutter_background_service/flutter_background_service.dart';
import 'background_service.dart';
import 'ioslate_managet.dart';

// Overlay entry point - this runs in a separate isolate
@pragma("vm:entry-point")
void overlayMain() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Material(
      child: OverlayWidget(),
    ),
  ));
}

class OverlayWidget extends StatefulWidget {
  const OverlayWidget({Key? key}) : super(key: key);

  @override
  _OverlayWidgetState createState() => _OverlayWidgetState();
}

class _OverlayWidgetState extends State<OverlayWidget> {
  String currentTime = '';
  int overlayCount = 0;
  Timer? timeTimer;

  @override
  void initState() {
    super.initState();
    _updateTime();

    // Listen for messages from main app or background service
    SystemAlertWindow.overlayListener.listen((data) {
      dev.log("Overlay received: $data");
      if (data is Map && data['type'] == 'update_count') {
        if (mounted) {
          setState(() {
            overlayCount = data['count'] ?? 0;
          });
        }
      }
    });

    // Update time every second
    timeTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateTime();
      } else {
        timer.cancel();
      }
    });
  }

  void _updateTime() {
    if (mounted) {
      setState(() {
        currentTime = DateTime.now().toString().substring(11, 19);
      });
    }
  }

  void _callBackFunction(String tag) async {
    dev.log("Overlay button pressed: $tag");

    try {
      // Close overlay immediately
      await SystemAlertWindow.closeSystemWindow();

      // Send message to background service to handle cleanup
      SendPort? port = IsolateManager.lookupPortByName();
      if (port != null) {
        port.send({'action': tag, 'timestamp': DateTime.now().millisecondsSinceEpoch});
      }
    } catch (e) {
      dev.log("Error closing overlay: $e");
    }
  }

  @override
  void dispose() {
    timeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 300,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 15,
              offset: Offset(0, 6),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.blue.shade800],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Background Overlay #$overlayCount',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      dev.log("Close button tapped!");
                      _callBackFunction("close_overlay");
                    },
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.schedule,
                      color: Colors.blue.shade600,
                      size: 28,
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Background Service',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      currentTime,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Works even when app is closed!',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.green.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            // Footer with close button
            InkWell(
              onTap: () {
                dev.log("Close button in footer tapped!");
                _callBackFunction("close_overlay");
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
                child: Text(
                  'Close Overlay',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize background service
  await BackgroundServiceManager.initializeService();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Background Overlay Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: OverlayDemoPage(),
    );
  }
}

class OverlayDemoPage extends StatefulWidget {
  @override
  _OverlayDemoPageState createState() => _OverlayDemoPageState();
}

class _OverlayDemoPageState extends State<OverlayDemoPage> with WidgetsBindingObserver {
  Timer? _timer;
  bool _isOverlayActive = false;
  bool _isBackgroundServiceActive = false;
  int _overlayCount = 0;
  late ReceivePort _port;
  final FlutterBackgroundService _service = FlutterBackgroundService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeOverlay();
    _checkServiceStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    SystemAlertWindow.closeSystemWindow();
    IsolateManager.removePortNameMapping(IsolateManager.FOREGROUND_PORT_NAME);
    _port.close();

    // Clean up when app is terminated
    if (_isBackgroundServiceActive) {
      _service.invoke("cleanup_on_app_exit");
    }

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    dev.log("App lifecycle state: $state");

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
      // App is being terminated or going inactive
        SystemAlertWindow.closeSystemWindow();
        if (_isBackgroundServiceActive) {
          _service.invoke("app_going_inactive");
        }
        break;
      case AppLifecycleState.paused:
      // App is going to background
        if (_isOverlayActive) {
          SystemAlertWindow.closeSystemWindow();
        }
        break;
      case AppLifecycleState.resumed:
      // App is coming back to foreground
        _checkServiceStatus();
        break;
      case AppLifecycleState.hidden:
      // App is hidden
        SystemAlertWindow.closeSystemWindow();
        break;
    }
  }

  Future<void> _checkServiceStatus() async {
    bool isRunning = await _service.isRunning();
    if (mounted) {
      setState(() {
        _isBackgroundServiceActive = isRunning;
      });
    }
  }

  Future<void> _initializeOverlay() async {
    // Request permissions
    bool? hasPermission = await SystemAlertWindow.requestPermissions();
    if (hasPermission != true) {
      _showPermissionDialog();
      return;
    }

    // Set up isolate communication
    _port = ReceivePort();
    IsolateManager.registerPortWithName(_port.sendPort);

    _port.listen((message) {
      dev.log("Message from overlay: $message");
      if (message is Map) {
        if (message['action'] == "close_overlay") {
          _closeOverlay();
        }
      } else if (message == "close_overlay") {
        _closeOverlay();
      }
    });
  }

  Future<bool> _checkPermissions() async {
    bool? result = await SystemAlertWindow.checkPermissions();
    return result ?? false;
  }

  // Foreground overlay (when app is running)
  void _startForegroundOverlay() async {
    bool hasPermission = await _checkPermissions();

    if (!hasPermission) {
      _showPermissionDialog();
      return;
    }

    setState(() {
      _isOverlayActive = true;
      _overlayCount = 0;
    });

    _timer = Timer.periodic(Duration(seconds: 5), (timer) async {
      if (!_isOverlayActive) {
        timer.cancel();
        return;
      }

      setState(() {
        _overlayCount++;
      });

      await _showDirectOverlay();
    });
  }

  // Background overlay (works when app is closed)
  void _startBackgroundOverlay() async {
    bool hasPermission = await _checkPermissions();

    if (!hasPermission) {
      _showPermissionDialog();
      return;
    }

    await BackgroundServiceManager.startService();
    _service.invoke("start_overlay");

    setState(() {
      _isBackgroundServiceActive = true;
    });

    // Check service status periodically
    Timer.periodic(Duration(seconds: 2), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      bool isRunning = await _service.isRunning();
      if (mounted) {
        setState(() {
          _isBackgroundServiceActive = isRunning;
        });
      }
      if (!isRunning) {
        timer.cancel();
      }
    });
  }

  void _stopForegroundOverlay() {
    _timer?.cancel();
    SystemAlertWindow.closeSystemWindow();
    setState(() {
      _isOverlayActive = false;
    });
  }

  void _stopBackgroundOverlay() async {
    _service.invoke("stop_overlay");
    await BackgroundServiceManager.stopService();
    setState(() {
      _isBackgroundServiceActive = false;
    });
  }

  Future<void> _closeOverlay() async {
    try {
      await SystemAlertWindow.closeSystemWindow();
    } catch (e) {
      dev.log("Error closing overlay: $e");
    }
  }

  Future<void> _showDirectOverlay() async {
    try {
      await SystemAlertWindow.sendMessageToOverlay({
        'type': 'update_count',
        'count': _overlayCount,
      });

      await SystemAlertWindow.showSystemWindow(
        height: 180,
        width: 300,
        gravity: SystemWindowGravity.CENTER,
        prefMode: SystemWindowPrefMode.OVERLAY,
        layoutParamFlags: [
          SystemWindowFlags.FLAG_NOT_FOCUSABLE,
          SystemWindowFlags.FLAG_NOT_TOUCH_MODAL,
          // Removed FLAG_NOT_TOUCHABLE to allow touch interactions
        ],
      );

      Timer(Duration(seconds: 3), () {
        if (_isOverlayActive) {
          SystemAlertWindow.closeSystemWindow();
        }
      });
    } catch (e) {
      dev.log("Error showing overlay: $e");
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Flexible(
                child: Text('Permissions Required'),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('For background overlay service, you need:'),
              SizedBox(height: 8),
              Text('1. "Display over other apps" permission'),
              Text('2. "Background activity" permission'),
              Text('3. Disable battery optimization for this app'),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Background service will keep overlay running even when app is closed!',
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await SystemAlertWindow.requestPermissions();
              },
              child: Text('Grant Permissions'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Background Overlay Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Status Cards
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: _isOverlayActive ? Colors.green.shade50 : Colors.grey.shade50,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(
                            Icons.layers,
                            color: _isOverlayActive ? Colors.green : Colors.grey,
                            size: 40,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Foreground\nOverlay',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _isOverlayActive ? Colors.green : Colors.grey,
                            ),
                          ),
                          Text(
                            _isOverlayActive ? 'ACTIVE' : 'INACTIVE',
                            style: TextStyle(
                              fontSize: 12,
                              color: _isOverlayActive ? Colors.green : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Card(
                    color: _isBackgroundServiceActive ? Colors.blue.shade50 : Colors.grey.shade50,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(
                            Icons.cloud,
                            color: _isBackgroundServiceActive ? Colors.blue : Colors.grey,
                            size: 40,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Background\nService',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _isBackgroundServiceActive ? Colors.blue : Colors.grey,
                            ),
                          ),
                          Text(
                            _isBackgroundServiceActive ? 'RUNNING' : 'STOPPED',
                            style: TextStyle(
                              fontSize: 12,
                              color: _isBackgroundServiceActive ? Colors.blue : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 30),

            // Foreground Overlay Controls
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Foreground Overlay (App Running)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isOverlayActive ? null : _startForegroundOverlay,
                            icon: Icon(Icons.play_arrow),
                            label: Text('Start'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isOverlayActive ? _stopForegroundOverlay : null,
                            icon: Icon(Icons.stop),
                            label: Text('Stop'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_isOverlayActive)
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Count: $_overlayCount',
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Background Service Controls
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Background Service (Works When App Closed)',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isBackgroundServiceActive ? null : _startBackgroundOverlay,
                            icon: Icon(Icons.cloud_upload),
                            label: Text('Start Background'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isBackgroundServiceActive ? _stopBackgroundOverlay : null,
                            icon: Icon(Icons.cloud_off),
                            label: Text('Stop Background'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 30),

            // Information Cards
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700),
                        SizedBox(width: 8),
                        Text(
                          'Fixed Features',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '✅ Fixed isolatedMode parameter\n'
                          '✅ Removed deprecated registerOnClickListener\n'
                          '✅ Close button now works properly\n'
                          '✅ App lifecycle handling for overlay cleanup\n'
                          '✅ Better touch response with InkWell\n'
                          '✅ Proper app termination handling\n'
                          '✅ Background service cleanup on app exit',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.battery_saver, color: Colors.amber.shade800),
                        SizedBox(width: 8),
                        Text(
                          'Battery Optimization',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'For background service to work reliably:\n'
                          '• Disable battery optimization for this app\n'
                          '• Allow background activity\n'
                          '• Enable "Display over other apps"',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}