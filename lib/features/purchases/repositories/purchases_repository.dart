import 'package:drift/drift.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/core/database/daos/purchases_dao.dart';

class PurchasesRepository {
  final PurchasesDao _purchasesDao;

  PurchasesRepository(this._purchasesDao);

  Stream<List<Purchase>> watchPurchasesInGroup(int groupId) =>
      _purchasesDao.watchPurchasesInGroup(groupId);

  Stream<List<Purchase>> watchGeneralPurchases() => _purchasesDao.watchPurchasesWithoutGroup();

  Future<int> addPurchase(String name, int? groupId) {
    return _purchasesDao.insertPurchase(
      PurchasesCompanion.insert(name: name, purchaseDate: DateTime.now(), groupId: Value(groupId)),
    );
  }

  Future<void> deletePurchase(int id) => _purchasesDao.deletePurchase(id);
}
