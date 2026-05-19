import 'package:birdle/data/services/storage_service.dart';
import 'package:birdle/ui/view_models/palette_view_model.dart';
import 'package:birdle/ui/view_models/pomodoro_config_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  String _userName = '';
  List<int> _workingDurations = [25, 50, 75];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final storage = StorageService();
    final name = storage.getName() ?? 'Not set';
    final storedDurations = storage.getPomodoroDurations();
    if (mounted) {
      setState(() {
        _userName = name;
        _workingDurations = storedDurations.isEmpty
            ? List.from(StorageService.defaultPomodoroDurations)
            : storedDurations;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PaletteViewModel>(
      builder: (context, paletteVm, child) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── User name ──────────────────────────────────────
            const Text(
              'User',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _userName.isEmpty ? 'Not set' : _userName,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),

            // ── Palette selection ──────────────────────────────
            const Text(
              'Color Palettes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: paletteVm.allPalettes.length,
                itemBuilder: (context, index) {
                  final palette = paletteVm.allPalettes[index];
                  final isSelected =
                      paletteVm.currentPalette == palette.name;
                  return GestureDetector(
                    onTap: () => paletteVm.setPalette(palette.name),
                    child: Container(
                      width: 48,
                      height: 48,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: palette.accentColors.first,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Current: ${paletteVm.currentPalette}',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // ── Pomodoro durations ─────────────────────────────
            const Text(
              'Pomodoro Durations (minutes)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Consumer<PomodoroConfigViewModel>(
              builder: (context, config, _) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...config.durations.map(
                      (d) => Chip(
                        label: Text('$d min'),
                        onDeleted: () {
                          setState(() {
                            _workingDurations.remove(d);
                          });
                          // Persist and notify all Consumers
                          context
                              .read<PomodoroConfigViewModel>()
                              .saveDurations(_workingDurations);
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () {
                        final config = context.read<PomodoroConfigViewModel>();
                        showDialog<int>(
                          context: context,
                          builder: (ctx) => _DurationPickerDialog(
                            currentDurations: _workingDurations,
                          ),
                        ).then((value) {
                          if (value != null && mounted) {
                            setState(() {
                              _workingDurations.add(value);
                            });
                            // Persist and notify all Consumers (Settings + Pomodoro)
                            config.saveDurations(_workingDurations);
                          }
                        });
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

/// Dialog for picking a single pomodoro duration.
class _DurationPickerDialog extends StatefulWidget {
  final List<int> currentDurations;

  const _DurationPickerDialog({required this.currentDurations});

  @override
  State<_DurationPickerDialog> createState() => _DurationPickerDialogState();
}

class _DurationPickerDialogState extends State<_DurationPickerDialog> {
  int _selected = 25;
  final TextEditingController _customController = TextEditingController();

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Duration'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose a duration in minutes:'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [25, 50, 75, 10, 15, 30, 45, 60].map((d) {
              final isSelected = d == _selected;
              return ChoiceChip(
                label: Text('$d'),
                selected: isSelected,
                onSelected: (_) => setState(() {
                  _selected = d;
                  _customController.clear();
                }),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          const Text('Or enter a custom value:'),
          const SizedBox(height: 4),
          TextFormField(
            controller: _customController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'e.g. 1, 2, 3',
              border: OutlineInputBorder(),
              prefixText: '',
            ),
            onFieldSubmitted: (val) {
              final parsed = int.tryParse(val);
              if (parsed != null && parsed > 0) {
                setState(() {
                  _selected = parsed;
                });
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            // Always try text field first — it takes priority over chip selection.
            final parsed = int.tryParse(_customController.text);
            if (parsed != null && parsed > 0) {
              Navigator.of(context).pop(parsed);
            } else {
              // Text field is empty or invalid — fall back to chip selection.
              Navigator.of(context).pop(_selected);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
