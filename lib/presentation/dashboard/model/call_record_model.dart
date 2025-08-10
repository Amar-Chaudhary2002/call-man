import 'package:flutter/material.dart';
import '../recent_call_screen.dart';

class CallRecord {
  final String phoneNumber;
  final DateTime startTime;
  final DateTime? endTime;
  final CallState state;
  final bool isOutgoing;
  final Duration? duration;
  final bool isConnected;
  final String contactName;

  CallRecord({
    required this.phoneNumber,
    required this.startTime,
    this.endTime,
    required this.state,
    required this.isOutgoing,
    this.duration,
    this.isConnected = false,
    this.contactName = '',
  });

  CallRecord copyWith({
    String? phoneNumber,
    DateTime? startTime,
    DateTime? endTime,
    CallState? state,
    bool? isOutgoing,
    Duration? duration,
    bool? isConnected,
    String? contactName,
  }) {
    return CallRecord(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      state: state ?? this.state,
      isOutgoing: isOutgoing ?? this.isOutgoing,
      duration: duration ?? this.duration,
      isConnected: isConnected ?? this.isConnected,
      contactName: contactName ?? this.contactName,
    );
  }

  String get callType {
    if (state == CallState.disconnected &&
        duration != null &&
        duration!.inSeconds > 0) {
      return isOutgoing ? "Outgoing" : "Incoming";
    } else if (state == CallState.disconnected &&
        (duration == null || duration!.inSeconds == 0)) {
      return isOutgoing ? "Not picked" : "Missed call";
    } else if (state == CallState.ringing) {
      return isOutgoing ? "Calling..." : "Incoming call";
    } else if (state == CallState.offhook) {
      return "Connected";
    }
    return "Unknown";
  }

  /// Text color based on call type
  Color get callTypeColor {
    final lower = callType.toLowerCase();
    if (lower.contains("missed")) return Color(0xFFEF4444);
    if (lower.contains("not picked")) return Color(0xFFF56E0B);
    if (lower.contains("incoming")) return const Color(0xFF5498F7);
    if (lower.contains("outgoing")) return const Color(0xFF10B981);
    if (lower.contains("connected")) return Color(0xFF10B981);
    // if (lower.contains("calling")) return Colors.amber;
    return Colors.white70;
  }

  /// Background color for the CircleAvatar
  Color get callTypeBackgroundColor => callTypeColor.withOpacity(0.15);

  /// SVG asset path for call type
  String get svgAsset {
    final lower = callType.toLowerCase();
    if (lower.contains("missed")) return "assets/images/missed call.svg";
    if (lower.contains("not picked")) return "assets/images/not picked.svg";
    if (lower.contains("incoming")) return "assets/images/incoming.svg";
    if (lower.contains("outgoing")) return "assets/images/outgoing.svg";
    if (lower.contains("connected")) return "assets/icons/connected.svg";
    // if (lower.contains("calling")) return "assets/icons/calling.svg";
    return "assets/images/decline.svg";
  }

  String get displayName => contactName.isNotEmpty ? contactName : phoneNumber;

  String get formattedTime {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final callDate = DateTime(startTime.year, startTime.month, startTime.day);

    String formatHourMinute(DateTime dt) {
      final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      return "$hour:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}";
    }

    if (callDate == today) {
      return formatHourMinute(startTime);
    } else if (callDate == yesterday) {
      return "Yesterday ${formatHourMinute(startTime)}";
    } else {
      return "${_getMonthName(startTime.month)} ${startTime.day}, ${formatHourMinute(startTime)}";
    }
  }

  String _getMonthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month];
  }

  String get durationText {
    if (duration == null || duration!.inSeconds == 0) return '';
    final minutes = duration!.inMinutes;
    final seconds = duration!.inSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}
