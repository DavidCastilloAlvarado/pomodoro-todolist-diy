import 'package:birdle/app.dart';
import 'package:birdle/data/models/todo_item.dart';
import 'package:birdle/data/services/alarm_service.dart';
import 'package:birdle/data/services/database.dart';
import 'package:birdle/data/services/notification_service.dart';
import 'package:birdle/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;

class StartupFallbackNotificationService extends NotificationService {
  StartupFallbackNotificationService()
    : super.test(
        localTimezoneIdentifierProvider: () async {
          throw MissingPluginException(
            'No implementation found for method getLocalTimezone on channel flutter_timezone',
          );
        },
        fallbackTimezoneLocationProvider: (_) => tz.Location(
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
        ),
      );

  bool initCalled = false;
  DateTime? capturedScheduledTime;
  tz.TZDateTime? capturedWallClockSchedule;

  @override
  Future<void> init() async {
    initCalled = true;
    await initializeLocalTimezone();
  }

  @override
  Future<bool> requestNotificationPermission() async => true;

  @override
  Future<bool> requestExactAlarmPermission() async => true;

  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    capturedScheduledTime = scheduledTime;
    capturedWallClockSchedule = createWallClockSchedule(scheduledTime);
  }
}

class FakeStartupAlarmService extends AlarmService {
  FakeStartupAlarmService({required NotificationService service})
    : super.test(
        notificationService: service,
        nowProvider: () => DateTime(2024, 1, 1, 0, 54),
      );

  BirdleDatabase? initializedDatabase;
  bool initAlarmManagerCalled = false;

  @override
  void init({required BirdleDatabase database}) {
    initializedDatabase = database;
  }

  @override
  Future<void> initAlarmManager() async {
    initAlarmManagerCalled = true;
  }
}

class FakeBirdleDatabase extends BirdleDatabase {
  bool opened = false;

  @override
  Future<void> open() async {
    opened = true;
  }
}

TodoItem _buildAlarmItem() {
  return TodoItem(
    id: 'item-startup',
    listId: 'list-1',
    title: 'Startup alarm',
    color: Colors.blue,
    alarm: const AlarmInfo(
      day: DayOfWeek.monday,
      time: TimeOfDay(hour: 1, minute: 56),
    ),
    createdAt: DateTime(2024, 1, 1),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'bootstrapBirdleApp survives timezone plugin startup failure and preserves local wall-clock scheduling',
    () async {
      final notificationService = StartupFallbackNotificationService();
      final alarmService = FakeStartupAlarmService(
        service: notificationService,
      );
      final database = FakeBirdleDatabase();
      Widget? renderedApp;

      await expectLater(
        bootstrapBirdleApp(
          storageInitializer: () async {},
          preferredOrientationsSetter: (_) async {},
          notificationService: notificationService,
          databaseFactory: () => database,
          alarmService: alarmService,
          appRunner: (app) => renderedApp = app,
        ),
        completes,
      );

      expect(notificationService.initCalled, isTrue);
      expect(database.opened, isTrue);
      expect(alarmService.initializedDatabase, same(database));
      expect(alarmService.initAlarmManagerCalled, isTrue);
      expect(renderedApp, isA<App>());
      expect(tz.local.name, 'Birdle/TestFallback');

      await alarmService.scheduleAlarm(_buildAlarmItem());

      expect(
        notificationService.capturedScheduledTime,
        DateTime(2024, 1, 1, 1, 56),
      );
      expect(
        notificationService.capturedWallClockSchedule?.location.name,
        'Birdle/TestFallback',
      );
      expect(
        notificationService.capturedWallClockSchedule?.timeZoneOffset,
        const Duration(hours: -5),
      );
      expect(notificationService.capturedWallClockSchedule?.hour, 1);
      expect(notificationService.capturedWallClockSchedule?.minute, 56);
    },
  );
}
