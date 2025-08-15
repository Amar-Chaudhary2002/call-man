// Replace your current overlay_widget.dart with this minimal version
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class OverlayWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print("=== OVERLAY WIDGET BUILD CALLED ===");

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.red.withOpacity(0.8), // Bright red background
        child: Center(
          child: Container(
            width: 250,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.yellow,
              border: Border.all(color: Colors.black, width: 5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "OVERLAY WORKING!",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  DateTime.now().toString().substring(11, 19),
                  style: TextStyle(fontSize: 14, color: Colors.black),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    print("Close button pressed");
                    FlutterOverlayWindow.closeOverlay();
                  },
                  child: Text("CLOSE"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}