task: phase3_itemcount
reviewer: reviewer
date: 2026-05-16
status: approved
findings:
  - severity: info
    file: lib/ui/screens/app_shell/app_shell.dart
    line: 76
    description: "Don't use 'BuildContext's across async gaps — a dialog's returned context is used after the first await. This is an info-level lint, not a blocker."
    fix_instruction: "Guard the context use on line 76 with a 'mounted' check on the State object (this.mounted) before using it, or re-fetch the context via a local variable captured before the await."
  - severity: info
    file: lib/ui/widgets/color_picker_dialog.dart
    line: 55
    description: "'withOpacity' is deprecated — use '.withValues()' instead to avoid precision loss. This is pre-existing code, unrelated to this task."
    fix_instruction: "Replace '.withOpacity(...)' with '.withValues(alpha: ...)' on line 55 of color_picker_dialog.dart."
criteria:
  - [x] BirdleDatabase gains a countItemsByList(String listId) method that returns an int via raw SQL: SELECT COUNT(*) FROM todo_items WHERE list_id = ?
  - [x] ListRepository gains a countItemsByList(String listId) method that delegates to the database and returns the count
  - [x] ListListViewModel has a Map<String, int> _itemCounts field and a public getter itemCounts
  - [x] loadLists() calls _repository.countItemsByList for each list (in parallel via Future.wait) and populates _itemCounts before notifying
  - [x] After _showAddListDialog creates a list, item counts are refreshed (via loadLists call)
  - [x] _ListCard accepts an int itemCount parameter
  - [x] _ListCard displays a subtitle row below the list name showing "{count} items" (or "No items" when count is 0), using a subtle white text style consistent with the card's white theme
  - [x] dart analyze reports zero errors and zero warnings
summary: |
  All 8 completion criteria are met. The implementation follows the MVVM + Repository architecture:
  - Database layer: countItemsByList uses raw SQL SELECT COUNT(*) FROM todo_items WHERE list_id = ? (line 266-268 of database.dart).
  - Repository layer: ListRepository.countItemsByList delegates to _db.countItemsByList (line 45-47 of list_repository.dart).
  - ViewModel layer: _itemCounts Map field and public itemCounts getter added (lines 15-16 of list_list_view_model.dart). loadLists() fetches lists, then uses Future.wait on _lists.map(...) to count items in parallel, populates _itemCounts, then calls notifyListeners() (lines 24-40).
  - UI layer: _ListCard accepts itemCount parameter (line 175 of app_shell.dart) and displays "No items" or "N items" subtitle with white text style (lines 229-235). _ListsView passes viewModel.itemCounts[list.id] ?? 0 (line 154). After _showAddListDialog creates a list, viewModel.loadLists() is called to refresh counts (line 106).
  - dart analyze reports zero errors and zero warnings (2 info-level issues remain, both pre-existing and unrelated to this task).
  - Architectural compliance: Repository pattern respected, ViewModel extends ChangeNotifier, views are lean widgets with no business logic, dependency injection via Provider.
