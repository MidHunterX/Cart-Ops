import 'package:drift/drift.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/core/database/daos/purchases_dao.dart';

class PurchasesRepository {
  final PurchasesDao _purchasesDao;

  PurchasesRepository(this._purchasesDao);

  Stream<List<Purchase>> watchPurchasesInGroup(int groupId) =>
      _purchasesDao.watchPurchasesInGroup(groupId);

  Stream<List<Purchase>> watchGeneralPurchases() => _purchasesDao.watchPurchasesWithoutGroup();

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

  Future<void> deletePurchase(int id) => _purchasesDao.deletePurchase(id);
}
