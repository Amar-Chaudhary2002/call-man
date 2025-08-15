// Updated main.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:call_app/alert_dialog_service/overlay_widget.dart';
import 'package:call_app/database/database_service.dart';
import 'package:call_app/main_app_ui/home.dart';
import 'package:call_app/main_app_ui/permissions_screen.dart';
import 'package:call_app/monitoring_service/utils/flutter_background_service_utils.dart';

void main() async {
  // Start the monitoring service
  await onStart();
  DatabaseService dbService = await DatabaseService.instance();

  // Only check overlay permission since we don't need usage stats
  bool permissionsAvailable = await FlutterOverlayWindow.isPermissionGranted();

  runApp(MyApp(
      permissionsAvailable ? Home(dbService) : PermissionsScreen(dbService),
      dbService));
}

onStart() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  await startMonitoringService();
}

// This is the isolate entry for the Alert Window Service
// It needs to be added in the main.dart file with the name "overlayMain"

// In main.dart, before runApp():


@pragma("vm:entry-point")
void overlayMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await FlutterOverlayWindow.setOverlayEntryPoint(callback: overlayMain);


  debugPrint("Starting Overlay Isolate!");

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: OverlayWidget(),
    theme: ThemeData(
      primarySwatch: Colors.blue,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    ),
  ));
}

class MyApp extends StatelessWidget {
  Widget screenToDisplay;
  DatabaseService dbService;

  MyApp(this.screenToDisplay, this.dbService);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: screenToDisplay,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
    );
  }
}