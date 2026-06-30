import 'package:drift/drift.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/core/database/daos/items_dao.dart';
import 'package:shopping_assist/core/database/daos/purchased_items_dao.dart';

class PurchasedItemsRepository {
  final PurchasedItemsDao _purchasedItemsDao;
  final ItemsDao _itemsDao;

  PurchasedItemsRepository(this._purchasedItemsDao, this._itemsDao);

  Stream<List<PurchasedItemWithDetails>> watchPurchasedItems(int purchaseId) {
    return _purchasedItemsDao.watchPurchasedItems(purchaseId);
  }

  Future<List<Item>> getAvailableItems(int? groupId) {
    return groupId == null ? _itemsDao.getItemsWithoutGroup() : _itemsDao.getItemsInGroup(groupId);
  }

  Future<void> addPurchasedItem({
    required String name,
    required double price,
    required double qty,
    required double discount,
    required bool isWeight,
    required int purchaseId,
    required Group? group,
    Value<String?> imagePath = const Value.absent(),
  }) async {
    final targetItem = await _itemsDao.findItemByNameAndGroup(name, group?.id);

    int itemId;
    if (targetItem != null) {
      itemId = targetItem.id;
      if (imagePath.present) {
        await _itemsDao.updateItemImage(itemId, imagePath.value);
      }
    } else {
      itemId = await _itemsDao.insertItem(
        ItemsCompanion.insert(name: name, groupId: Value(group?.id), imagePath: imagePath),
      );
    }

    await _purchasedItemsDao.insertPurchasedItem(
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

  Future<void> updatePurchasedItem({
    required int id,
    required double price,
    required double qty,
    required double discount,
    required bool isWeight,
  }) async {
    await _purchasedItemsDao.updatePurchasedItem(
      PurchasedItemsCompanion(
        id: Value(id),
        price: Value(price),
        quantity: Value(qty),
        discount: Value(discount),
        isWeight: Value(isWeight),
      ),
    );
  }

  Future<void> deletePurchasedItem(int id) => _purchasedItemsDao.deletePurchasedItem(id);
}
