import 'package:drift/drift.dart';
import 'package:shopping_assist/database/database.dart';
import 'package:shopping_assist/database/models.dart';

part 'items_dao.g.dart';

@DriftAccessor(tables: [Items])
class ItemsDao extends DatabaseAccessor<AppDatabase> with _$ItemsDaoMixin {
  ItemsDao(super.db);

  Stream<List<Item>> watchItemsInGroup(int groupId) {
    return (select(items)..where((t) => t.groupId.equals(groupId))).watch();
  }

  // For AutoComplete
  Future<List<Item>> getItemsInGroup(int groupId) {
    return (select(items)..where((t) => t.groupId.equals(groupId))).get();
  }

  Future<int> insertItem(ItemsCompanion item) => into(items).insert(item);

  Future deleteItem(int id) =>
      (delete(items)..where((t) => t.id.equals(id))).go();
}
