import 'package:drift/drift.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/features/items/repositories/items_repository.dart';

class PurchasedItemsRepository {
  final AppDatabase _db;
  final ItemsRepository _itemsRepository;

  PurchasedItemsRepository(this._db) : _itemsRepository = ItemsRepository(_db);

  Stream<List<PurchasedItemWithDetails>> watchPurchasedItems(int purchaseId) {
    return _db.purchasedItemsDao.watchPurchasedItems(purchaseId);
  }

  Future<List<Item>> getAvailableItems(int? groupId) {
    return groupId == null
        ? _itemsRepository.getItemsWithoutGroup()
        : _itemsRepository.getItemsInGroup(groupId);
  }

  Future<void> addPurchasedItem({
    required String name,
    required double price,
    required double qty,
    required double discount,
    required bool isWeight,
    required int purchaseId,
    required Group? group,
    String? imagePath,
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
      if (imagePath != null) {
        await (_db.update(_db.items)..where((t) => t.id.equals(itemId))).write(
          ItemsCompanion(imagePath: Value(imagePath)),
        );
      }
    } else {
      itemId = await _itemsRepository.insertItem(
        ItemsCompanion.insert(
          name: name,
          groupId: Value(group?.id),
          imagePath: Value(imagePath),
        ),
      );
    }

    final totalPrice = price * qty;
    final finalPrice = totalPrice - discount;

    await _db.purchasedItemsDao.insertPurchasedItem(
      PurchasedItemsCompanion.insert(
        price: finalPrice,
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
