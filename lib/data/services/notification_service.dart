import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  static DateTime _systemNow() => DateTime.now();

  static DateTime? Function() _resolveNowProvider(
    DateTime? Function()? nowProvider,
  ) {
    return nowProvider ?? _systemNow;
  }

  static String _formatTimezoneOffset(Duration offset) {
    final absoluteOffset = offset.abs();
    final hours = absoluteOffset.inHours.toString().padLeft(2, '0');
    final minutes = absoluteOffset.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final sign = offset.isNegative ? '-' : '+';
    return '$sign$hours:$minutes';
  }

  static tz.Location _defaultFallbackTimezoneLocationProvider(
    DateTime referenceLocalNow,
  ) {
    final offset = referenceLocalNow.timeZoneOffset;
    final formattedOffset = _formatTimezoneOffset(offset);
    final abbreviation = referenceLocalNow.timeZoneName.trim().isNotEmpty
        ? referenceLocalNow.timeZoneName.trim()
        : 'UTC$formattedOffset';

    return tz.Location(
      'Birdle/LocalOffset$formattedOffset',
      const <int>[],
      const <int>[],
      <tz.TimeZone>[
        tz.TimeZone(
          offset.inMilliseconds,
          isDst: false,
          abbreviation: abbreviation,
        ),
      ],
    );
  }

  NotificationService._internal({
    FlutterLocalNotificationsPlugin? plugin,
    Future<String> Function()? localTimezoneIdentifierProvider,
    DateTime? Function()? nowProvider,
    tz.Location Function(String timezoneIdentifier)? timezoneLocationResolver,
    tz.Location Function(DateTime referenceLocalNow)?
    fallbackTimezoneLocationProvider,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _localTimezoneIdentifierProvider =
           localTimezoneIdentifierProvider ??
           _defaultLocalTimezoneIdentifierProvider,
       _nowProvider = _resolveNowProvider(nowProvider),
       _timezoneLocationResolver = timezoneLocationResolver ?? tz.getLocation,
       _fallbackTimezoneLocationProvider =
           fallbackTimezoneLocationProvider ??
           _defaultFallbackTimezoneLocationProvider;

  factory NotificationService() => _instance;

  NotificationService.test({
    FlutterLocalNotificationsPlugin? plugin,
    Future<String> Function()? localTimezoneIdentifierProvider,
    DateTime? Function()? nowProvider,
    tz.Location Function(String timezoneIdentifier)? timezoneLocationResolver,
    tz.Location Function(DateTime referenceLocalNow)?
    fallbackTimezoneLocationProvider,
  }) : this._internal(
         plugin: plugin,
         localTimezoneIdentifierProvider: localTimezoneIdentifierProvider,
         nowProvider: nowProvider,
         timezoneLocationResolver: timezoneLocationResolver,
         fallbackTimezoneLocationProvider: fallbackTimezoneLocationProvider,
       );

  final FlutterLocalNotificationsPlugin _plugin;
  final Future<String> Function() _localTimezoneIdentifierProvider;
  final DateTime? Function() _nowProvider;
  final tz.Location Function(String timezoneIdentifier)
  _timezoneLocationResolver;
  final tz.Location Function(DateTime referenceLocalNow)
  _fallbackTimezoneLocationProvider;
  bool _initialized = false;

  static Future<String> _defaultLocalTimezoneIdentifierProvider() async {
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    return timezoneInfo.identifier;
  }

  DateTime _resolveNow() {
    final referenceNow = _nowProvider();
    if (referenceNow != null) {
      return referenceNow;
    }

    debugPrint(
      'NotificationService: nowProvider returned null, falling back to DateTime.now()',
    );
    return _systemNow();
  }

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    await initializeLocalTimezone();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(settings);

    const androidChannel = AndroidNotificationChannel(
      'birdle_alarms',
      'Birdle Alarms',
      description: 'Notifications for todo item alarms and pomodoro timers',
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);

    _initialized = true;
  }

  Future<void> initializeLocalTimezone() async {
    tz_data.initializeTimeZones();
    try {
      final localTimezoneIdentifier = await _localTimezoneIdentifierProvider();
      final location = _timezoneLocationResolver(localTimezoneIdentifier);
      tz.setLocalLocation(location);
      debugPrint(
        'NotificationService: Local timezone initialized to $localTimezoneIdentifier',
      );
    } on MissingPluginException catch (error, stackTrace) {
      _setFallbackTimezone(
        reason:
            'timezone plugin unavailable during local timezone initialization',
        error: error,
        stackTrace: stackTrace,
      );
    } on PlatformException catch (error, stackTrace) {
      _setFallbackTimezone(
        reason: 'timezone platform lookup failed during initialization',
        error: error,
        stackTrace: stackTrace,
      );
    } on Exception catch (error, stackTrace) {
      _setFallbackTimezone(
        reason: 'timezone lookup failed during initialization',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _setFallbackTimezone({
    required String reason,
    required Object error,
    required StackTrace stackTrace,
  }) {
    try {
      final fallbackLocation = _fallbackTimezoneLocationProvider(_resolveNow());
      tz.setLocalLocation(fallbackLocation);
      debugPrint(
        'NotificationService: $reason ($error). '
        'Falling back to fixed-offset local timezone ${fallbackLocation.name}.',
      );
      debugPrintStack(
        label: 'NotificationService timezone fallback reason',
        stackTrace: stackTrace,
      );
    } catch (fallbackError, fallbackStackTrace) {
      final utcLocation = _timezoneLocationResolver('UTC');
      tz.setLocalLocation(utcLocation);
      debugPrint(
        'NotificationService: $reason ($error). '
        'Failed to build fixed-offset fallback timezone, using UTC instead: '
        '$fallbackError',
      );
      debugPrintStack(
        label: 'NotificationService timezone fallback reason',
        stackTrace: stackTrace,
      );
      debugPrintStack(
        label: 'NotificationService UTC fallback reason',
        stackTrace: fallbackStackTrace,
      );
    }
  }

  DateTime computeNextDailyOccurrence(TimeOfDay time, {DateTime? now}) {
    final referenceNow = now ?? _resolveNow();
    final todayAtTargetTime = DateTime(
      referenceNow.year,
      referenceNow.month,
      referenceNow.day,
      time.hour,
      time.minute,
    );

    if (todayAtTargetTime.isAfter(referenceNow)) {
      return todayAtTargetTime;
    }

    return DateTime(
      referenceNow.year,
      referenceNow.month,
      referenceNow.day + 1,
      time.hour,
      time.minute,
    );
  }

  tz.TZDateTime createWallClockSchedule(DateTime scheduledTime) {
    return tz.TZDateTime(
      tz.local,
      scheduledTime.year,
      scheduledTime.month,
      scheduledTime.day,
      scheduledTime.hour,
      scheduledTime.minute,
    );
  }

  Future<void> showNotification(String title, String body, {int id = 0}) async {
    await init();

    final android = AndroidNotificationDetails(
      'birdle_alarms',
      'Birdle Alarms',
      channelDescription:
          'Notifications for todo item alarms and pomodoro timers',
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

    debugPrint(
      'NotificationService: Exact alarms ${supportsExactAlarms ? 'supported' : 'not supported'}, using ${supportsExactAlarms ? 'exactAllowWhileIdle' : 'inexactAllowWhileIdle'}',
    );

    final tzScheduledTime = createWallClockSchedule(scheduledTime);

    debugPrint(
      'NotificationService: Scheduling notification id=$id '
      'at $tzScheduledTime (${tz.local.name})',
    );

    final android = AndroidNotificationDetails(
      'birdle_alarms',
      'Birdle Alarms',
      channelDescription:
          'Notifications for todo item alarms and pomodoro timers',
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
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      androidScheduleMode: scheduleMode,
    );

    debugPrint(
      'NotificationService: Notification scheduled successfully id=$id',
    );
  }

  /// Schedule a daily recurring notification at the given time.
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    DateTime? firstOccurrence,
  }) async {
    await init();

    final supportsExactAlarms = await canScheduleExactAlarms();
    final scheduleMode = supportsExactAlarms
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    debugPrint(
      'NotificationService: Exact alarms ${supportsExactAlarms ? 'supported' : 'not supported'}, using ${supportsExactAlarms ? 'exactAllowWhileIdle' : 'inexactAllowWhileIdle'}',
    );

    final referenceNow = _resolveNow();
    final nextOccurrence =
        firstOccurrence != null && firstOccurrence.isAfter(referenceNow)
        ? firstOccurrence
        : computeNextDailyOccurrence(time, now: referenceNow);
    final tzScheduledTime = createWallClockSchedule(nextOccurrence);

    debugPrint(
      'NotificationService: Scheduling daily notification id=$id '
      'at $tzScheduledTime (${tz.local.name})',
    );

    final android = AndroidNotificationDetails(
      'birdle_alarms',
      'Birdle Alarms',
      channelDescription:
          'Notifications for todo item alarms and pomodoro timers',
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
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: scheduleMode,
    );

    debugPrint(
      'NotificationService: Notification scheduled successfully id=$id',
    );
  }

  /// Request notification permission on Android 13+.
  Future<bool> requestNotificationPermission() async {
    final plugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
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
