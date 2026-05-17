name: phase3_itemcount
phase: 3
description: >
  Add item counts to each list card in the grid view on the Lists tab.
  Each card currently shows the list name and color; this task adds a
  subtitle row displaying the total number of items in that list (e.g.
  "3 items" or "0 items"). Counts are fetched via a raw SQL COUNT(*)
  query, cached in the ViewModel, and passed down to the card widget.
files:
  - lib/data/services/database.dart
  - lib/data/repositories/list_repository.dart
  - lib/ui/view_models/list_list_view_model.dart
  - lib/ui/screens/app_shell/app_shell.dart
completion_criteria:
  - [ ] BirdleDatabase gains a countItemsByList(String listId) method that
        returns an int via raw SQL: SELECT COUNT(*) FROM todo_items WHERE list_id = ?
  - [ ] ListRepository gains a countItemsByList(String listId) method that
        delegates to the database and returns the count
  - [ ] ListListViewModel has a Map<String, int> _itemCounts field and a
        public getter itemCounts
  - [ ] loadLists() calls _repository.countItemsByList for each list (in
        parallel via Future.wait) and populates _itemCounts before notifying
  - [ ] After _showAddListDialog creates a list, item counts are refreshed
        (either by calling loadLists again or a dedicated refresh)
  - [ ] _ListCard accepts an int itemCount parameter
  - [ ] _ListCard displays a subtitle row below the list name showing
        "{count} items" (or "No items" when count is 0), using a subtle
        white text style consistent with the card's white theme
  - [ ] dart analyze reports zero errors and zero warnings
status: completed
