import 'package:drift/drift.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/core/database/daos/groups_dao.dart';

class GroupsRepository {
  final GroupsDao _groupsDao;

  GroupsRepository(this._groupsDao);

  Stream<List<Group>> watchGroups() => _groupsDao.watchGroups();

  Future<int> addGroup(String name, {String? description, String? iconKey}) {
    return _groupsDao.insertGroup(
      GroupsCompanion.insert(name: name, description: Value(description), iconKey: Value(iconKey)),
    );
  }

  Future<bool> updateGroup(int id, String name, {String? description, String? iconKey}) {
    return _groupsDao.updateGroup(
      id,
      GroupsCompanion(name: Value(name), description: Value(description), iconKey: Value(iconKey)),
    );
  }

  Future<void> deleteGroup(int id) => _groupsDao.deleteGroup(id);
}
