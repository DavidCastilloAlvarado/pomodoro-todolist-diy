import 'package:birdle/data/models/pomodoro_session.dart';
import 'package:birdle/ui/view_models/pomodoro_config_view_model.dart';
import 'package:birdle/ui/view_models/pomodoro_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  @override
  void initState() {
    super.initState();
    // Load config durations on first visit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PomodoroConfigViewModel>().loadDurations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PomodoroViewModel>(
      builder: (context, vm, child) {
        // Also listen to config changes so we can display current durations
        return Consumer<PomodoroConfigViewModel>(
          builder: (context, config, _) {
            return Scaffold(
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ── Three timer rows ─────────────────────────────
                      _TimerRow(
                        label: 'Work',
                        duration: config.workMinutes,
                        remaining: vm.workRemaining,
                        isActive: vm.currentPhase == PomodoroPhase.work,
                        phaseDuration: vm.workDuration,
                      ),
                      const SizedBox(height: 16),
                      _TimerRow(
                        label: 'Short Break',
                        duration: config.breakMinutes,
                        remaining: vm.breakRemaining,
                        isActive: vm.currentPhase == PomodoroPhase.shortBreak,
                        phaseDuration: vm.breakDuration,
                      ),
                      const SizedBox(height: 16),
                      _TimerRow(
                        label: 'Long Break',
                        duration: config.longBreakMinutes,
                        remaining: vm.longBreakRemaining,
                        isActive: vm.currentPhase == PomodoroPhase.longBreak,
                        phaseDuration: vm.longBreakDuration,
                      ),

                      const SizedBox(height: 24),

                      // ── Active phase label ───────────────────────────
                      Text(
                        vm.currentPhase == PomodoroPhase.work
                            ? 'Work Session'
                            : vm.currentPhase == PomodoroPhase.shortBreak
                                ? 'Short Break'
                                : 'Long Break',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ── Session counter with dot indicators ──────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          4,
                          (index) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: index < vm.completedSessions
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.primaryContainer,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 48),

                      // ── Action buttons ───────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Start / Pause toggle
                          FilledButton(
                            onPressed: vm.isTimerRunning
                                ? vm.pauseTimer
                                : vm.startTimer,
                            child: Text(
                              vm.isTimerRunning ? 'Pause' : 'Start',
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Reset button
                          OutlinedButton(
                            onPressed: vm.resetTimer,
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// A single timer row showing label, circular progress, and time.
class _TimerRow extends StatelessWidget {
  final String label;
  final int duration;
  final int remaining;
  final bool isActive;
  final int phaseDuration;

  const _TimerRow({
    required this.label,
    required this.duration,
    required this.remaining,
    required this.isActive,
    required this.phaseDuration,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3);
    final progress = phaseDuration > 0
        ? (isActive && remaining > 0 ? remaining / phaseDuration : 1.0)
        : 1.0;

    return Row(
      children: [
        // Label
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: isActive ? 18 : 14,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Circular progress indicator
        SizedBox(
          width: 56,
          height: 56,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 4,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(width: 12),
        // Time display
        Text(
          _formatTime(remaining),
          style: TextStyle(
            fontSize: isActive ? 28 : 20,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatTime(int totalSeconds) {
    final mins = (totalSeconds ~/ 60).remainder(60);
    final secs = totalSeconds.remainder(60);
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
