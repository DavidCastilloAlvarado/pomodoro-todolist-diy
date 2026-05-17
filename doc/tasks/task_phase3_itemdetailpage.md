name: phase3_itemdetailpage
phase: 3
description: >
  Create ListItemDetailPage — a screen showing all items for a selected list.
  Items are displayed as a list with tap-to-complete toggle. Each item has
  a per-item color picker. Also add an FAB to add new items.

files:
  - lib/ui/screens/item_detail_page.dart
  - lib/ui/view_models/item_detail_view_model.dart
  - lib/app.dart
completion_criteria:
  - [ ] ListItemDetailPage exists as a new file in lib/ui/screens/
  - [ ] Page reads listId from route arguments
  - [ ] Displays items as a list (checklist style) with title and completion state
  - [ ] Tap item row toggles completed state
  - [ ] Per-item color picker available (long press or edit button)
  - [ ] FAB to add new item with title input
  - [ ] Route /item_detail registered in app.dart
  - [ ] dart analyze passes with no errors
status: completed
