import 'dart:async';
import 'package:birdle/data/models/pomodoro_session.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class ForegroundTaskService {
  static final ForegroundTaskService _instance = ForegroundTaskService._internal();
  ForegroundTaskService._internal();

  factory ForegroundTaskService() => _instance;

  Timer? _timer;
  final StreamController<int> _remainingStream = StreamController<int>.broadcast();
  PomodoroSession? _currentSession;

  // ── Static data passed to the foreground callback isolate ──
  // The callback runs in a separate isolate, so we can't pass
  // data via FlutterForegroundTask.initialData (which doesn't
  // exist on this plugin version). Instead we use static fields
  // that the callback reads directly.
  static int? _callbackRemaining;
  static String? _callbackItemTitle;

  Stream<int> get remainingSecondsStream => _remainingStream.stream;

  Future<void> startPomodoroTask(PomodoroSession session) async {
    _currentSession = session;

    // Store session data for the foreground callback isolate
    _callbackRemaining = session.remaining.inSeconds;
    _callbackItemTitle = session.itemTitle;

    await FlutterForegroundTask.startService(
      notificationTitle: 'Pomodoro',
      notificationText: _formatRemaining(session.remaining),
      callback: pomodoroTaskCallback,
    );

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_currentSession != null && _currentSession!.status == PomodoroStatus.running) {
        final remaining = _currentSession!.remaining - const Duration(seconds: 1);
        _currentSession = _currentSession!.copyWith(remaining: remaining);
        _remainingStream.add(remaining.inSeconds);

        if (remaining.inSeconds <= 0) {
          stopPomodoroTask();
        }
      }
    });
  }

  Future<void> stopPomodoroTask() async {
    _timer?.cancel();
    _timer = null;
    await FlutterForegroundTask.stopService();
  }

  String _formatRemaining(Duration duration) {
    final mins = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }
}

/// Background callback for the foreground task.
/// Runs in a separate isolate — must be @pragma('vm:entry-point')
/// annotated so the Dart AOT compiler keeps it.
///
/// Implements the countdown timer so the pomodoro survives the app
/// being killed/swiped away. Each second it updates the notification
/// via FlutterForegroundTask.updateService(). On completion it stops
/// the service and shows a completion notification (which uses the
/// alarm notification channel configured in NotificationService with
/// playSound:true and enableVibration:true).
@pragma('vm:entry-point')
void pomodoroTaskCallback(FlutterForegroundTask task) {
  // Read session data from the static fields set by startPomodoroTask()
  final int initialRemaining = ForegroundTaskService._callbackRemaining ?? 0;
  final String itemTitle = ForegroundTaskService._callbackItemTitle ?? 'Unknown';

  // Use a mutable counter (not final) so we can decrement it
  int remaining = initialRemaining;

  Timer.periodic(const Duration(seconds: 1), (timer) {
    if (remaining <= 0) {
      timer.cancel();
      FlutterForegroundTask.updateService(
        notificationTitle: 'Pomodoro Complete!',
        notificationText: 'Session for $itemTitle is done.',
      );
      // Notify the main isolate so it can play sound + vibrate
      // if the app is still running.
      FlutterForegroundTask.sendDataToMain({
        'type': 'pomodoro_complete',
        'itemTitle': itemTitle,
      });
      FlutterForegroundTask.stopService();
    } else {
      remaining--;
      FlutterForegroundTask.updateService(
        notificationTitle: 'Pomodoro',
        notificationText: _formatRemaining(Duration(seconds: remaining)),
      );
    }
  });
}

String _formatRemaining(Duration duration) {
  final mins = duration.inMinutes.remainder(60);
  final secs = duration.inSeconds.remainder(60);
  return '$mins:${secs.toString().padLeft(2, '0')}';
}
