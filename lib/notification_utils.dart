import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationUtils {
  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'call_tracking_service_channel', // id
    'Call Tracking Service', // title
    description: 'Monitors incoming and outgoing calls',
    importance: Importance.low,
  );

  static Future<void> initialize() async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
}