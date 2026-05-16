import 'package:flutter/material.dart';
import 'package:birdle/data/models/todo_list.dart';
import 'package:birdle/data/services/database.dart';

class ListRepository {
  ListRepository({required BirdleDatabase database}) : _db = database;

  final BirdleDatabase _db;

  Future<List<TodoList>> getAllLists() async {
    final data = await _db.getAllTodoLists();
    return data.map((d) => TodoList(
      id: d.id,
      name: d.name,
      color: Color(d.colorHex),
      createdAt: DateTime.fromMillisecondsSinceEpoch(d.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(d.updatedAt),
    )).toList();
  }

  Future<void> addList(TodoList list) async {
    await _db.insertTodoList(TodoListsData(
      id: list.id,
      name: list.name,
      colorHex: list.color.toARGB32(),
      createdAt: list.createdAt.millisecondsSinceEpoch,
      updatedAt: list.updatedAt.millisecondsSinceEpoch,
    ));
  }

  Future<void> updateList(TodoList list) async {
    await _db.updateTodoList(TodoListsData(
      id: list.id,
      name: list.name,
      colorHex: list.color.toARGB32(),
      createdAt: list.createdAt.millisecondsSinceEpoch,
      updatedAt: list.updatedAt.millisecondsSinceEpoch,
    ));
  }

  Future<void> deleteList(String id) async {
    await _db.deleteTodoList(id);
  }

  Future<TodoList?> getListById(String id) async {
    final data = await _db.getTodoListById(id);
    if (data == null) return null;
    return TodoList(
      id: data.id,
      name: data.name,
      color: Color(data.colorHex),
      createdAt: DateTime.fromMillisecondsSinceEpoch(data.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(data.updatedAt),
    );
  }
}
