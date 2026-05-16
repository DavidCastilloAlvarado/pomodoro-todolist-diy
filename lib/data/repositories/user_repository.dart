import 'package:uuid/uuid.dart';
import 'package:birdle/data/models/user.dart';
import 'package:birdle/data/services/database.dart';
import 'package:birdle/data/services/storage_service.dart';

class UserRepository {
  UserRepository({
    required BirdleDatabase database,
    required StorageService storage,
  }) : _db = database, _storage = storage;

  final BirdleDatabase _db;
  final StorageService _storage;

  Future<void> saveUser(String name) async {
    final user = User(
      id: const Uuid().v4(),
      name: name,
      createdAt: DateTime.now(),
    );
    await _db.insertUser(UsersData(
      id: user.id,
      name: user.name,
      createdAt: user.createdAt.millisecondsSinceEpoch,
    ));
    await _storage.saveName(name);
  }

  Future<User?> getUser() async {
    final data = await _db.getFirstUser();
    if (data == null) return null;
    return User(
      id: data.id,
      name: data.name,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data.createdAt),
    );
  }

  Future<bool> isFirstLaunch() async {
    return _storage.isFirstLaunch();
  }

  Future<void> completeOnboarding() async {
    await _storage.completeOnboarding();
  }
}
