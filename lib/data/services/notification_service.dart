import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  NotificationService._internal();

  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

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

    final android = AndroidNotificationDetails(
      'birdle_alarms',
      'Birdle Alarms',
      channelDescription: 'Notifications for todo item alarms and pomodoro timers',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: false,
    );

    final settings = NotificationDetails(android: android);

    await _plugin.show(id, title, body, settings);
  }

  Future<void> cancelNotification(String id) async {
    final notificationId = id.hashCode.abs();
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

    final supportsExactAlarms = await canScheduleExactAlarms();
    final scheduleMode = supportsExactAlarms
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    debugPrint('NotificationService: Exact alarms ${supportsExactAlarms ? 'supported' : 'not supported'}, using ${supportsExactAlarms ? 'exactAllowWhileIdle' : 'inexactAllowWhileIdle'}');

    final tzScheduledTime = tz.TZDateTime(
      tz.local,
      scheduledTime.year,
      scheduledTime.month,
      scheduledTime.day,
      scheduledTime.hour,
      scheduledTime.minute,
    );

    debugPrint('NotificationService: Scheduling notification id=$id at $tzScheduledTime');

    final android = AndroidNotificationDetails(
      'birdle_alarms',
      'Birdle Alarms',
      channelDescription: 'Notifications for todo item alarms and pomodoro timers',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: false,
    );

    final settings = NotificationDetails(android: android);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduledTime,
      settings,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.wallClockTime,
      androidScheduleMode: scheduleMode,
    );

    debugPrint('NotificationService: Notification scheduled successfully id=$id');
  }

  /// Schedule a daily recurring notification at the given time.
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    await init();

    final supportsExactAlarms = await canScheduleExactAlarms();
    final scheduleMode = supportsExactAlarms
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    debugPrint('NotificationService: Exact alarms ${supportsExactAlarms ? 'supported' : 'not supported'}, using ${supportsExactAlarms ? 'exactAllowWhileIdle' : 'inexactAllowWhileIdle'}');

    // Calculate the next occurrence of the target time
    final now = DateTime.now();
    final todayAtTargetTime = DateTime(
      now.year, now.month, now.day,
      time.hour, time.minute,
    );

    DateTime nextOccurrence;
    if (todayAtTargetTime.isAfter(now) || todayAtTargetTime.isAtSameMomentAs(now)) {
      // Target time is still ahead today
      nextOccurrence = todayAtTargetTime;
    } else {
      // Target time has passed today, schedule for tomorrow
      nextOccurrence = todayAtTargetTime.add(const Duration(days: 1));
    }

    // Create TZDateTime from local DateTime components
    final tzScheduledTime = tz.TZDateTime(
      tz.local,
      nextOccurrence.year,
      nextOccurrence.month,
      nextOccurrence.day,
      nextOccurrence.hour,
      nextOccurrence.minute,
    );

    debugPrint('NotificationService: Scheduling notification id=$id at $tzScheduledTime');

    final android = AndroidNotificationDetails(
      'birdle_alarms',
      'Birdle Alarms',
      channelDescription: 'Notifications for todo item alarms and pomodoro timers',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: false,
    );

    final settings = NotificationDetails(android: android);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduledTime,
      settings,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.wallClockTime,
      androidScheduleMode: scheduleMode,
    );

    debugPrint('NotificationService: Notification scheduled successfully id=$id');
  }

  /// Request notification permission on Android 13+.
  Future<bool> requestNotificationPermission() async {
    final plugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await plugin?.requestNotificationsPermission() ?? false;
  }

  /// Check whether the device supports exact alarms.
  Future<bool> canScheduleExactAlarms() async {
    final status = await Permission.scheduleExactAlarm.status;
    return status.isGranted;
  }

  /// Request the SCHEDULE_EXACT_ALARM runtime permission.
  Future<bool> requestExactAlarmPermission() async {
    final permission = Permission.scheduleExactAlarm;
    if (await permission.status.isGranted) return true;
    final result = await permission.request();
    return result.isGranted;
  }

  /// Cancel a notification by its ID.
  Future<void> cancelById(int id) async {
    await _plugin.cancel(id);
  }
}
