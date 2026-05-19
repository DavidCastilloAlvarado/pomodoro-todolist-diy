import 'package:flutter/material.dart';
import 'package:birdle/data/models/todo_item.dart';
import 'package:birdle/data/services/alarm_service.dart';
import 'package:birdle/data/services/database.dart';

class ItemRepository {
  ItemRepository({
    required BirdleDatabase database,
    required AlarmService alarm,
  }) : _db = database, _alarm = alarm;

  final BirdleDatabase _db;
  final AlarmService _alarm;

  Future<List<TodoItem>> getItems(String listId) async {
    final data = await _db.getItemsByList(listId);
    return data.map((d) {
      AlarmInfo? alarm;
      if (d.alarmDay != null && d.alarmHour != null && d.alarmMinute != null) {
        alarm = AlarmInfo(
          day: DayOfWeek.values[d.alarmDay!],
          time: TimeOfDay(hour: d.alarmHour!, minute: d.alarmMinute!),
        );
      }
      return TodoItem(
        id: d.id,
        listId: d.listId,
        title: d.title,
        completed: d.completed == 1,
        color: Color(d.colorHex),
        alarm: alarm,
        createdAt: DateTime.fromMillisecondsSinceEpoch(d.createdAt),
      );
    }).toList();
  }

  Future<void> addItem(TodoItem item) async {
    await _db.insertTodoItem(TodoItemsData(
      id: item.id,
      listId: item.listId,
      title: item.title,
      completed: item.completed ? 1 : 0,
      colorHex: item.color.toARGB32(),
      alarmDay: item.alarm?.day.index,
      alarmHour: item.alarm?.time.hour,
      alarmMinute: item.alarm?.time.minute,
      createdAt: item.createdAt.millisecondsSinceEpoch,
    ));
    if (item.alarm != null) {
      await _alarm.scheduleAlarm(item);
    }
  }

  Future<void> updateItem(TodoItem item) async {
    // Determine if the alarm is being removed (was non-null, now null).
    final wasAlarmSet = item.alarm != null;
    await _db.updateTodoItem(TodoItemsData(
      id: item.id,
      listId: item.listId,
      title: item.title,
      completed: item.completed ? 1 : 0,
      colorHex: item.color.toARGB32(),
      alarmDay: item.alarm?.day.index,
      alarmHour: item.alarm?.time.hour,
      alarmMinute: item.alarm?.time.minute,
      createdAt: item.createdAt.millisecondsSinceEpoch,
    ));
    // Only schedule alarms for non-completed items.
    if (item.alarm != null && !item.completed) {
      await _alarm.scheduleAlarm(item);
    }
    // If the alarm was previously set but is now being cleared, cancel it.
    if (wasAlarmSet && item.alarm == null) {
      await _alarm.cancelAlarm(item.id);
    }
  }

  Future<void> toggleCompleted(String itemId) async {
    final itemData = await _db.getTodoItemById(itemId);
    if (itemData == null) return;

    final item = TodoItem(
      id: itemData.id,
      listId: itemData.listId,
      title: itemData.title,
      completed: itemData.completed == 1,
      color: Color(itemData.colorHex),
      alarm: itemData.alarmDay != null
          ? AlarmInfo(
              day: DayOfWeek.values[itemData.alarmDay!],
              time: TimeOfDay(hour: itemData.alarmHour!, minute: itemData.alarmMinute!),
            )
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(itemData.createdAt),
    );

    final updated = item.copyWith(completed: !item.completed);
    await _db.updateTodoItem(TodoItemsData(
      id: updated.id,
      listId: updated.listId,
      title: updated.title,
      completed: updated.completed ? 1 : 0,
      colorHex: updated.color.toARGB32(),
      alarmDay: updated.alarm?.day.index,
      alarmHour: updated.alarm?.time.hour,
      alarmMinute: updated.alarm?.time.minute,
      createdAt: updated.createdAt.millisecondsSinceEpoch,
    ));
    if (item.completed) {
      await _alarm.cancelAlarm(itemId);
    }
  }

  Future<void> deleteItem(String itemId) async {
    await _alarm.cancelAlarm(itemId);
    await _db.deleteTodoItem(itemId);
  }

  /// Cancel the alarm for the given item.
  Future<void> cancelAlarm(String itemId) async {
    await _alarm.cancelAlarm(itemId);
  }

  /// Schedule an alarm for the given item.
  Future<void> scheduleAlarm(TodoItem item) async {
    await _alarm.scheduleAlarm(item);
  }

  Future<void> reRegisterAllAlarms() async {
    final pending = await _db.getPendingAlarms();
    for (final itemData in pending) {
      // Skip completed items — their alarms should not be re-registered.
      if (itemData.completed == 1) continue;

      final item = TodoItem(
        id: itemData.id,
        listId: itemData.listId,
        title: itemData.title,
        completed: itemData.completed == 1,
        color: Color(itemData.colorHex),
        alarm: AlarmInfo(
          day: DayOfWeek.values[itemData.alarmDay!],
          time: TimeOfDay(hour: itemData.alarmHour!, minute: itemData.alarmMinute!),
        ),
        createdAt: DateTime.fromMillisecondsSinceEpoch(itemData.createdAt),
      );
      await _alarm.scheduleAlarm(item);
    }
  }
}
