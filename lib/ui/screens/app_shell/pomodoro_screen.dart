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
  int _selectedDuration = 25;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final config = context.read<PomodoroConfigViewModel>();
      config.loadDurations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PomodoroViewModel>(
      builder: (context, vm, child) {
        final status = vm.status;
        final remaining = vm.remainingSeconds;

        return Scaffold(
          body: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Timer display
                  Text(
                    _formatTime(remaining),
                    style: const TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                      fontVariations: [FontVariation('wght', 300)],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    status == PomodoroStatus.idle
                        ? 'Ready to focus'
                        : vm.session?.itemTitle ?? 'Focus session',
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 48),

                  // Duration picker (only when idle)
                  if (status == PomodoroStatus.idle) ...[
                    const Text(
                      'Duration (minutes)',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Consumer<PomodoroConfigViewModel>(
                      builder: (context, config, _) {
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: config.durations.map((d) {
                            final isSelected = d == _selectedDuration;
                            return ChoiceChip(
                              label: Text('$d'),
                              selected: isSelected,
                              onSelected: (_) => setState(() => _selectedDuration = d),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: () {
                        final listId = '';
                        vm.startSession(
                          itemTitle: 'Focus session',
                          listId: listId,
                          durationMinutes: _selectedDuration,
                        );
                      },
                      child: const Text('Start'),
                    ),
                  ],

                  // Pause button (when running)
                  if (status == PomodoroStatus.running)
                    FilledButton.tonal(
                      onPressed: () => vm.pauseSession(),
                      child: const Text('Pause'),
                    ),

                  // Resume + Cancel buttons (when paused)
                  if (status == PomodoroStatus.paused) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FilledButton(
                          onPressed: () => vm.resumeSession(),
                          child: const Text('Resume'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: () => vm.cancelSession(),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ],

                  // Completed state
                  if (status == PomodoroStatus.completed) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Session complete!',
                      style: TextStyle(fontSize: 18, color: Colors.green),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        vm.cancelSession();
                        setState(() {});
                      },
                      child: const Text('Done'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTime(int totalSeconds) {
    final mins = (totalSeconds ~/ 60).remainder(60);
    final secs = totalSeconds.remainder(60);
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
