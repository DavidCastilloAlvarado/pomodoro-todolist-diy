import 'package:flutter/material.dart';
import 'package:birdle/data/models/todo_item.dart';
import 'package:birdle/data/repositories/item_repository.dart';
import 'package:uuid/uuid.dart';

class ItemDetailViewModel extends ChangeNotifier {
  ItemDetailViewModel({
    required ItemRepository repository,
    required String listId,
  })  : _repository = repository,
        _listId = listId;

  final ItemRepository _repository;
  final String _listId;

  List<TodoItem> _items = [];
  List<TodoItem> get items => List.unmodifiable(_items);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isAdding = false;
  bool get isAdding => _isAdding;

  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();
    try {
      _items = await _repository.getItems(_listId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addItem(String title, Color color) async {
    _isAdding = true;
    notifyListeners();
    try {
      final item = TodoItem(
        id: _uuid.v4(),
        listId: _listId,
        title: title,
        color: color,
        createdAt: DateTime.now(),
      );
      await _repository.addItem(item);
      _items = [..._items, item];
    } finally {
      _isAdding = false;
      notifyListeners();
    }
  }

  Future<void> toggleCompleted(String itemId) async {
    await _repository.toggleCompleted(itemId);
    _items = _items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(completed: !item.completed);
      }
      return item;
    }).toList();
    notifyListeners();
  }

  Future<void> updateItemColor(String itemId, Color color) async {
    final item = _items.firstWhere((i) => i.id == itemId);
    final updated = item.copyWith(color: color);
    await _repository.updateItem(updated);
    _items = _items.map((i) => i.id == itemId ? updated : i).toList();
    notifyListeners();
  }

  Future<void> deleteItem(String itemId) async {
    await _repository.deleteItem(itemId);
    _items = _items.where((i) => i.id != itemId).toList();
    notifyListeners();
  }

  Future<void> updateItemAlarm(String itemId, AlarmInfo? alarm) async {
    final item = _items.firstWhere((i) => i.id == itemId);

    // Cancel any existing alarm before setting a new one.
    if (item.alarm != null) {
      await _repository.cancelAlarm(itemId);
    }

    final updated = item.copyWith(alarm: alarm);
    await _repository.updateItem(updated);

    // Schedule the new alarm if one was set.
    if (alarm != null) {
      await _repository.scheduleAlarm(updated);
    }

    _items = _items.map((i) => i.id == itemId ? updated : i).toList();
    notifyListeners();
  }
}

final _uuid = const Uuid();
