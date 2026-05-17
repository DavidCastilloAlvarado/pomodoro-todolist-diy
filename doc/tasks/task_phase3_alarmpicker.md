name: phase3_alarmpicker
phase: 3
description: >
  Create AlarmPickerDialog — a dialog that lets users select a day of the week
  and a time for item alarms. Integrate it into ItemDetailPage so users can
  set alarms per item.

files:
  - lib/ui/widgets/alarm_picker_dialog.dart
  - lib/ui/screens/item_detail_page.dart
  - lib/ui/view_models/item_detail_view_model.dart
completion_criteria:
  - [ ] AlarmPickerDialog exists in lib/ui/widgets/
  - [ ] Dialog has day-of-week selector (all 7 days + "Every day" option)
  - [ ] Dialog has time picker (TimePickerDialog)
  - [ ] Returns AlarmInfo (day + time) or null
  - [ ] ItemDetailPage has an alarm button per item row
  - [ ] Tapping alarm button opens AlarmPickerDialog
  - [ ] Saving alarm calls viewModel.updateItemAlarm()
  - [ ] AlarmInfo is saved to DB via ItemRepository
  - [ ] dart analyze passes with no errors
status: completed
