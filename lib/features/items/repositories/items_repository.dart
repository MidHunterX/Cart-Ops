import 'dart:io';

import 'package:drift/drift.dart';
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

  Future<Item?> findItem(int id, int? groupId) {
    return _itemsDao.findItem(id, groupId);
  }

  Future<int> insertItem({required String name, int? groupId, String? imagePath}) {
    return _itemsDao.insertItem(
      ItemsCompanion.insert(name: name, groupId: Value(groupId), imagePath: Value(imagePath)),
    );
  }

  Future<List<PurchasedItem>> getPurchasedItemsForItem(int itemId) =>
      _itemsDao.getPurchasedItemsForItem(itemId);

  Future<List<PurchasedItemWithPurchase>> getPurchaseHistoryForItem(int itemId) =>
      _itemsDao.getPurchaseHistoryForItem(itemId);

  Future<int> countPurchasesForItem(int itemId) => _itemsDao.countPurchasesForItem(itemId);

  Future<void> updateItem(
    int id, {
    String? name,
    Value<String?> imagePath = const Value.absent(),
  }) async {
    if (imagePath.present) {
      final oldItem = await _itemsDao.getItemById(id);
      final oldImagePath = oldItem?.imagePath;
      if (oldImagePath != null && oldImagePath != imagePath.value) {
        try {
          final oldFile = File(oldImagePath);
          if (await oldFile.exists()) {
            await oldFile.delete();
          }
        } catch (_) {}
      }
    }
    await _itemsDao.updateItem(id, name: name, imagePath: imagePath);
  }

  Future<PurchasedItem?> getLastPurchasedDetails(int itemId) {
    return _itemsDao.getLastPurchasedDetails(itemId);
  }

  Future<bool> hasPurchasedItems(int itemId) {
    return _itemsDao.hasPurchasedItems(itemId);
  }

  Future<bool> deleteItem(int id) async {
    final item = await _itemsDao.getItemById(id);
    final deleted = await _itemsDao.deleteItem(id);

    if (!deleted) throw Exception('Failed to delete item with id: $id');

    if (item?.imagePath != null) {
      final file = File(item!.imagePath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    return deleted;
  }

  Future<List<Item>> searchItems(String query, {int? groupId}) async {
    final items = groupId != null ? await getItemsInGroup(groupId) : await getItemsWithoutGroup();

    return items.where((item) => item.name.toLowerCase().contains(query.toLowerCase())).toList();
  }
}
