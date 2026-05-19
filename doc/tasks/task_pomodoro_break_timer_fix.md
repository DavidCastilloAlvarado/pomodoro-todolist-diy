name: pomodoro_break_timer_fix
phase: 4
description: Fix Short Break timer showing 00:00 and not counting down after Work phase completes. Three related issues: (1) _onPhaseComplete() never calls _startTimer() to restart the countdown, (2) foreground stream listener overwrites _breakRemaining with stale 0, (3) foreground task callback's remaining stays <= 0 causing repeated pomodoro_complete events.
files:
  - lib/ui/view_models/pomodoro_view_model.dart
  - lib/data/services/foreground_task.dart
completion_criteria:
  - [ ] _onPhaseComplete() calls _startTimer() after setting the new phase and remaining time
  - [ ] Foreground stream listener guards against overwriting with stale values (only updates when value > 0 or within expected range)
  - [ ] Foreground task callback resets remaining to new phase duration after phase transition (prevents infinite pomodoro_complete events)
  - [ ] Work → Short Break transition: Short Break timer displays correct duration (e.g., 01:00) and counts down
  - [ ] Short Break → Work transition: Work timer displays correct duration and counts down
  - [ ] Short Break → Work → Long Break → Work full cycle completes without timer issues
  - [ ] dart analyze reports zero errors and zero warnings
status: pending
