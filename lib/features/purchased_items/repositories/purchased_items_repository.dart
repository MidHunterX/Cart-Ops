import 'package:drift/drift.dart';
import 'package:shopping_assist/core/database/database.dart';

class PurchasedItemsRepository {
  final AppDatabase _db;

  PurchasedItemsRepository(this._db);

  Stream<List<PurchasedItemWithDetails>> watchPurchasedItems(int purchaseId) {
    return _db.purchasedItemsDao.watchPurchasedItems(purchaseId);
  }

  Future<List<Item>> getAvailableItems(int? groupId) {
    return groupId == null
        ? _db.itemsDao.getItemsWithoutGroup()
        : _db.itemsDao.getItemsInGroup(groupId);
  }

  Future<void> addPurchasedItem({
    required String name,
    required double price,
    required double qty,
    required double discount,
    required bool isWeight,
    required int purchaseId,
    required Group? group,
  }) async {
    final items = await getAvailableItems(group?.id);

    Item? targetItem;
    try {
      targetItem = items.firstWhere(
        (item) => item.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      targetItem = null;
    }

    int itemId;
    if (targetItem != null) {
      itemId = targetItem.id;
    } else {
      itemId = await _db.itemsDao.insertItem(
        ItemsCompanion.insert(
          name: name,
          price: price,
          groupId: Value(group?.id),
        ),
      );
    }

    await _db.purchasedItemsDao.insertPurchasedItem(
      PurchasedItemsCompanion.insert(
        price: price,
        quantity: qty,
        isWeight: Value(isWeight),
        discount: Value(discount),
        purchaseId: purchaseId,
        itemId: itemId,
      ),
    );
  }

  Future<void> deletePurchasedItem(int id) =>
      _db.purchasedItemsDao.deletePurchasedItem(id);
}
