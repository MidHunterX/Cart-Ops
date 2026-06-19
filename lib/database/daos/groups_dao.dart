import 'package:drift/drift.dart';
import 'package:shopping_assist/database/database.dart';
import 'package:shopping_assist/database/models.dart';

part 'groups_dao.g.dart';

@DriftAccessor(tables: [Groups])
class GroupsDao extends DatabaseAccessor<AppDatabase> with _$GroupsDaoMixin {
  GroupsDao(super.db);

  Stream<List<Group>> watchGroups() => select(groups).watch();

  Future<int> insertGroup(String name) {
    return into(groups).insert(GroupsCompanion.insert(name: name));
  }

  Future deleteGroup(int id) =>
      (delete(groups)..where((t) => t.id.equals(id))).go();
}
