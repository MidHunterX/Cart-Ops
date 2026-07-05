import 'package:drift/drift.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/core/database/models.dart';

part 'purchased_items_dao.g.dart';

@DriftAccessor(tables: [PurchasedItems, Items])
class PurchasedItemsDao extends DatabaseAccessor<AppDatabase> with _$PurchasedItemsDaoMixin {
  PurchasedItemsDao(super.db);

  Stream<List<PurchasedItemWithDetails>> watchPurchasedItems(int purchaseId) {
    final query = select(purchasedItems).join([
      leftOuterJoin(items, items.id.equalsExp(purchasedItems.itemId)),
    ])..where(purchasedItems.purchaseId.equals(purchaseId));

    return query.watch().map((rows) {
      return rows.map((row) {
        return PurchasedItemWithDetails(row.readTable(purchasedItems), row.readTableOrNull(items));
      }).toList();
    });
  }

  Future<int> insertPurchasedItem(PurchasedItemsCompanion purchasedItem) {
    return into(purchasedItems).insert(purchasedItem);
  }

  Future updatePurchasedItem(PurchasedItemsCompanion entry) {
    return (update(purchasedItems)..where((t) => t.id.equals(entry.id.value))).write(entry);
  }

  Future deletePurchasedItem(int id) =>
      (delete(purchasedItems)..where((t) => t.id.equals(id))).go();
}
