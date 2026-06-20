import 'package:drift/drift.dart';
import 'package:shopping_assist/core/database/database.dart';

class PurchasesRepository {
  final AppDatabase _db;

  PurchasesRepository(this._db);

  Stream<List<Purchase>> watchPurchasesInGroup(int groupId) =>
      _db.purchasesDao.watchPurchasesInGroup(groupId);

  Stream<List<Purchase>> watchGeneralPurchases() =>
      _db.purchasesDao.watchPurchasesWithoutGroup();

  Future<int> addPurchase(String name, int? groupId) {
    return _db.purchasesDao.insertPurchase(
      PurchasesCompanion.insert(
        name: name,
        purchaseDate: DateTime.now(),
        groupId: Value(groupId),
      ),
    );
  }

  Future<void> deletePurchase(int id) => _db.purchasesDao.deletePurchase(id);
}
