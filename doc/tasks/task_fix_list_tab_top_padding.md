name: fix_list_tab_top_padding
phase: 6
description: Add top-safe-area spacing to the Lists tab so the first row of list cards no longer sits flush against the top of the screen while preserving the existing grid, refresh, and add-list behavior.
files:
  - lib/ui/screens/app_shell/app_shell.dart
completion_criteria:
  - [ ] The Lists tab content respects the top safe area or equivalent top inset so the first row of list cards is visibly separated from the top edge/status bar
  - [ ] The list grid keeps its current two-column layout, pull-to-refresh behavior, and existing card interactions after the top spacing change
  - [ ] The floating add-list button remains available and functional on the Lists tab after the layout update
  - [ ] `dart analyze` passes without introducing new errors in the touched files
status: pending
