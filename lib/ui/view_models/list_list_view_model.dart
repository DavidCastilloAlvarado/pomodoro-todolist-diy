import 'package:flutter/material.dart';
import 'package:birdle/data/models/todo_list.dart';
import 'package:birdle/data/repositories/list_repository.dart';
import 'package:uuid/uuid.dart';

class ListListViewModel extends ChangeNotifier {
  ListListViewModel({required ListRepository repository})
      : _repository = repository;

  final ListRepository _repository;

  List<TodoList> _lists = [];
  List<TodoList> get lists => List.unmodifiable(_lists);

  Map<String, int> _itemCounts = {};
  Map<String, int> get itemCounts => _itemCounts;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isAdding = false;
  bool get isAdding => _isAdding;

  Future<void> loadLists() async {
    _isLoading = true;
    notifyListeners();
    try {
      _lists = await _repository.getAllLists();
      final counts = <String, int>{};
      await Future.wait(
        _lists.map((list) async {
          counts[list.id] = await _repository.countItemsByList(list.id);
        }),
      );
      _itemCounts = counts;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addList(String name, Color color) async {
    _isAdding = true;
    notifyListeners();
    try {
      final list = TodoList(
        id: _uuid.v4(),
        name: name,
        color: color,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _repository.addList(list);
      // Reload from DB to ensure in-memory state is in sync
      _lists = await _repository.getAllLists();
    } finally {
      _isAdding = false;
      notifyListeners();
    }
  }

  Future<void> deleteList(String id) async {
    await _repository.deleteList(id);
    // Reload from DB to ensure in-memory state is in sync
    _lists = await _repository.getAllLists();
    notifyListeners();
  }

  Future<void> reloadListCounts() async {
    // First ensure lists are up to date
    _lists = await _repository.getAllLists();
    final counts = <String, int>{};
    await Future.wait(
      _lists.map((list) async {
        counts[list.id] = await _repository.countItemsByList(list.id);
      }),
    );
    _itemCounts = counts;
    notifyListeners();
  }
}

final _uuid = const Uuid();
