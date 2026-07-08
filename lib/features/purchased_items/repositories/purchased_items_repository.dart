import 'dart:io';

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
    required double? price,
    required double? qty,
    required double? discount,
    required bool isWeight,
    required int purchaseId,
    required Group? group,
    Value<String?> imagePath = const Value.absent(),
  }) async {
    Item? targetItem;

    if (itemId != null) {
      targetItem = await _itemsDao.findItem(itemId, group?.id);
    }

    int? finalItemId;
    if (targetItem != null) {
      finalItemId = targetItem.id;
      if (imagePath.present) {
        await _itemsDao.updateItemImage(finalItemId, imagePath.value);
      }
    } else {
      final trimmedName = name.trim();
      if (trimmedName.isNotEmpty && price != null && qty != null) {
        finalItemId = await _itemsDao.insertItem(
          ItemsCompanion.insert(name: trimmedName, groupId: Value(group?.id), imagePath: imagePath),
        );
      }
    }

    await _purchasedItemsDao.insertPurchasedItem(
      PurchasedItemsCompanion.insert(
        name: Value(name.trim().isEmpty ? null : name.trim()),
        imagePath: imagePath,
        price: Value(price),
        quantity: Value(qty),
        isWeight: Value(isWeight),
        discount: Value(discount ?? 0.0),
        purchaseId: purchaseId,
        itemId: Value(finalItemId),
      ),
    );
  }

  Future<void> updatePurchasedItem({
    required int id,
    int? itemId,
    String? name,
    required double? price,
    required double? qty,
    required double discount,
    required bool isWeight,
    int? groupId,
    Value<String?> imagePath = const Value.absent(),
  }) async {
    int? finalItemId = itemId;

    bool isNewItemRequired = name != null && price != null && qty != null;

    if (isNewItemRequired) {
      Item? targetItem;
      if (itemId != null && itemId != -1) {
        targetItem = await _itemsDao.findItem(itemId, groupId);
      }

      if (targetItem != null) {
        finalItemId = targetItem.id;
        if (imagePath.present) {
          await _itemsDao.updateItemImage(finalItemId, imagePath.value);
        }
      } else {
        final trimmedName = name.trim();
        if (trimmedName.isNotEmpty) {
          finalItemId = await _itemsDao.insertItem(
            ItemsCompanion.insert(name: trimmedName, groupId: Value(groupId), imagePath: imagePath),
          );
        }
      }
    }

    await _purchasedItemsDao.updatePurchasedItem(
      PurchasedItemsCompanion(
        id: Value(id),
        name: name != null ? Value(name.trim().isEmpty ? null : name.trim()) : const Value.absent(),
        itemId: isNewItemRequired ? Value(finalItemId) : const Value.absent(),
        price: Value(price),
        quantity: Value(qty),
        discount: Value(discount),
        isWeight: Value(isWeight),
        imagePath: imagePath,
      ),
    );
  }

  Future<void> deletePurchasedItem(int id) async {
    final purchasedItem = await _purchasedItemsDao.getPurchasedItem(id);
    if (purchasedItem != null && purchasedItem.imagePath != null) {
      try {
        final file = File(purchasedItem.imagePath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // Silent fail
      }
    }
    await _purchasedItemsDao.deletePurchasedItem(id);
  }
}
