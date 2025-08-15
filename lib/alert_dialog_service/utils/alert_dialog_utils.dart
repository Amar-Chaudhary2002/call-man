// Fixed alert_dialog_utils.dart
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class AlertDialogUtils {

  static Future<void> showDialog() async {
    try {
      // Close any existing overlay first
      await FlutterOverlayWindow.closeOverlay();

      // Small delay to ensure previous overlay is closed
      await Future.delayed(const Duration(milliseconds: 100));

      // Show overlay with proper parameters
      await FlutterOverlayWindow.showOverlay(
        height: WindowSize.fullCover, // Try full screen first
        width: WindowSize.fullCover,
        overlayTitle: "5 Second Alert",
        overlayContent: "This overlay appears every 5 seconds",
        enableDrag: true,
        positionGravity: PositionGravity.auto,
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilityPublic,
      );

      print("Overlay shown with full parameters");

    } catch (e) {
      print("Error showing overlay: $e");

      // Fallback: try with minimal parameters
      try {
        await FlutterOverlayWindow.showOverlay();
        print("Overlay shown with minimal parameters");
      } catch (e2) {
        print("Fallback overlay also failed: $e2");
      }
    }
  }

  static Future<void> closeAlertDialog() async {
    try {
      await FlutterOverlayWindow.closeOverlay();
      print("Overlay closed successfully");
    } catch (e) {
      print("Error closing overlay: $e");
    }
  }

  static getOverlayPermission() async {
    bool status = await FlutterOverlayWindow.isPermissionGranted();
    if (!status) {
      await FlutterOverlayWindow.requestPermission();
    }
  }
}