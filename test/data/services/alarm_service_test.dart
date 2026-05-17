import 'package:birdle/data/models/todo_item.dart';
import 'package:birdle/data/services/alarm_service.dart';
import 'package:birdle/data/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;

NotificationScheduleDiagnostics _buildTestDiagnostics({
  required int id,
  required String title,
  required String body,
  DateTime? requestedLocalTime,
  tz.TZDateTime? requestedZonedTime,
}) {
  final localTime = requestedLocalTime ?? DateTime(2024, 1, 1, 1, 56);
  final zonedTime = requestedZonedTime ?? tz.TZDateTime.utc(2024, 1, 1, 1, 56);

  return NotificationScheduleDiagnostics(
    notificationId: id,
    title: title,
    body: body,
    scheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    requestedLocalTime: localTime,
    requestedZonedTime: zonedTime,
    notificationsEnabled: true,
    exactAlarmsEnabled: true,
    timezoneName: zonedTime.location.name,
    localTimezoneOffset: zonedTime.timeZoneOffset,
    pendingRequestCount: 1,
    appearsInPendingRequests: true,
    matchingPendingRequest: PendingNotificationRequest(id, title, body, ''),
    alarmChannel: const NotificationChannelDiagnostics(
      id: NotificationService.alarmChannelId,
      name: NotificationService.alarmChannelName,
      description: NotificationService.alarmChannelDescription,
      importance: NotificationService.alarmChannelImportance,
      playSound: true,
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    ),
  );
}

class FakeNotificationService extends NotificationService {
  FakeNotificationService()
    : super.test(localTimezoneIdentifierProvider: () async => 'America/Lima');

  DateTime? capturedScheduledTime;
  DateTime? capturedDailyFirstOccurrence;
  TimeOfDay? capturedDailyTime;

  @override
  Future<void> init() async {}

  @override
  Future<void> logPendingNotificationRequests({required String context}) async {}

  @override
  Future<NotificationScheduleDiagnostics> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    capturedScheduledTime = scheduledTime;
    return _buildTestDiagnostics(
      id: id,
      title: title,
      body: body,
      requestedLocalTime: scheduledTime,
    );
  }

  @override
  Future<NotificationScheduleDiagnostics> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    DateTime? firstOccurrence,
  }) async {
    capturedDailyTime = time;
    capturedDailyFirstOccurrence = firstOccurrence;
    return _buildTestDiagnostics(
      id: id,
      title: title,
      body: body,
      requestedLocalTime: firstOccurrence,
    );
  }
}

TodoItem buildItem({required DayOfWeek day, required TimeOfDay time}) {
  return TodoItem(
    id: 'item-1',
    listId: 'list-1',
    title: 'Alarm item',
    color: Colors.blue,
    alarm: AlarmInfo(day: day, time: time),
    createdAt: DateTime(2024, 1, 1),
  );
}

void main() {
  group('NotificationService timezone initialization', () {
    test('uses the device timezone for Peru local scheduling', () async {
      final service = NotificationService.test(
        localTimezoneIdentifierProvider: () async => 'America/Lima',
      );

      await service.initializeLocalTimezone();

      final scheduled = service.createWallClockSchedule(
        DateTime(2024, 1, 1, 1, 56),
      );
      final now = tz.TZDateTime(tz.local, 2024, 1, 1, 0, 54);

      expect(tz.local.name, 'America/Lima');
      expect(scheduled.location.name, 'America/Lima');
      expect(scheduled.timeZoneOffset, const Duration(hours: -5));
      expect(scheduled.isAfter(now), isTrue);
    });

    test(
      'falls back to a fixed-offset local timezone when plugin lookup fails',
      () async {
        final fallbackLocation = tz.Location(
          'Birdle/TestFallback',
          const <int>[],
          const <int>[],
          const <tz.TimeZone>[
            tz.TimeZone(
              -5 * Duration.millisecondsPerHour,
              isDst: false,
              abbreviation: 'PET',
            ),
          ],
        );
        final service = NotificationService.test(
          localTimezoneIdentifierProvider: () async {
            throw MissingPluginException(
              'No implementation found for method getLocalTimezone on channel flutter_timezone',
            );
          },
          fallbackTimezoneLocationProvider: (_) => fallbackLocation,
        );

        await expectLater(service.initializeLocalTimezone(), completes);

        final scheduled = service.createWallClockSchedule(
          DateTime(2024, 1, 1, 1, 56),
        );

        expect(tz.local.name, 'Birdle/TestFallback');
        expect(scheduled.location.name, 'Birdle/TestFallback');
        expect(scheduled.timeZoneOffset, const Duration(hours: -5));
        expect(scheduled.hour, 1);
        expect(scheduled.minute, 56);
      },
    );

    test('falls back to system time when the now provider returns null', () {
      final service = NotificationService.test(nowProvider: () => null);

      final nextOccurrence = service.computeNextDailyOccurrence(
        const TimeOfDay(hour: 23, minute: 59),
      );

      expect(nextOccurrence.hour, 23);
      expect(nextOccurrence.minute, 59);
    });
  });

  group('AlarmService.scheduleAlarm', () {
    test(
      'schedules the Peru 01:56 local weekday alarm as a future local time',
      () async {
        final notificationService = FakeNotificationService();
        final service = AlarmService.test(
          notificationService: notificationService,
          nowProvider: () => DateTime(2024, 1, 1, 0, 54),
        );

        await service.scheduleAlarm(
          buildItem(
            day: DayOfWeek.monday,
            time: const TimeOfDay(hour: 1, minute: 56),
          ),
        );

        expect(
          notificationService.capturedScheduledTime,
          DateTime(2024, 1, 1, 1, 56),
        );
      },
    );

    test(
      'falls back to system time when the now provider returns null',
      () async {
        final notificationService = FakeNotificationService();
        final service = AlarmService.test(
          notificationService: notificationService,
          nowProvider: () => null,
        );

        await expectLater(
          service.scheduleAlarm(
            buildItem(
              day: DayOfWeek.everyDay,
              time: const TimeOfDay(hour: 23, minute: 59),
            ),
          ),
          completes,
        );

        expect(
          notificationService.capturedDailyTime,
          const TimeOfDay(hour: 23, minute: 59),
        );
        expect(notificationService.capturedDailyFirstOccurrence, isNotNull);
      },
    );

    test(
      'rolls same-day weekday alarms that already passed to next week',
      () async {
        final notificationService = FakeNotificationService();
        final service = AlarmService.test(
          notificationService: notificationService,
          nowProvider: () => DateTime(2024, 1, 1, 2, 0),
        );

        await service.scheduleAlarm(
          buildItem(
            day: DayOfWeek.monday,
            time: const TimeOfDay(hour: 1, minute: 56),
          ),
        );

        expect(
          notificationService.capturedScheduledTime,
          DateTime(2024, 1, 8, 1, 56),
        );
      },
    );

    test('keeps weekday alarms on the next matching weekday', () {
      final service = AlarmService.test(
        notificationService: FakeNotificationService(),
        nowProvider: () => DateTime(2024, 1, 3, 9, 0),
      );

      final nextOccurrence = service.computeNextLocalOccurrence(
        const AlarmInfo(
          day: DayOfWeek.monday,
          time: TimeOfDay(hour: 1, minute: 56),
        ),
      );

      expect(nextOccurrence, DateTime(2024, 1, 8, 1, 56));
    });

    test('factory singleton resolves a default now provider', () {
      final service = AlarmService();

      final nextOccurrence = service.computeNextLocalOccurrence(
        const AlarmInfo(
          day: DayOfWeek.everyDay,
          time: TimeOfDay(hour: 23, minute: 59),
        ),
      );

      expect(nextOccurrence.hour, 23);
      expect(nextOccurrence.minute, 59);
    });

    test(
      'keeps daily alarms on the same local wall-clock time tomorrow when today passed',
      () async {
        final notificationService = FakeNotificationService();
        final service = AlarmService.test(
          notificationService: notificationService,
          nowProvider: () => DateTime(2024, 1, 1, 2, 0),
        );

        await service.scheduleAlarm(
          buildItem(
            day: DayOfWeek.everyDay,
            time: const TimeOfDay(hour: 1, minute: 56),
          ),
        );

        expect(
          notificationService.capturedDailyTime,
          const TimeOfDay(hour: 1, minute: 56),
        );
        expect(
          notificationService.capturedDailyFirstOccurrence,
          DateTime(2024, 1, 2, 1, 56),
        );
      },
    );
  });
}
