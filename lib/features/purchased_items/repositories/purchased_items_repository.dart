import 'dart:io';

import 'package:drift/drift.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/core/database/daos/items_dao.dart';
import 'package:shopping_assist/core/database/daos/purchases_dao.dart';
import 'package:shopping_assist/core/database/daos/purchased_items_dao.dart';

class PurchasedItemsRepository {
  final PurchasedItemsDao _purchasedItemsDao;
  final ItemsDao _itemsDao;
  final PurchasesDao _purchasesDao;

  PurchasedItemsRepository(this._purchasedItemsDao, this._itemsDao, this._purchasesDao);

  Stream<List<PurchasedItemWithDetails>> watchPurchasedItems(int purchaseId) {
    return _purchasedItemsDao.watchPurchasedItems(purchaseId);
  }

  Future<List<Item>> getAvailableItems(int? groupId) {
    return groupId == null ? _itemsDao.getItemsWithoutGroup() : _itemsDao.getItemsInGroup(groupId);
  }

  Future<int> addPurchasedItem({
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
    // By default, the purchased item retains the image unless it's transferred.
    Value<String?> finalPurchasedItemImagePath = imagePath;

    if (targetItem != null) {
      finalItemId = targetItem.id;
      if (imagePath.present) {
        if (targetItem.imagePath != null && targetItem.imagePath != imagePath.value) {
          try {
            final oldFile = File(targetItem.imagePath!);
            if (await oldFile.exists()) {
              await oldFile.delete();
            }
          } catch (_) {}
        }
        await _itemsDao.updateItemImage(finalItemId, imagePath.value);
        // Transfer ownership to the existing main item
        finalPurchasedItemImagePath = const Value<String?>(null);
      }
    } else {
      final trimmedName = name.trim();
      if (trimmedName.isNotEmpty && price != null && qty != null) {
        finalItemId = await _itemsDao.insertItem(
          ItemsCompanion.insert(name: trimmedName, groupId: Value(group?.id), imagePath: imagePath),
        );
        // Transfer ownership to the newly created item
        finalPurchasedItemImagePath = const Value<String?>(null);
      }
    }

    int newItemId = await _purchasedItemsDao.insertPurchasedItem(
      PurchasedItemsCompanion.insert(
        name: Value(name.trim().isEmpty ? null : name.trim()),
        imagePath: finalPurchasedItemImagePath,
        price: Value(price),
        quantity: Value(qty),
        isWeight: Value(isWeight),
        discount: Value(discount ?? 0.0),
        purchaseId: purchaseId,
        itemId: Value(finalItemId),
      ),
    );

    await _purchasesDao.recalculatePurchaseTotal(purchaseId);

    return newItemId;
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
    int? finalGroupId = groupId;

    final existingPurchasedItem = await _purchasedItemsDao.getPurchasedItem(id);
    if (existingPurchasedItem != null) {
      final purchase = await _purchasesDao.getPurchaseById(existingPurchasedItem.purchaseId);
      finalGroupId = purchase.groupId;
    }

    bool isItemRequirementsMet =
        name != null && name.trim().isNotEmpty && price != null && qty != null;

    // EDGE CASE: If a new image is provided right before handover, clean up
    // the old image owned by the PurchasedItem so it doesn't get orphaned.
    if (imagePath.present && existingPurchasedItem != null) {
      if (existingPurchasedItem.imagePath != null &&
          existingPurchasedItem.imagePath != imagePath.value) {
        try {
          final oldFile = File(existingPurchasedItem.imagePath!);
          if (await oldFile.exists()) {
            await oldFile.delete();
          }
        } catch (_) {}
      }
    }

    Value<String?> finalPurchasedItemImagePath = imagePath;

    if (isItemRequirementsMet) {
      Item? targetItem;
      if (itemId != null) {
        targetItem = await _itemsDao.findItem(itemId, groupId);
      }

      if (targetItem != null) {
        finalItemId = targetItem.id;
        if (imagePath.present) {
          if (targetItem.imagePath != null && targetItem.imagePath != imagePath.value) {
            try {
              final oldFile = File(targetItem.imagePath!);
              if (await oldFile.exists()) {
                await oldFile.delete();
              }
            } catch (_) {}
          }
          await _itemsDao.updateItemImage(finalItemId, imagePath.value);
          // Transfer ownership to existing linked item
          finalPurchasedItemImagePath = const Value<String?>(null);
        }
      } else {
        final trimmedName = name.trim();
        if (trimmedName.isNotEmpty) {
          // Identify which image to pass: the new one if supplied, else the existing one
          String? imageToTransfer = imagePath.present
              ? imagePath.value
              : existingPurchasedItem?.imagePath;

          finalItemId = await _itemsDao.insertItem(
            ItemsCompanion.insert(
              name: trimmedName,
              groupId: Value(finalGroupId),
              imagePath: Value(imageToTransfer),
            ),
          );

          // OWNERSHIP TRANSFER: Because the new item now owns the image, we strip
          // it from the PurchasedItem to maintain a single source of truth.
          finalPurchasedItemImagePath = const Value<String?>(null);
        }
      }
    }

    await _purchasedItemsDao.updatePurchasedItem(
      PurchasedItemsCompanion(
        id: Value(id),
        name: name != null ? Value(name.trim().isEmpty ? null : name.trim()) : const Value.absent(),
        itemId: isItemRequirementsMet ? Value(finalItemId) : const Value.absent(),
        price: Value(price),
        quantity: Value(qty),
        discount: Value(discount),
        isWeight: Value(isWeight),
        imagePath: finalPurchasedItemImagePath,
      ),
    );

    if (existingPurchasedItem != null) {
      await _purchasesDao.recalculatePurchaseTotal(existingPurchasedItem.purchaseId);
    }
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

    if (purchasedItem != null) {
      await _purchasesDao.recalculatePurchaseTotal(purchasedItem.purchaseId);
    }
  }

  Future<void> toggleItemCheck(int id, bool isChecked) {
    return _purchasedItemsDao.updatePurchasedItem(
      PurchasedItemsCompanion(id: Value(id), isChecked: Value(isChecked)),
    );
  }

  Future<void> setAllItemsCheckState(int purchaseId, bool isChecked) {
    return _purchasedItemsDao.setAllItemsCheckState(purchaseId, isChecked);
  }
}
