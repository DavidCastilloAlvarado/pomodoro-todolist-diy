import 'package:flutter/material.dart';
import 'package:birdle/data/models/todo_item.dart';

class AlarmPickerDialog extends StatefulWidget {
  const AlarmPickerDialog({super.key, this.initialAlarm});

  final AlarmInfo? initialAlarm;

  @override
  State<AlarmPickerDialog> createState() => _AlarmPickerDialogState();
}

class _AlarmPickerDialogState extends State<AlarmPickerDialog> {
  late DayOfWeek _selectedDay;
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    if (widget.initialAlarm != null) {
      _selectedDay = widget.initialAlarm!.day;
      _selectedTime = widget.initialAlarm!.time;
    } else {
      _selectedDay = DayOfWeek.everyDay;
      _selectedTime = TimeOfDay.now();
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && context.mounted) {
      setState(() => _selectedTime = picked);
    }
  }

  void _ok() {
    Navigator.of(context).pop<AlarmInfo?>(
      AlarmInfo(day: _selectedDay, time: _selectedTime),
    );
  }

  void _cancel() {
    Navigator.of(context).pop<AlarmInfo?>(null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Set alarm'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day selector
            const Text(
              'Day',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: DayOfWeek.values.map((day) {
                final isSelected = _selectedDay == day;
                final label = _dayLabel(day);
                return ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => _selectedDay = day);
                  },
                  selectedColor: theme.colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Time picker
            const Text(
              'Time',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _pickTime(context),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _selectedTime.format(context),
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _cancel,
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _ok,
          child: const Text('OK'),
        ),
      ],
    );
  }

  String _dayLabel(DayOfWeek day) {
    return switch (day) {
      DayOfWeek.monday => 'Mon',
      DayOfWeek.tuesday => 'Tue',
      DayOfWeek.wednesday => 'Wed',
      DayOfWeek.thursday => 'Thu',
      DayOfWeek.friday => 'Fri',
      DayOfWeek.saturday => 'Sat',
      DayOfWeek.sunday => 'Sun',
      DayOfWeek.everyDay => 'Every day',
    };
  }
}
