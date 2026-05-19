import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:birdle/data/models/pomodoro_session.dart';
import 'package:birdle/data/repositories/pomodoro_repository.dart';
import 'package:birdle/data/services/foreground_task.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:birdle/ui/view_models/pomodoro_config_view_model.dart';
import 'package:uuid/uuid.dart';

/// Phase-based Pomodoro timer ViewModel.
/// Implements the classic Pomodoro technique:
/// Work (25 min) → Short Break (5 min) → repeat × 4 → Long Break (15 min) → repeat
class PomodoroViewModel extends ChangeNotifier {
  PomodoroViewModel({
    required PomodoroRepository repository,
    required PomodoroConfigViewModel config,
  }) : _repository = repository,
       _config = config {
    _initForegroundStream();
    _initForegroundTaskCallback();
    _initDefaults();
    // Listen for config changes so durations are always up-to-date
    _config.durationsValue.addListener(_onConfigChanged);
  }

  void _initDefaults() {
    _workRemaining = workDuration;
    _breakRemaining = breakDuration;
    _longBreakRemaining = longBreakDuration;
  }

  final PomodoroRepository _repository;
  final PomodoroConfigViewModel _config;
  Timer? _timer;
  StreamSubscription<int>? _foregroundSubscription;

  // ── Phase ────────────────────────────────────────────────────────

  PomodoroPhase _currentPhase = PomodoroPhase.work;
  PomodoroPhase get currentPhase => _currentPhase;

  int get workDuration => _config.workMinutes * 60;
  int get breakDuration => _config.breakMinutes * 60;
  int get longBreakDuration => _config.longBreakMinutes * 60;

  int get _phaseDuration {
    switch (_currentPhase) {
      case PomodoroPhase.work:
        return workDuration;
      case PomodoroPhase.shortBreak:
        return breakDuration;
      case PomodoroPhase.longBreak:
        return longBreakDuration;
    }
  }

  // ── Timer state ─────────────────────────────────────────────────

  int _workRemaining = 0;
  int get workRemaining => _workRemaining;

  int _breakRemaining = 0;
  int get breakRemaining => _breakRemaining;

  int _longBreakRemaining = 0;
  int get longBreakRemaining => _longBreakRemaining;

  int get _phaseRemaining {
    switch (_currentPhase) {
      case PomodoroPhase.work:
        return _workRemaining;
      case PomodoroPhase.shortBreak:
        return _breakRemaining;
      case PomodoroPhase.longBreak:
        return _longBreakRemaining;
    }
  }

  int get timeRemaining => _phaseRemaining;

  int _completedSessions = 0;
  int get completedSessions => _completedSessions;

  bool _isTimerRunning = false;
  bool get isTimerRunning => _isTimerRunning;

  // ── Foreground task ──────────────────────────────────────────────

  void _initForegroundStream() {
    _foregroundSubscription =
        ForegroundTaskService().remainingSecondsStream.listen((seconds) {
      switch (_currentPhase) {
        case PomodoroPhase.work:
          _workRemaining = seconds;
          break;
        case PomodoroPhase.shortBreak:
          _breakRemaining = seconds;
          break;
        case PomodoroPhase.longBreak:
          _longBreakRemaining = seconds;
          break;
      }
      notifyListeners();
    });
  }

  void _initForegroundTaskCallback() {
    FlutterForegroundTask.addTaskDataCallback(_onForegroundTaskData);
  }

  void _onForegroundTaskData(Object data) {
    if (data is Map && data['type'] == 'pomodoro_complete') {
      // Phase completion handled by the foreground service which already
      // transitioned to the next phase. We just need to play sound + vibrate
      // if the app is in the foreground.
      if (_isTimerRunning) {
        _playCompletionSound();
        HapticFeedback.vibrate();
      }
      notifyListeners();
    }
  }

  // ── Config change listener ───────────────────────────────────────

  void _onConfigChanged() {
    if (_isTimerRunning) {
      // Preserve remaining seconds, recalculate progress
      notifyListeners();
    } else {
      // Idle: show new defaults immediately
      _currentPhase = PomodoroPhase.work;
      _workRemaining = workDuration;
      _breakRemaining = breakDuration;
      _longBreakRemaining = longBreakDuration;
      _completedSessions = 0;
      notifyListeners();
    }
  }

  // ── Load active session (called by AppShell on startup) ──────────

  Future<void> loadActiveSession() async {
    final session = await _repository.getActiveSession();
    if (session != null) {
      _isTimerRunning = session.status == PomodoroStatus.running;
      _currentPhase = PomodoroPhase.values[session.currentPhase];
      final remaining = session.remaining.inSeconds;
      switch (_currentPhase) {
        case PomodoroPhase.work:
          _workRemaining = remaining;
          break;
        case PomodoroPhase.shortBreak:
          _breakRemaining = remaining;
          break;
        case PomodoroPhase.longBreak:
          _longBreakRemaining = remaining;
          break;
      }
      _completedSessions = session.completedSessions;
      notifyListeners();
    }
  }

  // ── Timer control ────────────────────────────────────────────────

  Future<void> startTimer() async {
    if (_isTimerRunning) return;

    _isTimerRunning = true;
    notifyListeners();

    // Start the foreground task so the timer survives screen off
    final session = PomodoroSession(
      id: _uuid.v4(),
      itemTitle: _phaseLabel,
      listId: '',
      durationMinutes: _phaseDuration ~/ 60,
      status: PomodoroStatus.running,
      startedAt: DateTime.now(),
      remaining: Duration(seconds: _phaseRemaining),
      currentPhase: _currentPhase.index,
      completedSessions: _completedSessions,
    );
    await _repository.startSession(session);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isTimerRunning && _phaseRemaining > 0) {
        switch (_currentPhase) {
          case PomodoroPhase.work:
            _workRemaining--;
            break;
          case PomodoroPhase.shortBreak:
            _breakRemaining--;
            break;
          case PomodoroPhase.longBreak:
            _longBreakRemaining--;
            break;
        }
        notifyListeners();

        if (_phaseRemaining <= 0) {
          _onPhaseComplete();
        }
      }
    });
  }

  Future<void> pauseTimer() async {
    if (!_isTimerRunning) return;

    _isTimerRunning = false;
    _timer?.cancel();
    _timer = null;
    await _repository.pauseSession();
    notifyListeners();
  }

  Future<void> resetTimer() async {
    _timer?.cancel();
    _timer = null;
    _isTimerRunning = false;
    await _repository.pauseSession();
    // Reset the CURRENT phase to its full duration
    switch (_currentPhase) {
      case PomodoroPhase.work:
        _workRemaining = workDuration;
        break;
      case PomodoroPhase.shortBreak:
        _breakRemaining = breakDuration;
        break;
      case PomodoroPhase.longBreak:
        _longBreakRemaining = longBreakDuration;
        break;
    }
    notifyListeners();
  }

  // ── Phase transitions ────────────────────────────────────────────

  Future<void> _onPhaseComplete() async {
    _timer?.cancel();
    _timer = null;

    switch (_currentPhase) {
      case PomodoroPhase.work:
        // Work completed
        _completedSessions++;
        if (_completedSessions < 4) {
          _currentPhase = PomodoroPhase.shortBreak;
          _breakRemaining = breakDuration;
        } else {
          _currentPhase = PomodoroPhase.longBreak;
          _longBreakRemaining = longBreakDuration;
        }
        break;

      case PomodoroPhase.shortBreak:
        // Short break completed
        _currentPhase = PomodoroPhase.work;
        _workRemaining = workDuration;
        break;

      case PomodoroPhase.longBreak:
        // Long break completed — reset cycle
        _completedSessions = 0;
        _currentPhase = PomodoroPhase.work;
        _workRemaining = workDuration;
        break;
    }

    // Sound + vibration on any phase completion
    _playCompletionSound();
    HapticFeedback.vibrate();

    notifyListeners();
  }

  // ── Phase label helpers ──────────────────────────────────────────

  String get _phaseLabel {
    switch (_currentPhase) {
      case PomodoroPhase.work:
        return 'Work';
      case PomodoroPhase.shortBreak:
        return 'Short Break';
      case PomodoroPhase.longBreak:
        return 'Long Break';
    }
  }

  // ── Sound ────────────────────────────────────────────────────────

  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> _playCompletionSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/complete.mp3'));
    } catch (_) {
      // Sound playback failed silently
    }
  }

  // ── Dispose ──────────────────────────────────────────────────────

  @override
  void dispose() {
    _timer?.cancel();
    _foregroundSubscription?.cancel();
    FlutterForegroundTask.removeTaskDataCallback(_onForegroundTaskData);
    _config.durationsValue.removeListener(_onConfigChanged);
    _audioPlayer.dispose();
    super.dispose();
  }
}

final _uuid = const Uuid();
