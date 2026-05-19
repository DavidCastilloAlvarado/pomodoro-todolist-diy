import 'package:flutter/material.dart';
import 'package:birdle/data/models/todo_item.dart';
import 'package:birdle/data/services/database.dart';
import 'package:birdle/data/services/notification_service.dart';

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();

  static DateTime _systemNow() => DateTime.now();

  static DateTime Function() _resolveNowProvider(
    DateTime? Function()? nowProvider,
  ) {
    if (nowProvider == null) {
      return _systemNow;
    }

    return () {
      final referenceNow = nowProvider();
      if (referenceNow != null) {
        return referenceNow;
      }

      debugPrint(
        'AlarmService: nowProvider returned null, falling back to DateTime.now()',
      );
      return _systemNow();
    };
  }

  AlarmService._internal({
    NotificationService? notificationService,
    DateTime? Function()? nowProvider,
  }) : _notificationService = notificationService ?? NotificationService(),
       _nowProvider = _resolveNowProvider(nowProvider);

  factory AlarmService() => _instance;

  AlarmService.test({
    required NotificationService notificationService,
    DateTime? Function()? nowProvider,
  }) : _notificationService = notificationService,
       _nowProvider = _resolveNowProvider(nowProvider);

  late BirdleDatabase _db;
  final NotificationService _notificationService;
  final DateTime Function() _nowProvider;

  DateTime _resolveNow() {
    return _nowProvider();
  }

  void init({required BirdleDatabase database}) {
    _db = database;
  }

  DateTime computeNextLocalOccurrence(AlarmInfo alarm, {DateTime? now}) {
    final referenceNow = now ?? _resolveNow();

    switch (alarm.day) {
      case DayOfWeek.everyDay:
        return DateTime(
              referenceNow.year,
              referenceNow.month,
              referenceNow.day,
              alarm.time.hour,
              alarm.time.minute,
            ).isAfter(referenceNow)
            ? DateTime(
                referenceNow.year,
                referenceNow.month,
                referenceNow.day,
                alarm.time.hour,
                alarm.time.minute,
              )
            : DateTime(
                referenceNow.year,
                referenceNow.month,
                referenceNow.day + 1,
                alarm.time.hour,
                alarm.time.minute,
              );
      case DayOfWeek.monday:
      case DayOfWeek.tuesday:
      case DayOfWeek.wednesday:
      case DayOfWeek.thursday:
      case DayOfWeek.friday:
      case DayOfWeek.saturday:
      case DayOfWeek.sunday:
        final currentDayOfWeek = referenceNow.weekday;
        final targetDay = alarm.day.index + 1;
        int daysUntil = targetDay - currentDayOfWeek;

        final todayTargetTime = DateTime(
          referenceNow.year,
          referenceNow.month,
          referenceNow.day,
          alarm.time.hour,
          alarm.time.minute,
        );

        if (daysUntil < 0) {
          daysUntil += 7;
        } else if (daysUntil == 0 && !todayTargetTime.isAfter(referenceNow)) {
          daysUntil = 7;
        }

        var alarmTime = DateTime(
          referenceNow.year,
          referenceNow.month,
          referenceNow.day + daysUntil,
          alarm.time.hour,
          alarm.time.minute,
        );

        if (!alarmTime.isAfter(referenceNow)) {
          alarmTime = DateTime(
            referenceNow.year,
            referenceNow.month,
            referenceNow.day + daysUntil + 7,
            alarm.time.hour,
            alarm.time.minute,
          );
        }

        return alarmTime;
    }
  }

  /// Schedule an alarm for the given item.
  /// - For "every day": schedules a daily recurring notification.
  /// - For specific day: schedules a one-time notification for the next occurrence.
  Future<void> scheduleAlarm(TodoItem item) async {
    WidgetsFlutterBinding.ensureInitialized();

    final alarm = item.alarm;
    if (alarm == null) return;

    try {
      final now = _resolveNow();

      switch (alarm.day) {
        case DayOfWeek.everyDay:
          final firstOccurrence = computeNextLocalOccurrence(alarm, now: now);
          debugPrint(
            'AlarmService: Scheduling daily alarm for "${item.title}" at ${alarm.time.hour}:${alarm.time.minute.toString().padLeft(2, '0')}',
          );
          // Schedule daily recurring notification
          final diagnostics = await _notificationService
              .scheduleDailyNotification(
                id: item.id.hashCode.abs(),
                title: item.title,
                body: 'Reminder: ${item.title}',
                time: alarm.time,
                firstOccurrence: firstOccurrence,
              );
          debugPrint(
            'AlarmService: Daily delivery diagnostics -> ${diagnostics.toLogString()}',
          );
          await _notificationService.logPendingNotificationRequests(
            context: 'schedule-daily-${item.id}',
          );
          debugPrint(
            _notificationService.buildManualVerificationGuide(
              notificationId: item.id.hashCode.abs(),
              title: item.title,
              scheduledTime: firstOccurrence,
              scheduleMode: diagnostics.scheduleMode,
            ),
          );
          debugPrint('AlarmService: Alarm scheduled OK for "${item.title}"');
          return;

        case DayOfWeek.monday:
        case DayOfWeek.tuesday:
        case DayOfWeek.wednesday:
        case DayOfWeek.thursday:
        case DayOfWeek.friday:
        case DayOfWeek.saturday:
        case DayOfWeek.sunday:
          final alarmTime = computeNextLocalOccurrence(alarm, now: now);

          debugPrint(
            'AlarmService: Scheduling alarm for "${item.title}" — day: ${alarm.day}, time: ${alarm.time.hour}:${alarm.time.minute.toString().padLeft(2, '0')}, next local occurrence: $alarmTime',
          );
          // Schedule a one-time notification for that specific day/time
          final diagnostics = await _notificationService.scheduleNotification(
            id: item.id.hashCode.abs(),
            title: item.title,
            body: 'Reminder: ${item.title}',
            scheduledTime: alarmTime,
          );
          debugPrint(
            'AlarmService: Delivery diagnostics -> ${diagnostics.toLogString()}',
          );
          await _notificationService.logPendingNotificationRequests(
            context: 'schedule-once-${item.id}',
          );
          debugPrint(
            _notificationService.buildManualVerificationGuide(
              notificationId: item.id.hashCode.abs(),
              title: item.title,
              scheduledTime: alarmTime,
              scheduleMode: diagnostics.scheduleMode,
            ),
          );
          debugPrint('AlarmService: Alarm scheduled OK for "${item.title}"');
          break;
      }
    } catch (e, stack) {
      debugPrint(
        'AlarmService: Failed to schedule alarm for "${item.title}": $e\n$stack',
      );
    }
  }

  /// Cancel the alarm for the given item.
  Future<void> cancelAlarm(String itemId) async {
    await _notificationService.cancelById(itemId.hashCode.abs());
  }

  /// Re-register all alarms from the database (called on app startup).
  Future<void> reRegisterAllAlarms() async {
    try {
      final pendingItems = await _db.getPendingAlarms();
      debugPrint(
        'AlarmService: Re-registering ${pendingItems.length} persisted alarm(s) on startup',
      );
      for (final itemData in pendingItems) {
        // Skip completed items — their alarms should not be re-registered.
        if (itemData.completed == 1) continue;

        final alarmDay = itemData.alarmDay!;
        final alarmHour = itemData.alarmHour!;
        final alarmMinute = itemData.alarmMinute!;

        final item = TodoItem(
          id: itemData.id,
          listId: itemData.listId,
          title: itemData.title,
          completed: itemData.completed == 1,
          color: Color(itemData.colorHex),
          alarm: AlarmInfo(
            day: DayOfWeek.values[alarmDay],
            time: TimeOfDay(hour: alarmHour, minute: alarmMinute),
          ),
          createdAt: DateTime.fromMillisecondsSinceEpoch(itemData.createdAt),
        );

        await scheduleAlarm(item);
      }

      await _notificationService.logPendingNotificationRequests(
        context: 'alarm-reregistration-complete',
      );
    } catch (e, stack) {
      debugPrint('AlarmService: Failed to re-register alarms: $e\n$stack');
    }
  }

  /// Get pending alarms from the database.
  List<TodoItem> getPendingAlarms() {
    return [];
  }

  /// Initialize the alarm manager (called on app startup).
  Future<void> initAlarmManager() async {
    await reRegisterAllAlarms();
  }
}
