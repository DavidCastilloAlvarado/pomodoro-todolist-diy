task: fix_list_tab_top_padding
reviewer: reviewer
date: 2026-05-17
status: approved
findings: []
summary: |
  Approved. The Lists tab now wraps its scrollable content in SafeArea(bottom: false), which adds the requested top inset without changing the existing two-column GridView, RefreshIndicator wiring, or floating add-list button behavior. The change is minimal and localized to lib/ui/screens/app_shell/app_shell.dart, and `dart analyze` passes with no issues.
completion_criteria_check:
  - [x] The Lists tab content respects the top safe area or equivalent top inset so the first row of list cards is visibly separated from the top edge/status bar
  - [x] The list grid keeps its current two-column layout, pull-to-refresh behavior, and existing card interactions after the top spacing change
  - [x] The floating add-list button remains available and functional on the Lists tab after the layout update
  - [x] `dart analyze` passes without introducing new errors in the touched files
