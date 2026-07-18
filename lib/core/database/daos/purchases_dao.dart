import 'package:drift/drift.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/core/database/models.dart';

part 'purchases_dao.g.dart';

@DriftAccessor(tables: [Purchases, PurchasedItems])
class PurchasesDao extends DatabaseAccessor<AppDatabase> with _$PurchasesDaoMixin {
  PurchasesDao(super.db);

  Stream<List<Purchase>> watchPurchases([int? groupId]) {
    if (groupId == null) {
      return (select(purchases)
            ..where((t) => t.groupId.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.purchaseDate)]))
          .watch();
    }
    return (select(purchases)
          ..where((t) => t.groupId.equals(groupId))
          ..orderBy([(t) => OrderingTerm.desc(t.purchaseDate)]))
        .watch();
  }

  Stream<Purchase> watchPurchaseById(int id) {
    return (select(purchases)..where((t) => t.id.equals(id))).watchSingle();
  }

  Stream<int> watchPurchasesCount([int? groupId, bool? all]) {
    var query = select(purchases);
    if (all != true) {
      if (groupId != null) {
        query = query..where((t) => t.groupId.equals(groupId));
      } else {
        query = query..where((t) => t.groupId.isNull());
      }
    }
    return query.watch().map((rows) => rows.length);
  }

  Future<int> insertPurchase(PurchasesCompanion purchase) {
    return into(purchases).insert(purchase);
  }

  Future<Purchase> getPurchaseById(int id) {
    return (select(purchases)..where((t) => t.id.equals(id))).getSingle();
  }

  /*Future<int> getPurchasesCount([int? groupId, bool? all]) {
    var query = select(purchases);
    if (all != true) {
      if (groupId != null) {
        query.where((t) => t.groupId.equals(groupId));
      } else {
        query.where((t) => t.groupId.isNull());
      }
    }
    return query.get().then((rows) => rows.length);
  }*/

  Future<void> updatePurchase(PurchasesCompanion entry) {
    return (update(purchases)..where((t) => t.id.equals(entry.id.value))).write(entry);
  }

  Future deletePurchase(int id) => (delete(purchases)..where((t) => t.id.equals(id))).go();

  Future<void> recalculatePurchaseTotal(int purchaseId) async {
    final items = await (select(
      purchasedItems,
    )..where((t) => t.purchaseId.equals(purchaseId))).get();
    double total = 0.0;
    for (final item in items) {
      final price = item.price ?? 0.0;
      final qty = item.quantity ?? 0.0;
      final discountPercent = item.discount;
      final discountAmount = price * (discountPercent / 100);
      total += ((price - discountAmount) * qty);
    }
    await (update(
      purchases,
    )..where((t) => t.id.equals(purchaseId))).write(PurchasesCompanion(totalPrice: Value(total)));
  }
}
