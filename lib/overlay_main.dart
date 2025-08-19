import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

// Entry point for overlay
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(home: CallOverlay(), debugShowCheckedModeBanner: false),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CallMan',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const platform = MethodChannel('overlay_permission');
  static const callDetectionChannel = MethodChannel('call_detection');
  bool hasOverlayPermission = false;

  @override
  void initState() {
    super.initState();
    checkOverlayPermission();
    setupCallDetection();
  }

  Future<void> checkOverlayPermission() async {
    try {
      final bool result = await platform.invokeMethod('checkOverlayPermission');
      setState(() {
        hasOverlayPermission = result;
      });
    } catch (e) {
      print('Error checking overlay permission: $e');
    }
  }

  Future<void> requestOverlayPermission() async {
    try {
      await platform.invokeMethod('requestOverlayPermission');
      // Recheck after a delay
      Future.delayed(const Duration(seconds: 2), checkOverlayPermission);
    } catch (e) {
      print('Error requesting overlay permission: $e');
    }
  }

  Future<void> startCallService() async {
    try {
      await platform.invokeMethod('startCallService');
    } catch (e) {
      print('Error starting call service: $e');
    }
  }

  void setupCallDetection() {
    callDetectionChannel.setMethodCallHandler((call) async {
      if (call.method == 'onCallReceived') {
        final String phoneNumber = call.arguments;
        print('Incoming call from: $phoneNumber');

        // Show overlay
        if (hasOverlayPermission) {
          await FlutterOverlayWindow.showOverlay(
            enableDrag: true,
            overlayTitle: "Incoming Call",
            overlayContent: phoneNumber,
            flag: OverlayFlag.defaultFlag,
            visibility: NotificationVisibility.visibilityPublic,
            positionGravity: PositionGravity.auto,
            height: 200,
            width: 300,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CallMan')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Overlay Permission: ${hasOverlayPermission ? "Granted" : "Not Granted"}',
              style: TextStyle(
                fontSize: 18,
                color: hasOverlayPermission ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            if (!hasOverlayPermission)
              ElevatedButton(
                onPressed: requestOverlayPermission,
                child: const Text('Request Overlay Permission'),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: hasOverlayPermission ? startCallService : null,
              child: const Text('Start Call Detection Service'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: hasOverlayPermission
                  ? () async {
                      print('Testing overlay...');
                      try {
                        await FlutterOverlayWindow.showOverlay(
                          enableDrag: true,
                          overlayTitle: "Test Overlay",
                          overlayContent: "This is a test overlay",
                          flag: OverlayFlag.defaultFlag,
                          visibility: NotificationVisibility.visibilityPublic,
                          positionGravity: PositionGravity.auto,
                          height: 200,
                          width: 300,
                        );
                        print('Overlay shown successfully');
                      } catch (e) {
                        print('Error showing overlay: $e');
                      }
                    }
                  : null,
              child: const Text('Test Overlay'),
            ),
          ],
        ),
      ),
    );
  }
}

class CallOverlay extends StatelessWidget {
  const CallOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Incoming Call',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Phone Number Here',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    FlutterOverlayWindow.closeOverlay();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Decline'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Handle accept call
                    FlutterOverlayWindow.closeOverlay();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Accept'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
