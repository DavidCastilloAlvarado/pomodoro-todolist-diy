import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:birdle/data/models/todo_item.dart';
import 'package:birdle/data/services/notification_service.dart';

/// Result type for the alarm picker dialog.
///
/// Used to distinguish between:
/// - [AlarmSet] — user picked a new alarm
/// - [AlarmRemoved] — user explicitly removed the alarm
/// - [AlarmDismissed] — user dismissed the dialog without making a choice
sealed class AlarmPickerResult {
  const AlarmPickerResult();
}

/// The user picked a new alarm in the picker dialog.
class AlarmSet extends AlarmPickerResult {
  const AlarmSet(this.alarm);
  final AlarmInfo alarm;
}

/// The user explicitly removed the alarm.
class AlarmRemoved extends AlarmPickerResult {
  const AlarmRemoved();
}

/// The user dismissed the dialog without making a choice.
class AlarmDismissed extends AlarmPickerResult {
  const AlarmDismissed();
}

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

  Future<void> _ok() async {
    final alarmInfo = AlarmInfo(day: _selectedDay, time: _selectedTime);
    final canSchedule = await NotificationService().canScheduleExactAlarms();
    if (!canSchedule && _selectedDay != DayOfWeek.everyDay) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Exact Alarm Permission'),
            content: const Text(
              'Your device does not allow Birdle to set exact alarms. '
              'Alarms may not fire at the exact time you set. '
              'You can try enabling this in Settings → Apps → Birdle → '
              'Special app access → Exact alarms.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
              OutlinedButton(
                onPressed: () async {
                  await openAppSettings();
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                  }
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }
    }
    if (mounted) {
      Navigator.of(context).pop<AlarmPickerResult>(AlarmSet(alarmInfo));
    }
  }

  void _clear() {
    Navigator.of(context).pop<AlarmPickerResult>(const AlarmRemoved());
  }

  void _cancel() {
    Navigator.of(context).pop<AlarmPickerResult>(const AlarmDismissed());
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
        if (widget.initialAlarm != null)
          TextButton(
            onPressed: _clear,
            child: const Text('Clear'),
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
