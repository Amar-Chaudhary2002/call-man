// isolate_manager.dart
import 'dart:isolate';
import 'dart:ui';

class IsolateManager {
  static const FOREGROUND_PORT_NAME = "foreground_port";

  static SendPort? lookupPortByName([String name = FOREGROUND_PORT_NAME]) {
    return IsolateNameServer.lookupPortByName(name);
  }

  static bool registerPortWithName(SendPort port, [String name = FOREGROUND_PORT_NAME]) {
    removePortNameMapping(name);
    return IsolateNameServer.registerPortWithName(port, name);
  }

  static bool removePortNameMapping([String name = FOREGROUND_PORT_NAME]) {
    return IsolateNameServer.removePortNameMapping(name);
  }
}
