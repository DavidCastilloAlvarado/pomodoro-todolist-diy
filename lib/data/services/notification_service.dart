import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  NotificationService._internal();

  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(settings);

    const androidChannel = AndroidNotificationChannel(
      'birdle_alarms',
      'Birdle Alarms',
      description: 'Notifications for todo item alarms and pomodoro timers',
      importance: Importance.high,
    );

    await _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(androidChannel);

    _initialized = true;
  }

  Future<void> showNotification(
    String title,
    String body, {
    int id = 0,
  }) async {
    await init();

    const android = AndroidNotificationDetails(
      'birdle_alarms',
      'Birdle Alarms',
      channelDescription: 'Notifications for todo item alarms and pomodoro timers',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: false,
    );

    const settings = NotificationDetails(android: android);

    await _plugin.show(id, title, body, settings);
  }

  Future<void> cancelNotification(String id) async {
    final notificationId = id.hashCode;
    await _plugin.cancel(notificationId);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Schedule a one-time notification at the given time.
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    await init();

    // Initialize timezone database if not already done
    try {
      tz_data.initializeTimeZones();
    } catch (_) {}

    final tzLocation = tz.getLocation('Asia/Manila');
    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tzLocation);

    const android = AndroidNotificationDetails(
      'birdle_alarms',
      'Birdle Alarms',
      channelDescription: 'Notifications for todo item alarms and pomodoro timers',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: false,
    );

    const settings = NotificationDetails(android: android);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduledTime,
      settings,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.wallClockTime,
      androidScheduleMode: AndroidScheduleMode.alarmClock,
    );
  }

  /// Schedule a daily recurring notification at the given time.
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    await init();

    const android = AndroidNotificationDetails(
      'birdle_alarms',
      'Birdle Alarms',
      channelDescription: 'Notifications for todo item alarms and pomodoro timers',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: false,
    );

    const settings = NotificationDetails(android: android);

    // Use periodicallyShow with daily repeat
    await _plugin.periodicallyShow(
      id,
      title,
      body,
      RepeatInterval.daily,
      settings,
      androidScheduleMode: AndroidScheduleMode.alarmClock,
    );
  }

  /// Cancel a notification by its ID.
  Future<void> cancelById(int id) async {
    await _plugin.cancel(id);
  }
}
