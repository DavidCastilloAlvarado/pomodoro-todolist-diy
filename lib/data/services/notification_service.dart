import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationChannelDiagnostics {
  const NotificationChannelDiagnostics({
    required this.id,
    required this.name,
    required this.description,
    required this.importance,
    required this.playSound,
    required this.enableVibration,
    required this.audioAttributesUsage,
  });

  factory NotificationChannelDiagnostics.fromChannel(
    AndroidNotificationChannel channel,
  ) {
    return NotificationChannelDiagnostics(
      id: channel.id,
      name: channel.name,
      description: channel.description,
      importance: channel.importance,
      playSound: channel.playSound,
      enableVibration: channel.enableVibration,
      audioAttributesUsage: channel.audioAttributesUsage,
    );
  }

  final String id;
  final String name;
  final String? description;
  final Importance importance;
  final bool playSound;
  final bool enableVibration;
  final AudioAttributesUsage audioAttributesUsage;

  String toLogString() {
    return 'id=$id, name="$name", importance=${importance.name}, '
        'playSound=$playSound, enableVibration=$enableVibration, '
        'audioUsage=${audioAttributesUsage.name}, '
        'description="${description ?? ''}"';
  }
}

class NotificationEnvironmentDiagnostics {
  const NotificationEnvironmentDiagnostics({
    required this.notificationsEnabled,
    required this.exactAlarmsEnabled,
    required this.timezoneName,
    required this.localTimezoneOffset,
    required this.alarmChannel,
  });

  final bool notificationsEnabled;
  final bool exactAlarmsEnabled;
  final String timezoneName;
  final Duration localTimezoneOffset;
  final NotificationChannelDiagnostics? alarmChannel;

  String toLogString() {
    return 'notificationsEnabled=$notificationsEnabled, '
        'exactAlarmsEnabled=$exactAlarmsEnabled, '
        'timezone=$timezoneName (${NotificationService.formatTimezoneOffset(localTimezoneOffset)}), '
        'alarmChannel=${alarmChannel?.toLogString() ?? 'missing'}';
  }
}

class NotificationScheduleDiagnostics {
  const NotificationScheduleDiagnostics({
    required this.notificationId,
    required this.title,
    required this.body,
    required this.scheduleMode,
    required this.requestedLocalTime,
    required this.requestedZonedTime,
    required this.notificationsEnabled,
    required this.exactAlarmsEnabled,
    required this.timezoneName,
    required this.localTimezoneOffset,
    required this.pendingRequestCount,
    required this.appearsInPendingRequests,
    required this.matchingPendingRequest,
    required this.alarmChannel,
  });

  final int notificationId;
  final String title;
  final String body;
  final AndroidScheduleMode scheduleMode;
  final DateTime requestedLocalTime;
  final tz.TZDateTime requestedZonedTime;
  final bool notificationsEnabled;
  final bool exactAlarmsEnabled;
  final String timezoneName;
  final Duration localTimezoneOffset;
  final int pendingRequestCount;
  final bool appearsInPendingRequests;
  final PendingNotificationRequest? matchingPendingRequest;
  final NotificationChannelDiagnostics? alarmChannel;

  String toLogString() {
    return 'id=$notificationId, title="$title", body="$body", '
        'scheduleMode=${scheduleMode.name}, '
        'requestedLocalTime=$requestedLocalTime, '
        'requestedZonedTime=$requestedZonedTime, '
        'timezone=$timezoneName (${NotificationService.formatTimezoneOffset(localTimezoneOffset)}), '
        'notificationsEnabled=$notificationsEnabled, '
        'exactAlarmsEnabled=$exactAlarmsEnabled, '
        'pendingRequestCount=$pendingRequestCount, '
        'appearsInPendingRequests=$appearsInPendingRequests, '
        'pendingMatchTitle="${matchingPendingRequest?.title ?? ''}", '
        'pendingMatchBody="${matchingPendingRequest?.body ?? ''}", '
        'alarmChannel=${alarmChannel?.toLogString() ?? 'missing'}';
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static const String alarmChannelId = 'birdle_alarms';
  static const String alarmChannelName = 'Birdle Alarms';
  static const String alarmChannelDescription =
      'Notifications for todo item alarms and pomodoro timers';
  // Packaged as the Android small-notification icon resource.
  static const String alarmNotificationIcon = 'ic_stat_birdle';
  static const Importance alarmChannelImportance = Importance.max;
  static const Priority alarmNotificationPriority = Priority.max;

  static DateTime _systemNow() => DateTime.now();

  static DateTime? Function() _resolveNowProvider(
    DateTime? Function()? nowProvider,
  ) {
    return nowProvider ?? _systemNow;
  }

  static String formatTimezoneOffset(Duration offset) {
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
    final formattedOffset = formatTimezoneOffset(offset);
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

  AndroidFlutterLocalNotificationsPlugin? get _androidPlugin => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

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

    const android = AndroidInitializationSettings(alarmNotificationIcon);
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(settings);

    final androidPlugin = _androidPlugin;
    await androidPlugin?.createNotificationChannel(_buildAlarmChannel());

    debugPrint(
      'NotificationService: Initialized Android notifications with '
      'defaultIcon=$alarmNotificationIcon, timezone=${tz.local.name}',
    );
    await logEnvironmentDiagnostics(context: 'init-complete');
    await logPendingNotificationRequests(context: 'init-complete');

    _initialized = true;
  }

  AndroidNotificationChannel _buildAlarmChannel() {
    return const AndroidNotificationChannel(
      alarmChannelId,
      alarmChannelName,
      description: alarmChannelDescription,
      importance: alarmChannelImportance,
      playSound: true,
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );
  }

  AndroidNotificationDetails _buildAlarmNotificationDetails() {
    return const AndroidNotificationDetails(
      alarmChannelId,
      alarmChannelName,
      channelDescription: alarmChannelDescription,
      importance: alarmChannelImportance,
      priority: alarmNotificationPriority,
      channelAction: AndroidNotificationChannelAction.createIfNotExists,
      category: AndroidNotificationCategory.alarm,
      playSound: true,
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      showWhen: false,
      visibility: NotificationVisibility.public,
    );
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

    final android = _buildAlarmNotificationDetails();
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
  Future<NotificationScheduleDiagnostics> scheduleNotification({
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

    final android = _buildAlarmNotificationDetails();
    final settings = NotificationDetails(android: android);

    await zonedScheduleNotification(
      id,
      title,
      body,
      tzScheduledTime,
      settings,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      androidScheduleMode: scheduleMode,
    );

    final diagnostics = await _collectScheduleDiagnostics(
      id: id,
      title: title,
      body: body,
      scheduleMode: scheduleMode,
      requestedLocalTime: scheduledTime,
      requestedZonedTime: tzScheduledTime,
    );

    debugPrint(
      'NotificationService: Notification scheduled successfully id=$id',
    );
    debugPrint(
      'NotificationService: Delivery diagnostics -> ${diagnostics.toLogString()}',
    );

    if (!diagnostics.appearsInPendingRequests) {
      debugPrint(
        'NotificationService: WARNING scheduled notification id=$id was not found '
        'in pendingNotificationRequests() after scheduling.',
      );
    }

    return diagnostics;
  }

  /// Schedule a daily recurring notification at the given time.
  Future<NotificationScheduleDiagnostics> scheduleDailyNotification({
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

    final android = _buildAlarmNotificationDetails();
    final settings = NotificationDetails(android: android);

    await zonedScheduleNotification(
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

    final diagnostics = await _collectScheduleDiagnostics(
      id: id,
      title: title,
      body: body,
      scheduleMode: scheduleMode,
      requestedLocalTime: nextOccurrence,
      requestedZonedTime: tzScheduledTime,
    );

    debugPrint(
      'NotificationService: Notification scheduled successfully id=$id',
    );
    debugPrint(
      'NotificationService: Delivery diagnostics -> ${diagnostics.toLogString()}',
    );

    if (!diagnostics.appearsInPendingRequests) {
      debugPrint(
        'NotificationService: WARNING scheduled daily notification id=$id was not '
        'found in pendingNotificationRequests() after scheduling.',
      );
    }

    return diagnostics;
  }

  /// Request notification permission on Android 13+.
  Future<bool> requestNotificationPermission() async {
    final result = await _androidPlugin?.requestNotificationsPermission();
    final granted = result ?? true;
    debugPrint(
      'NotificationService: Notification permission request result -> '
      '$granted',
    );
    return granted;
  }

  Future<bool> areNotificationsEnabled() async {
    final result = await _androidPlugin?.areNotificationsEnabled();
    return result ?? true;
  }

  /// Check whether the device supports exact alarms.
  Future<bool> canScheduleExactAlarms() async {
    final result = await _androidPlugin?.canScheduleExactNotifications();
    return result ?? true;
  }

  /// Request the SCHEDULE_EXACT_ALARM runtime permission.
  Future<bool> requestExactAlarmPermission() async {
    final androidPlugin = _androidPlugin;
    final alreadyEnabled = await androidPlugin?.canScheduleExactNotifications();
    if (alreadyEnabled ?? false) {
      debugPrint(
        'NotificationService: Exact alarm permission already enabled before request',
      );
      return true;
    }

    final result = await androidPlugin?.requestExactAlarmsPermission();
    final granted = result ?? true;
    debugPrint(
      'NotificationService: Exact alarm permission request result -> $granted',
    );
    return granted;
  }

  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async {
    return _plugin.pendingNotificationRequests();
  }

  Future<List<AndroidNotificationChannel>> getNotificationChannels() async {
    final channels = await _androidPlugin?.getNotificationChannels();
    return channels ?? const <AndroidNotificationChannel>[];
  }

  Future<NotificationEnvironmentDiagnostics>
  collectEnvironmentDiagnostics() async {
    final currentLocalTime = tz.TZDateTime.from(_resolveNow(), tz.local);
    NotificationChannelDiagnostics? alarmChannel;

    for (final channel in await getNotificationChannels()) {
      if (channel.id == alarmChannelId) {
        alarmChannel = NotificationChannelDiagnostics.fromChannel(channel);
        break;
      }
    }

    return NotificationEnvironmentDiagnostics(
      notificationsEnabled: await areNotificationsEnabled(),
      exactAlarmsEnabled: await canScheduleExactAlarms(),
      timezoneName: tz.local.name,
      localTimezoneOffset: currentLocalTime.timeZoneOffset,
      alarmChannel: alarmChannel,
    );
  }

  Future<void> logEnvironmentDiagnostics({required String context}) async {
    final diagnostics = await collectEnvironmentDiagnostics();
    debugPrint('NotificationService[$context]: ${diagnostics.toLogString()}');
  }

  Future<void> logPendingNotificationRequests({required String context}) async {
    final pendingRequests = await pendingNotificationRequests();
    final summary = pendingRequests.isEmpty
        ? 'none'
        : pendingRequests
              .map(
                (request) =>
                    'id=${request.id}, title="${request.title ?? ''}", '
                    'body="${request.body ?? ''}"',
              )
              .join(' | ');
    debugPrint(
      'NotificationService[$context]: pendingNotificationRequests='
      '${pendingRequests.length} [$summary]',
    );
  }

  String buildManualVerificationGuide({
    required int notificationId,
    required String title,
    required DateTime scheduledTime,
    required AndroidScheduleMode scheduleMode,
  }) {
    final zonedTime = createWallClockSchedule(scheduledTime);
    return 'Manual Android alarm verification: '
        '1) schedule "$title" 1-2 minutes ahead; '
        '2) confirm Birdle logs show id=$notificationId, '
        'scheduleMode=${scheduleMode.name}, timezone=${tz.local.name}, '
        'scheduledLocal=$scheduledTime, scheduledZoned=$zonedTime, '
        'appearsInPendingRequests=true; '
        '3) press home or turn the screen off; '
        '4) wait until the due time; '
        '5) expect a visible Birdle notification on channel $alarmChannelId; '
        '6) if it does not appear, re-check the logged notification/exact-alarm '
        'permissions and OEM battery restrictions (https://dontkillmyapp.com).';
  }

  @protected
  Future<void> zonedScheduleNotification(
    int id,
    String title,
    String body,
    tz.TZDateTime scheduledTime,
    NotificationDetails details, {
    required UILocalNotificationDateInterpretation
    uiLocalNotificationDateInterpretation,
    DateTimeComponents? matchDateTimeComponents,
    required AndroidScheduleMode androidScheduleMode,
  }) {
    return _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      details,
      uiLocalNotificationDateInterpretation:
          uiLocalNotificationDateInterpretation,
      matchDateTimeComponents: matchDateTimeComponents,
      androidScheduleMode: androidScheduleMode,
    );
  }

  Future<NotificationScheduleDiagnostics> _collectScheduleDiagnostics({
    required int id,
    required String title,
    required String body,
    required AndroidScheduleMode scheduleMode,
    required DateTime requestedLocalTime,
    required tz.TZDateTime requestedZonedTime,
  }) async {
    final environment = await collectEnvironmentDiagnostics();
    final pendingRequests = await _waitForPendingNotificationRequest(
      id: id,
      title: title,
      body: body,
    );

    PendingNotificationRequest? matchingPendingRequest;
    for (final request in pendingRequests) {
      if (_isMatchingPendingRequest(
        request,
        id: id,
        title: title,
        body: body,
      )) {
        matchingPendingRequest = request;
        break;
      }
    }

    return NotificationScheduleDiagnostics(
      notificationId: id,
      title: title,
      body: body,
      scheduleMode: scheduleMode,
      requestedLocalTime: requestedLocalTime,
      requestedZonedTime: requestedZonedTime,
      notificationsEnabled: environment.notificationsEnabled,
      exactAlarmsEnabled: environment.exactAlarmsEnabled,
      timezoneName: environment.timezoneName,
      localTimezoneOffset: environment.localTimezoneOffset,
      pendingRequestCount: pendingRequests.length,
      appearsInPendingRequests: matchingPendingRequest != null,
      matchingPendingRequest: matchingPendingRequest,
      alarmChannel: environment.alarmChannel,
    );
  }

  Future<List<PendingNotificationRequest>> _waitForPendingNotificationRequest({
    required int id,
    required String title,
    required String body,
  }) async {
    List<PendingNotificationRequest> latestRequests =
        const <PendingNotificationRequest>[];

    for (var attempt = 1; attempt <= 5; attempt++) {
      latestRequests = await pendingNotificationRequests();
      final foundMatch = latestRequests.any(
        (request) => _isMatchingPendingRequest(
          request,
          id: id,
          title: title,
          body: body,
        ),
      );

      if (foundMatch) {
        return latestRequests;
      }

      if (attempt < 5) {
        await Future<void>.delayed(const Duration(milliseconds: 150));
      }
    }

    return latestRequests;
  }

  bool _isMatchingPendingRequest(
    PendingNotificationRequest request, {
    required int id,
    required String title,
    required String body,
  }) {
    return request.id == id && request.title == title && request.body == body;
  }

  /// Cancel a notification by its ID.
  Future<void> cancelById(int id) async {
    await _plugin.cancel(id);
  }
}
