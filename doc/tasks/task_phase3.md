# Phase 3 — Todo Core

## Tasks

### Task 3.1: ColorPickerDialog
- Reusable dialog widget that shows a grid of color swatches
- User taps a color → dialog closes, returns selected Color
- At least 12 preset colors to choose from

### Task 3.2: AlarmPickerDialog
- Reusable dialog widget for picking alarm day + time
- Day picker: Mon–Sun + Every Day (chip-style selectable list)
- Time picker: uses `showTimePicker`
- Returns `AlarmInfo?` (null = no alarm)

### Task 3.3: ItemDetailViewModel
- `loadItems(listId)` — fetches items for a list
- `addItem(listId, title)` — adds item with default color
- `toggleCompleted(itemId)` — toggles completed flag
- `updateItemColor(itemId, color)` — updates item color
- `deleteItem(itemId)` — deletes item + cancels alarm
- `updateItemAlarm(itemId, AlarmInfo?)` — sets/cancels alarm

### Task 3.4: ItemDetailPage
- Navigated to from `_ListsView` via `Navigator.pushNamed('/item_detail', arguments: listId)`
- Shows list name as AppBar title
- Lists all items for the list:
  - Each item: leading checkbox (toggles completed), title text (strikethrough when completed), trailing color indicator chip
  - Tap item → show color picker dialog
  - Long press → delete with confirmation
- FAB: adds new item (shows `TextFormField` inline)
- Alarm indicator on items that have alarms

### Task 3.5: Update _ListsView — Grid + FAB
- Change from `ListView` to `GridView.count` (crossAxisCount: 2)
- Each card shows colored header + list name + item count
- FAB to add new list (shows name input + color picker)

### Task 3.6: Wire Routes in app.dart
- Add `routes` to MaterialApp: `/item_detail` → `ItemDetailPage`
- Extract `listId` from `ModalRoute.of(context)!.arguments as String`

## Completion Criteria

1. `_ListsView` displays a 2-column grid of colored list cards with item counts
2. FAB in `_ListsView` adds a new list with name input and color picker
3. Tapping a list card navigates to `ItemDetailPage`
4. `ItemDetailPage` shows all items for the selected list
5. Items can be toggled complete, edited for color, and deleted
6. Alarm picker dialog works for items
7. New list/item creation works end-to-end (DB + UI refresh)
8. `dart analyze` passes with no errors
