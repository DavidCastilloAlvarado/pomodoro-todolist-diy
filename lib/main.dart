import 'package:birdle/app.dart';
import 'package:birdle/data/services/alarm_service.dart';
import 'package:birdle/data/services/database.dart';
import 'package:birdle/data/services/notification_service.dart';
import 'package:birdle/data/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef StorageInitializer = Future<void> Function();
typedef PreferredOrientationsSetter =
    Future<void> Function(List<DeviceOrientation> orientations);
typedef AppRunner = void Function(Widget app);

Future<Widget> bootstrapBirdleApp({
  StorageInitializer? storageInitializer,
  PreferredOrientationsSetter? preferredOrientationsSetter,
  NotificationService? notificationService,
  BirdleDatabase Function()? databaseFactory,
  AlarmService? alarmService,
  AppRunner? appRunner,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('Birdle bootstrap: start');

  await (preferredOrientationsSetter ?? SystemChrome.setPreferredOrientations)([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await (storageInitializer ??
      () async {
        final storage = StorageService();
        await storage.init();
      })();
  debugPrint('Birdle bootstrap: storage initialized');

  // Initialize notification service early so alarms can use it
  final resolvedNotificationService =
      notificationService ?? NotificationService();
  try {
    debugPrint('Birdle bootstrap: initializing notification service');
    await resolvedNotificationService.init();

    // Request notification permission on Android 13+
    final notificationsGranted = await resolvedNotificationService
        .requestNotificationPermission();
    if (!notificationsGranted) {
      debugPrint(
        'NotificationService: Notifications remain disabled after startup permission request',
      );
    }

    // Request exact alarm permission on Android 12+
    final exactAlarmAlreadyEnabled = await resolvedNotificationService
        .canScheduleExactAlarms();
    final exactAlarmOk = exactAlarmAlreadyEnabled
        ? true
        : await resolvedNotificationService.requestExactAlarmPermission();
    if (!exactAlarmOk) {
      debugPrint(
        'NotificationService: Could not grant exact alarm permission — alarms may not fire reliably',
      );
    }

    await resolvedNotificationService.logEnvironmentDiagnostics(
      context: 'startup-before-alarm-reregistration',
    );
    await resolvedNotificationService.logPendingNotificationRequests(
      context: 'startup-before-alarm-reregistration',
    );
  } catch (error, stackTrace) {
    debugPrint(
      'NotificationService: Startup initialization failed, continuing app startup: $error',
    );
    debugPrintStack(
      label: 'NotificationService startup failure',
      stackTrace: stackTrace,
    );
  }

  BirdleDatabase? database;
  String? dbError;
  try {
    database = (databaseFactory ?? BirdleDatabase.new)();
    await database.open();
    debugPrint('Birdle bootstrap: database opened');

    // Initialize alarm service and re-register all alarms from DB
    final resolvedAlarmService = alarmService ?? AlarmService();
    resolvedAlarmService.init(database: database);
    debugPrint('Birdle bootstrap: re-registering persisted alarms');
    await resolvedAlarmService.initAlarmManager();
    await resolvedNotificationService.logEnvironmentDiagnostics(
      context: 'startup-after-alarm-reregistration',
    );
    await resolvedNotificationService.logPendingNotificationRequests(
      context: 'startup-after-alarm-reregistration',
    );
  } catch (e, stack) {
    dbError = '$e\n$stack';
    debugPrint('Failed to initialize database: $dbError');
  }

  final app = App(database: database, dbError: dbError);
  if (appRunner != null) {
    appRunner(app);
  } else {
    runApp(app);
  }

  debugPrint('Birdle bootstrap: app launched');

  return app;
}

Future<void> main() async {
  await bootstrapBirdleApp();
}
