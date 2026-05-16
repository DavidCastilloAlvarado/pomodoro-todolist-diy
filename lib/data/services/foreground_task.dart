import 'dart:async';
import 'package:birdle/data/models/pomodoro_session.dart';
import 'package:birdle/data/services/notification_service.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class ForegroundTaskService {
  static final ForegroundTaskService _instance = ForegroundTaskService._internal();
  ForegroundTaskService._internal();

  factory ForegroundTaskService() => _instance;

  final NotificationService _notificationService = NotificationService();
  Timer? _timer;
  final StreamController<int> _remainingStream = StreamController<int>.broadcast();
  PomodoroSession? _currentSession;

  Stream<int> get remainingSecondsStream => _remainingStream.stream;

  Future<void> startPomodoroTask(PomodoroSession session) async {
    _currentSession = session;

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
        _updateNotification(_currentSession!.itemTitle, remaining.inSeconds);

        if (remaining.inSeconds <= 0) {
          stopPomodoroTask();
          _notificationService.showNotification(
            'Pomodoro Complete!',
            'Session for ${_currentSession!.itemTitle} is done.',
          );
        }
      }
    });
  }

  Future<void> stopPomodoroTask() async {
    _timer?.cancel();
    _timer = null;
    await FlutterForegroundTask.stopService();
  }

  Future<void> _updateNotification(String title, int remaining) async {
    await _notificationService.showNotification(
      title,
      _formatRemaining(Duration(seconds: remaining)),
    );
  }

  String _formatRemaining(Duration duration) {
    final mins = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }
}

@pragma('vm:entry-point')
void pomodoroTaskCallback(FlutterForegroundTask task) {
  // Background callback for foreground task
}
