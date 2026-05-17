task: phase3_itemdetailpage
reviewer: reviewer
date: 2026-05-16
status: needs_revision
findings:
  - severity: warning
    file: lib/ui/screens/item_detail_page.dart
    line: 36
    description: >
      `_fetchListName` creates a `ListRepository` directly by calling
      `ListRepository(database: context.read<BirdleDatabase>())`, bypassing
      the DI container. Per architecture.md, repositories must be consumed
      via `context.read<ListRepository>()` to maintain proper dependency
      injection and testability.
    fix_instruction: >
      Replace the body of `_fetchListName` to use the DI container:
      `final listRepo = context.read<ListRepository>();`
      and change the return type to `Future<TodoList?>`, returning
      `listRepo.getListById(listId)`. Remove the direct `ListRepository`
      and `BirdleDatabase` imports if no longer needed.
  - severity: info
    file: lib/ui/view_models/item_detail_view_model.dart
    line: 67
    description: >
      `updateItemColor` uses `_items.firstWhere((i) => i.id == itemId)`
      without an `orElse` clause. If the item was concurrently deleted
      (e.g., rapid tap), this will throw a `StateError` at runtime.
    fix_instruction: >
      Add an `orElse` handler:
      `final item = _items.firstWhere((i) => i.id == itemId, orElse: () => throw StateError('Item $itemId not found'));`
      Or better, return null and check before proceeding.
  - severity: info
    file: lib/ui/view_models/item_detail_view_model.dart
    line: 22-23
    description: >
      `_isAdding` / `isAdding` flag is set in `addItem()` but only checked
      in the UI's `_showAddItemDialog` (line 47) as a guard. It is never
      exposed to the UI layer for visual feedback (e.g., disabling the FAB).
      This is a minor dead-state — the flag serves no purpose since the
      dialog flow itself prevents re-entrance.
    fix_instruction: >
      Either: (a) remove `_isAdding` and rely on the dialog flow guard, or
      (b) wire `isAdding` to the FAB's `onPressed` (e.g., `onPressed: viewModel.isAdding ? null : () => ...`).
  - severity: info
    file: lib/di/di_container.dart
    line: 61
    description: >
      `ItemDetailViewModel` is not registered in `buildProviders()` in
      `di_container.dart`. Per architecture.md (line 1289), it should be
      listed. However, since `ItemDetailViewModel` requires a `listId`
      constructor parameter that varies per route, it cannot be a singleton.
      The inline `ChangeNotifierProvider` in `ItemDetailPage` is the
      correct workaround, but this should be documented.
    fix_instruction: >
      Add a comment in `di_container.dart` noting that `ItemDetailViewModel`
      is intentionally excluded because it requires a per-route `listId`
      parameter and is created inline via `ChangeNotifierProvider`.
  - severity: info
    file: lib/ui/screens/item_detail_page.dart
    line: 248-268
    description: >
      The per-item color picker is triggered by tapping a small 16x16 color
      dot. The task criterion specifies "long press or edit button". While
      a tappable color dot is functional, it may be hard to hit on small
      screens and could accidentally trigger color changes.
    fix_instruction: >
      Consider adding a long-press gesture detector on the item row itself
      to show the color picker, or adding a dedicated "palette" icon button
      next to the delete button for clearer intent.
  - severity: info
    file: lib/ui/screens/item_detail_page.dart
    line: 139
    description: >
      `_fetchListName` is called inside `FutureBuilder` which re-runs on
      every rebuild. The `future` is created fresh each time, so the
      FutureBuilder will always show the loading state on the first frame,
      then the data. This works correctly but is a minor anti-pattern —
      the future should be stored in state or use `computed` from `flutter_riverpod`.
    fix_instruction: >
      Store the future in a `late final` field or use `initState` to fetch
      the list name once and cache it, or use `FutureBuilder` with a
      `future` computed once in `build` (current approach is acceptable
      since FutureBuilder handles deduplication).

completion_criteria_check:
  - [x] ListItemDetailPage exists as a new file in lib/ui/screens/ — file exists at lib/ui/screens/item_detail_page.dart
  - [x] Page reads listId from route arguments — route in app.dart line 79 extracts listId from ModalRoute settings.arguments
  - [x] Displays items as a list (checklist style) with title and completion state — _ItemRow shows checkbox, color dot, title with line-through
  - [x] Tap item row toggles completed state — InkWell onTap and Checkbox onChanged both call viewModel.toggleCompleted
  - [x] Per-item color picker available (long press or edit button) — tappable color dot opens ColorPickerDialog (partial: no long press, but functional)
  - [x] FAB to add new item with title input — FloatingActionButton.extended shows color picker then title input dialog
  - [x] Route /item_detail registered in app.dart — registered at app.dart line 79
  - [x] dart analyze passes with no errors — 0 errors, 2 info-level warnings in pre-existing files only

summary: |
  The Phase 3 ItemDetailPage implementation is functionally complete and
  meets all completion criteria. The code compiles cleanly (0 errors).
  The MVVM pattern is followed: ItemDetailViewModel extends ChangeNotifier
  with repository injection, and the view (ItemDetailPage) is a lean
  StatelessWidget that delegates to the ViewModel.

  One warning finding: `_fetchListName` in item_detail_page.dart bypasses
  the DI container by directly instantiating ListRepository. This should
  use `context.read<ListRepository>()` instead for architectural compliance.

  Five info-level suggestions are provided regarding code robustness,
  UX polish, and documentation. These are optional improvements.

  Overall: the task is substantially complete. The DI violation in
  _fetchListName is the most significant issue and should be fixed.
