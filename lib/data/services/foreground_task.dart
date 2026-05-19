import 'dart:async';
import 'package:birdle/data/models/pomodoro_session.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Service that manages the foreground task for the Pomodoro timer.
/// Tracks the current phase alongside remaining seconds so the
/// notification title updates correctly on phase transitions.
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
  static int? _callbackCurrentPhase;
  static int? _callbackCompletedSessions;
  static int? _callbackWorkDuration;
  static int? _callbackBreakDuration;
  static int? _callbackLongBreakDuration;

  Stream<int> get remainingSecondsStream => _remainingStream.stream;

  Future<void> startPomodoroTask(PomodoroSession session) async {
    _currentSession = session;

    // Store session data for the foreground callback isolate
    _callbackRemaining = session.remaining.inSeconds;
    _callbackItemTitle = session.itemTitle;
    _callbackCurrentPhase = session.currentPhase;
    _callbackCompletedSessions = session.completedSessions;
    // Defaults in case config is not yet loaded
    _callbackWorkDuration = session.durationMinutes * 60;
    _callbackBreakDuration = 5 * 60;
    _callbackLongBreakDuration = 15 * 60;

    final phaseLabel = _phaseLabel(session.currentPhase);

    await FlutterForegroundTask.startService(
      notificationTitle: phaseLabel,
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

  String _phaseLabel(int phaseIndex) {
    switch (PomodoroPhase.values[phaseIndex]) {
      case PomodoroPhase.work:
        return 'Work';
      case PomodoroPhase.shortBreak:
        return 'Short Break';
      case PomodoroPhase.longBreak:
        return 'Long Break';
    }
  }
}

/// Background callback for the foreground task.
/// Runs in a separate isolate — must be @pragma('vm:entry-point')
/// annotated so the Dart AOT compiler keeps it.
///
/// Implements the countdown timer so the pomodoro survives the app
/// being killed/swiped away. Each second it updates the notification
/// via FlutterForegroundTask.updateService(). On completion it handles
/// phase transitions, updates the notification title, and fires
/// `sendDataToMain` with `type: 'pomodoro_complete'`.
@pragma('vm:entry-point')
void pomodoroTaskCallback(FlutterForegroundTask task) {
  // Read session data from the static fields set by startPomodoroTask()
  final int initialRemaining = ForegroundTaskService._callbackRemaining ?? 0;
  final String itemTitle = ForegroundTaskService._callbackItemTitle ?? 'Unknown';
  int currentPhase = ForegroundTaskService._callbackCurrentPhase ?? 0;
  int completedSessions = ForegroundTaskService._callbackCompletedSessions ?? 0;

  // Use a mutable counter (not final) so we can decrement it
  int remaining = initialRemaining;

  Timer.periodic(const Duration(seconds: 1), (timer) {
    if (remaining <= 0) {
      // Phase completed — handle transition
      switch (PomodoroPhase.values[currentPhase]) {
        case PomodoroPhase.work:
          completedSessions++;
          if (completedSessions < 4) {
            currentPhase = PomodoroPhase.shortBreak.index;
          } else {
            currentPhase = PomodoroPhase.longBreak.index;
          }
          break;

        case PomodoroPhase.shortBreak:
          currentPhase = PomodoroPhase.work.index;
          break;

        case PomodoroPhase.longBreak:
          completedSessions = 0;
          currentPhase = PomodoroPhase.work.index;
          break;
      }

      // Reset remaining to the new phase's duration so the countdown
      // continues and pomodoro_complete fires only once.
      int newPhaseDuration;
      switch (PomodoroPhase.values[currentPhase]) {
        case PomodoroPhase.work:
          newPhaseDuration = ForegroundTaskService._callbackWorkDuration ?? 25 * 60;
          break;
        case PomodoroPhase.shortBreak:
          newPhaseDuration = ForegroundTaskService._callbackBreakDuration ?? 5 * 60;
          break;
        case PomodoroPhase.longBreak:
          newPhaseDuration = ForegroundTaskService._callbackLongBreakDuration ?? 15 * 60;
          break;
      }
      remaining = newPhaseDuration;

      // Update notification with new phase title and countdown
      FlutterForegroundTask.updateService(
        notificationTitle: _phaseLabel(currentPhase),
        notificationText: _formatRemaining(Duration(seconds: remaining)),
      );

      // Notify the main isolate so it can play sound + vibrate
      // if the app is still running.
      FlutterForegroundTask.sendDataToMain({
        'type': 'pomodoro_complete',
        'itemTitle': itemTitle,
      });
    } else {
      remaining--;
      FlutterForegroundTask.updateService(
        notificationTitle: _phaseLabel(currentPhase),
        notificationText: _formatRemaining(Duration(seconds: remaining)),
      );
    }
  });
}

String _phaseLabel(int phaseIndex) {
  switch (PomodoroPhase.values[phaseIndex]) {
    case PomodoroPhase.work:
      return 'Work';
    case PomodoroPhase.shortBreak:
      return 'Short Break';
    case PomodoroPhase.longBreak:
      return 'Long Break';
  }
}

String _formatRemaining(Duration duration) {
  final mins = duration.inMinutes.remainder(60);
  final secs = duration.inSeconds.remainder(60);
  return '$mins:${secs.toString().padLeft(2, '0')}';
}
