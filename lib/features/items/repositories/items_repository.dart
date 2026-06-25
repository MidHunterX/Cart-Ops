import 'package:shopping_assist/core/database/database.dart';

class ItemsRepository {
  final AppDatabase _db;

  ItemsRepository(this._db);

  Stream<List<Item>> watchItemsInGroup(int groupId) {
    return _db.itemsDao.watchItemsInGroup(groupId);
  }

  Future<List<Item>> getItemsInGroup(int groupId) {
    return _db.itemsDao.getItemsInGroup(groupId);
  }

  Future<List<Item>> getItemsWithoutGroup() {
    return _db.itemsDao.getItemsWithoutGroup();
  }

  Future<int> insertItem(ItemsCompanion item) {
    return _db.itemsDao.insertItem(item);
  }

  Future<double?> getLastPurchasedPrice(int itemId) {
    return _db.itemsDao.getLastPurchasedPrice(itemId);
  }

  Future<bool> hasPurchasedItems(int itemId) {
    return _db.itemsDao.hasPurchasedItems(itemId);
  }

  Future<void> deleteItem(int id) {
    return _db.itemsDao.deleteItem(id);
  }

  Future<Item?> getItemById(int id) async {
    final query = _db.select(_db.items)..where((t) => t.id.equals(id));
    return await query.getSingleOrNull();
  }

  Future<List<Item>> searchItems(String query, {int? groupId}) async {
    final items = groupId != null
        ? await getItemsInGroup(groupId)
        : await getItemsWithoutGroup();

    return items
        .where((item) => item.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
