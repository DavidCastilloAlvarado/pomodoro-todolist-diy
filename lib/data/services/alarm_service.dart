import 'package:flutter/material.dart';
import 'package:birdle/data/models/todo_item.dart';
import 'package:birdle/data/services/database.dart';
import 'package:birdle/data/services/notification_service.dart';

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  AlarmService._internal();

  factory AlarmService() => _instance;

  late BirdleDatabase _db;
  late NotificationService _notificationService;

  void init({required BirdleDatabase database}) {
    _db = database;
    _notificationService = NotificationService();
  }

  /// Schedule an alarm for the given item.
  /// - For "every day": schedules a daily recurring notification.
  /// - For specific day: schedules a one-time notification for the next occurrence.
  Future<void> scheduleAlarm(TodoItem item) async {
    WidgetsFlutterBinding.ensureInitialized();

    final alarm = item.alarm;
    if (alarm == null) return;

    try {
      final now = DateTime.now();
      DateTime alarmTime;

      switch (alarm.day) {
        case DayOfWeek.everyDay:
          debugPrint('AlarmService: Scheduling daily alarm for "${item.title}" at ${alarm.time.hour}:${alarm.time.minute.toString().padLeft(2, '0')}');
          // Schedule daily recurring notification
          await _notificationService.scheduleDailyNotification(
            id: item.id.hashCode.abs(),
            title: item.title,
            body: 'Reminder: ${item.title}',
            time: alarm.time,
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
          // Calculate the next occurrence of the target day
          final currentDayOfWeek = now.weekday;
          final targetDay = alarm.day.index + 1;
          int daysUntil = targetDay - currentDayOfWeek;

          // Calculate the target time today
          final todayTargetTime = DateTime(
            now.year, now.month, now.day,
            alarm.time.hour, alarm.time.minute,
          );

          if (daysUntil < 0) {
            // Past day of the week (e.g., it's Wednesday, alarm is for Monday)
            daysUntil += 7;
          } else if (daysUntil == 0) {
            // Same day — check if the target time has passed
            if (todayTargetTime.isBefore(now)) {
              // Time has passed today, schedule for next week
              daysUntil = 7;
            }
            // else: time hasn't passed today, daysUntil stays 0 → schedules for today
          }
          // else: daysUntil > 0 → future day of the week, schedule as-is

          alarmTime = DateTime(
            now.year,
            now.month,
            now.day + daysUntil,
            alarm.time.hour,
            alarm.time.minute,
          );

          debugPrint('AlarmService: Scheduling alarm for "${item.title}" — day: ${alarm.day}, time: ${alarm.time.hour}:${alarm.time.minute.toString().padLeft(2, '0')}');
          // Schedule a one-time notification for that specific day/time
          await _notificationService.scheduleNotification(
            id: item.id.hashCode.abs(),
            title: item.title,
            body: 'Reminder: ${item.title}',
            scheduledTime: alarmTime,
          );
          debugPrint('AlarmService: Alarm scheduled OK for "${item.title}"');
          break;
      }
    } catch (e, stack) {
      debugPrint('AlarmService: Failed to schedule alarm for "${item.title}": $e\n$stack');
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
      for (final itemData in pendingItems) {
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
