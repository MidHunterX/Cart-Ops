import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/core/database/daos/groups_dao.dart';

class GroupsRepository {
  final GroupsDao _groupsDao;

  GroupsRepository(this._groupsDao);

  Stream<List<Group>> watchGroups() => _groupsDao.watchGroups();

  Future<int> addGroup(String name) {
    return _groupsDao.insertGroup(GroupsCompanion.insert(name: name));
  }

  Future<void> deleteGroup(int id) => _groupsDao.deleteGroup(id);
}
