import 'package:shopping_assist/core/database/database.dart';

class GroupsRepository {
  final AppDatabase _db;

  GroupsRepository(this._db);

  Stream<List<Group>> watchGroups() => _db.groupsDao.watchGroups();

  Future<int> addGroup(String name) {
    return _db.groupsDao.insertGroup(GroupsCompanion.insert(name: name));
  }

  Future<void> deleteGroup(int id) => _db.groupsDao.deleteGroup(id);
}
