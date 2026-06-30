import 'package:drift/drift.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/core/database/models.dart';

part 'items_dao.g.dart';

@DriftAccessor(tables: [Items, PurchasedItems])
class ItemsDao extends DatabaseAccessor<AppDatabase> with _$ItemsDaoMixin {
  ItemsDao(super.db);

  Stream<List<Item>> watchItemsInGroup(int groupId) {
    return (select(items)..where((t) => t.groupId.equals(groupId))).watch();
  }

  Stream<List<Item>> watchItemsWithoutGroup() {
    return (select(items)..where((t) => t.groupId.isNull())).watch();
  }

  // For AutoComplete
  Future<List<Item>> getItemsInGroup(int groupId) {
    return (select(items)..where((t) => t.groupId.equals(groupId))).get();
  }

  Future<List<Item>> getItemsWithoutGroup() {
    return (select(items)..where((t) => t.groupId.isNull())).get();
  }

  Future<Item?> findItemByNameAndGroup(String name, int? groupId) {
    final query = select(items)..where((t) => t.name.equals(name.toLowerCase()));
    if (groupId != null) {
      query.where((t) => t.groupId.equals(groupId));
    } else {
      query.where((t) => t.groupId.isNull());
    }
    return query.getSingleOrNull();
  }

  Future<int> insertItem(ItemsCompanion item) => into(items).insert(item);

  Future<PurchasedItem?> getLastPurchasedDetails(int itemId) async {
    final query = select(purchasedItems)
      ..where((t) => t.itemId.equals(itemId))
      ..orderBy([(t) => OrderingTerm.desc(t.id)])
      ..limit(1);
    return await query.getSingleOrNull();
  }

  Future<bool> hasPurchasedItems(int itemId) async {
    final query = select(purchasedItems)..where((t) => t.itemId.equals(itemId));
    final result = await query.getSingleOrNull();
    return result != null;
  }

  Future<List<PurchasedItem>> getPurchasedItemsForItem(int itemId) {
    return (select(purchasedItems)..where((t) => t.itemId.equals(itemId))).get();
  }

  Future<int> countPurchasesForItem(int itemId) async {
    final query = select(purchasedItems)..where((t) => t.itemId.equals(itemId));
    return await query.get().then((list) => list.length);
  }

  Future<void> updateItem(int id, {String? name, Value<String?> imagePath = const Value.absent()}) {
    final companion = ItemsCompanion(
      name: name != null ? Value(name) : const Value.absent(),
      imagePath: imagePath,
    );
    return (update(items)..where((t) => t.id.equals(id))).write(companion);
  }

  Future<void> updateItemImage(int itemId, String? imagePath) async {
    await (update(
      items,
    )..where((t) => t.id.equals(itemId))).write(ItemsCompanion(imagePath: Value(imagePath)));
  }

  Future deleteItem(int id) async {
    final hasPurchases = await hasPurchasedItems(id);
    if (!hasPurchases) {
      await (delete(items)..where((t) => t.id.equals(id))).go();
    } else {
      throw Exception('Item with id:$id has purchase history');
    }
  }
}
