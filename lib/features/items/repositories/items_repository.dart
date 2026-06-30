import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/core/database/daos/items_dao.dart';

class ItemsRepository {
  final ItemsDao _itemsDao;

  ItemsRepository(this._itemsDao);

  Stream<List<Item>> watchItemsInGroup(int groupId) {
    return _itemsDao.watchItemsInGroup(groupId);
  }

  Stream<List<Item>> watchItemsWithoutGroup() {
    return _itemsDao.watchItemsWithoutGroup();
  }

  Future<List<Item>> getItemsInGroup(int groupId) {
    return _itemsDao.getItemsInGroup(groupId);
  }

  Future<List<Item>> getItemsWithoutGroup() {
    return _itemsDao.getItemsWithoutGroup();
  }

  Future<Item?> findItemByNameAndGroup(String name, int? groupId) {
    return _itemsDao.findItemByNameAndGroup(name, groupId);
  }

  Future<int> insertItem(ItemsCompanion item) {
    return _itemsDao.insertItem(item);
  }

  Future<PurchasedItem?> getLastPurchasedDetails(int itemId) {
    return _itemsDao.getLastPurchasedDetails(itemId);
  }

  Future<bool> hasPurchasedItems(int itemId) {
    return _itemsDao.hasPurchasedItems(itemId);
  }

  Future<void> deleteItem(int id) {
    return _itemsDao.deleteItem(id);
  }

  Future<List<Item>> searchItems(String query, {int? groupId}) async {
    final items = groupId != null ? await getItemsInGroup(groupId) : await getItemsWithoutGroup();

    return items.where((item) => item.name.toLowerCase().contains(query.toLowerCase())).toList();
  }
}
