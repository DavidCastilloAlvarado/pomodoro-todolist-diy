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

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadLists() async {
    _isLoading = true;
    notifyListeners();
    try {
      _lists = await _repository.getAllLists();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addList(String name, Color color) async {
    final list = TodoList(
      id: _uuid.v4(),
      name: name,
      color: color,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _repository.addList(list);
    _lists = [..._lists, list];
    notifyListeners();
  }

  Future<void> deleteList(String id) async {
    await _repository.deleteList(id);
    _lists = _lists.where((l) => l.id != id).toList();
    notifyListeners();
  }
}

final _uuid = const Uuid();
