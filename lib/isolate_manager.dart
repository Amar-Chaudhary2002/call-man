// lib/presentation/dashboard/isolate_manager.dart
import 'dart:isolate';
import 'dart:ui';
import 'dart:developer';

/// Helper class for managing isolate communication ports
class IsolateManager {
  static const String FOREGROUND_PORT_NAME = "foreground_port";
  static const String BACKGROUND_PORT_NAME = "background_port";
  static const String OVERLAY_PORT_NAME = "overlay_port";

  /// Look up a port by name
  static SendPort? lookupPortByName([String name = FOREGROUND_PORT_NAME]) {
    try {
      return IsolateNameServer.lookupPortByName(name);
    } catch (e) {
      log('Error looking up port $name: $e');
      return null;
    }
  }

  /// Register a port with a name
  static bool registerPortWithName(SendPort port, [String name = FOREGROUND_PORT_NAME]) {
    try {
      removePortNameMapping(name);
      return IsolateNameServer.registerPortWithName(port, name);
    } catch (e) {
      log('Error registering port $name: $e');
      return false;
    }
  }

  /// Remove port name mapping
  static bool removePortNameMapping([String name = FOREGROUND_PORT_NAME]) {
    try {
      return IsolateNameServer.removePortNameMapping(name);
    } catch (e) {
      log('Error removing port mapping $name: $e');
      return false;
    }
  }

  /// Send message to a specific port
  static bool sendMessageToPort(dynamic message, [String portName = FOREGROUND_PORT_NAME]) {
    try {
      final port = lookupPortByName(portName);
      if (port != null) {
        port.send(message);
        return true;
      }
      log('Port $portName not found');
      return false;
    } catch (e) {
      log('Error sending message to port $portName: $e');
      return false;
    }
  }

  /// Clean up all registered ports
  static void cleanupAllPorts() {
    try {
      removePortNameMapping(FOREGROUND_PORT_NAME);
      removePortNameMapping(BACKGROUND_PORT_NAME);
      removePortNameMapping(OVERLAY_PORT_NAME);
      log('✅ All isolate ports cleaned up');
    } catch (e) {
      log('❌ Error cleaning up ports: $e');
    }
  }
}