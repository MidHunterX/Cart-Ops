import 'package:drift/drift.dart';
import 'package:shopping_assist/database/database.dart';
import 'package:shopping_assist/database/models.dart';

part 'purchases_dao.g.dart';

@DriftAccessor(tables: [Purchases])
class PurchasesDao extends DatabaseAccessor<AppDatabase>
    with _$PurchasesDaoMixin {
  PurchasesDao(super.db);

  Stream<List<Purchase>> watchPurchasesInGroup(int groupId) {
    return (select(purchases)..where((t) => t.groupId.equals(groupId))).watch();
  }

  Stream<List<Purchase>> watchPurchasesWithoutGroup() {
    return (select(purchases)..where((t) => t.groupId.isNull())).watch();
  }

  Future<int> insertPurchase(PurchasesCompanion purchase) {
    return into(purchases).insert(purchase);
  }

  Future deletePurchase(int id) =>
      (delete(purchases)..where((t) => t.id.equals(id))).go();
}
