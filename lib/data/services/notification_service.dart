import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
}
