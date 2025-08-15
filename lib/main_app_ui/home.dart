// Add this to your Home screen for debugging
import 'package:call_app/database/database_service.dart';
import 'package:call_app/main_app_ui/utils/fonts.dart';
import 'package:call_app/main_app_ui/widgets/loading_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class Home extends StatefulWidget {
  DatabaseService dbService;
  Home(this.dbService);

  @override
  State<Home> createState() => _Home();
}

class _Home extends State<Home> {
  final service = FlutterBackgroundService();
  Set<int> status = {0};
  bool isServiceRunning = false;

  @override
  void initState() {
    super.initState();
    _checkServiceStatus();
  }

  void _checkServiceStatus() async {
    bool running = await service.isRunning();
    setState(() {
      isServiceRunning = running;
    });
  }

  // Test function to check if overlay works at all
  Future<void> _testOverlay() async {
    try {
      print("Testing overlay manually...");

      bool hasPermission = await FlutterOverlayWindow.isPermissionGranted();
      print("Has overlay permission: $hasPermission");

      if (!hasPermission) {
        print("Requesting overlay permission...");
        await FlutterOverlayWindow.requestPermission();
        hasPermission = await FlutterOverlayWindow.isPermissionGranted();
        print("Permission after request: $hasPermission");
      }

      if (hasPermission) {
        print("Showing test overlay...");
        await FlutterOverlayWindow.showOverlay(
          height: WindowSize.fullCover,
          width: WindowSize.fullCover,
          overlayTitle: "Test Overlay",
          overlayContent: "Manual test",
          enableDrag: true,
          positionGravity: PositionGravity.auto,
        );
        print("Test overlay command sent");

        // Auto close after 5 seconds
        Future.delayed(Duration(seconds: 5), () {
          FlutterOverlayWindow.closeOverlay();
          print("Test overlay closed");
        });
      } else {
        print("Still no overlay permission");
      }
    } catch (e) {
      print("Error testing overlay: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text("5-Second Overlay Service", style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Service status
            Card(
              elevation: 5,
              child: Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      isServiceRunning ? Icons.check_circle : Icons.cancel,
                      color: isServiceRunning ? Colors.green : Colors.red,
                      size: 50,
                    ),
                    SizedBox(height: 10),
                    Text(
                      isServiceRunning ? "Service Running" : "Service Stopped",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 30),

            // Test overlay button
            ElevatedButton(
              onPressed: _testOverlay,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: Text(
                "TEST OVERLAY MANUALLY",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),

            SizedBox(height: 20),

            // Start/Stop service button
            ElevatedButton(
              onPressed: () async {
                if (isServiceRunning) {
                  await _stopService();
                } else {
                  await _startService();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isServiceRunning ? Colors.red : Colors.green,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: Text(
                isServiceRunning ? "STOP SERVICE" : "START SERVICE",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),

            SizedBox(height: 20),

            // Permission check button
            ElevatedButton(
              onPressed: () async {
                bool hasPermission = await FlutterOverlayWindow.isPermissionGranted();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        hasPermission
                            ? "✅ Overlay permission granted"
                            : "❌ Overlay permission NOT granted"
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: Text(
                "CHECK PERMISSION",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startService() async {
    bool started = await service.startService();
    _checkServiceStatus();
  }

  Future<void> _stopService() async {
    service.invoke("stop");
    await Future.delayed(Duration(seconds: 2));
    _checkServiceStatus();
  }
}