import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _notifications.initialize(settings);

    await requestPermission();
  }


  static Future<void> requestPermission() async {
    if (Platform.isAndroid) {
      final androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      // Android 13+ needs this
      await androidImplementation?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      final iosImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  // Start (Persistent Notification)
  static Future<void> showOngoingNotification({
    required String title,
    required String content,
    required DateTime dateTime,
  }) async {
    final formattedDate = DateFormat('dd MM yyyy, hh:mm a').format(dateTime);

    const androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Reminders',
      channelDescription: 'This channel is for ongoing reminders',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: true, // Makes it non-dismissible
      autoCancel: false, // Prevents auto-removal
      showWhen: true,
      category: AndroidNotificationCategory.reminder,
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      0, // Notification ID (we keep 0 so we can cancel it easily)
      title,
      "$content\nTime: $formattedDate",
      details,
    );
  }

  // Stop (Cancel Notification)
  static Future<void> cancelOngoingNotification() async {
    await _notifications.cancel(0);
  }
}
