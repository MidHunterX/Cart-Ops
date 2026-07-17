import 'package:drift/drift.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/core/database/daos/purchases_dao.dart';

class PurchasesRepository {
  final PurchasesDao _purchasesDao;

  PurchasesRepository(this._purchasesDao);

  Stream<List<Purchase>> watchPurchases([int? groupId]) => _purchasesDao.watchPurchases(groupId);

  Stream<Purchase> watchPurchaseById(int id) => _purchasesDao.watchPurchaseById(id);

  Stream<int> watchPurchasesCount([int? groupId, bool? all]) => all == true
      ? _purchasesDao.watchPurchasesCount(groupId, true)
      : groupId == null
      ? _purchasesDao.watchPurchasesCount(null)
      : _purchasesDao.watchPurchasesCount(groupId);

  Future<Purchase> createPurchase(int? groupId) async {
    final now = DateTime.now();
    final defaultName = 'Purchase';
    final id = await _purchasesDao.insertPurchase(
      PurchasesCompanion.insert(name: defaultName, purchaseDate: now, groupId: Value(groupId)),
    );
    return _purchasesDao.getPurchaseById(id);
  }

  Future<void> updatePurchase(int id, String name, DateTime date) {
    return _purchasesDao.updatePurchase(
      PurchasesCompanion(id: Value(id), name: Value(name), purchaseDate: Value(date)),
    );
  }

  Future<void> updatePurchaseBudget(int id, double? budget) {
    return _purchasesDao.updatePurchase(PurchasesCompanion(id: Value(id), budget: Value(budget)));
  }

  Future<void> updateChecklistMode(int id, bool mode) {
    return _purchasesDao.updatePurchase(
      PurchasesCompanion(id: Value(id), isChecklistMode: Value(mode)),
    );
  }

  Future<void> deletePurchase(int id) => _purchasesDao.deletePurchase(id);
}
