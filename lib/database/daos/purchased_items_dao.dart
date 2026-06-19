import 'package:drift/drift.dart';
import 'package:shopping_assist/database/database.dart';
import 'package:shopping_assist/database/models.dart';

part 'purchased_items_dao.g.dart';

class PurchasedItemWithDetails {
  final PurchasedItem purchasedItem;
  final Item item;

  PurchasedItemWithDetails(this.purchasedItem, this.item);
}

@DriftAccessor(tables: [PurchasedItems, Items])
class PurchasedItemsDao extends DatabaseAccessor<AppDatabase>
    with _$PurchasedItemsDaoMixin {
  PurchasedItemsDao(super.db);

  Stream<List<PurchasedItemWithDetails>> watchPurchasedItems(int purchaseId) {
    final query = select(purchasedItems).join([
      innerJoin(items, items.id.equalsExp(purchasedItems.itemId)),
    ])..where(purchasedItems.purchaseId.equals(purchaseId));

    return query.watch().map((rows) {
      return rows.map((row) {
        return PurchasedItemWithDetails(
          row.readTable(purchasedItems),
          row.readTable(items),
        );
      }).toList();
    });
  }

  Future<int> insertPurchasedItem(PurchasedItemsCompanion purchasedItem) {
    return into(purchasedItems).insert(purchasedItem);
  }

  Future deletePurchasedItem(int id) =>
      (delete(purchasedItems)..where((t) => t.id.equals(id))).go();
}
