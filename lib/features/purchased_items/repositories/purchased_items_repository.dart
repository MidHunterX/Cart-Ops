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
    int? itemId,
    required String name,
    required double price,
    required double qty,
    required double discount,
    required bool isWeight,
    required int purchaseId,
    required Group? group,
    Value<String?> imagePath = const Value.absent(),
  }) async {
    Item? targetItem;

    if (itemId != null) {
      targetItem = await _itemsDao.findItemByIdAndGroup(itemId, group?.id);
    }

    int finalItemId;
    if (targetItem != null) {
      finalItemId = targetItem.id;
      if (imagePath.present) {
        await _itemsDao.updateItemImage(finalItemId, imagePath.value);
      }
    } else {
      finalItemId = await _itemsDao.insertItem(
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
        itemId: finalItemId,
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
