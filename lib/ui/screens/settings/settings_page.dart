import 'package:birdle/ui/view_models/pomodoro_config_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Settings page for configuring Pomodoro timer durations.
/// Three text field inputs pre-populated from [PomodoroConfigViewModel].
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _workController;
  late TextEditingController _breakController;
  late TextEditingController _longBreakController;

  @override
  void initState() {
    super.initState();
    _workController = TextEditingController();
    _breakController = TextEditingController();
    _longBreakController = TextEditingController();
  }

  @override
  void dispose() {
    _workController.dispose();
    _breakController.dispose();
    _longBreakController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PomodoroConfigViewModel>(
      builder: (context, config, _) {
        // Update controllers when config changes
        if (_workController.text != config.workMinutes.toString()) {
          _workController.text = config.workMinutes.toString();
        }
        if (_breakController.text != config.breakMinutes.toString()) {
          _breakController.text = config.breakMinutes.toString();
        }
        if (_longBreakController.text != config.longBreakMinutes.toString()) {
          _longBreakController.text = config.longBreakMinutes.toString();
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Pomodoro Durations (minutes)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Work duration input
            TextFormField(
              controller: _workController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Work (min)',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                final parsed = int.tryParse(value);
                if (parsed == null || parsed <= 0) return 'Must be a positive integer';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Break duration input
            TextFormField(
              controller: _breakController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Short Break (min)',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                final parsed = int.tryParse(value);
                if (parsed == null || parsed <= 0) return 'Must be a positive integer';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Long break duration input
            TextFormField(
              controller: _longBreakController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Long Break (min)',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                final parsed = int.tryParse(value);
                if (parsed == null || parsed <= 0) return 'Must be a positive integer';
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Save button
            FilledButton(
              onPressed: () {
                final work = int.tryParse(_workController.text);
                final breakMin = int.tryParse(_breakController.text);
                final longBreak = int.tryParse(_longBreakController.text);

                if (work == null || work <= 0 ||
                    breakMin == null || breakMin <= 0 ||
                    longBreak == null || longBreak <= 0) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All durations must be positive integers')),
                    );
                  }
                  return;
                }

                // CRITICAL: notifyListeners() is called inside saveDurations()
                config.saveDurations(
                  workMinutes: work,
                  breakMinutes: breakMin,
                  longBreakMinutes: longBreak,
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Durations saved')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
