name: phase3_listlistview
phase: 3
description: >
  Replace AppShell._ListsView with a proper grid of colored list cards and add
  a FAB to create new lists with the existing ColorPickerDialog.

files:
  - lib/ui/screens/app_shell/app_shell.dart
  - lib/ui/view_models/list_list_view_model.dart
  - lib/data/repositories/list_repository.dart
completion_criteria:
  - [ ] _ListsView renders lists in a GridView (not a plain ListView)
  - [ ] Each grid card shows the list name and uses list.color as background
  - [ ] FAB in Scaffold adds a new list
  - [ ] FAB opens ColorPickerDialog, user picks a color, creates list
  - [ ] ListListViewModel.addList is wired to FAB flow
  - [ ] List grid scrolls properly (no overflow)
  - [ ] dart analyze passes with no errors
status: completed
