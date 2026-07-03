import 'package:drift/drift.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/core/database/models.dart';

part 'purchases_dao.g.dart';

@DriftAccessor(tables: [Purchases])
class PurchasesDao extends DatabaseAccessor<AppDatabase> with _$PurchasesDaoMixin {
  PurchasesDao(super.db);

  Stream<List<Purchase>> watchPurchasesInGroup(int groupId) {
    return (select(purchases)
          ..where((t) => t.groupId.equals(groupId))
          ..orderBy([(t) => OrderingTerm.desc(t.purchaseDate)]))
        .watch();
  }

  Stream<List<Purchase>> watchPurchasesWithoutGroup() {
    return (select(purchases)
          ..where((t) => t.groupId.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.purchaseDate)]))
        .watch();
  }

  Future<int> insertPurchase(PurchasesCompanion purchase) {
    return into(purchases).insert(purchase);
  }

  Future<Purchase> getPurchaseById(int id) {
    return (select(purchases)..where((t) => t.id.equals(id))).getSingle();
  }

  Future<void> updatePurchase(PurchasesCompanion entry) {
    return (update(purchases)..where((t) => t.id.equals(entry.id.value))).write(entry);
  }

  Future deletePurchase(int id) => (delete(purchases)..where((t) => t.id.equals(id))).go();
}
