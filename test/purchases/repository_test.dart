import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/features/groups/repositories/groups_repository.dart';
import 'package:shopping_assist/features/purchases/repositories/purchases_repository.dart';

void main() {
  late AppDatabase database;
  late PurchasesRepository purchasesRepository;
  late GroupsRepository groupsRepository;

  setUp(() {
    database = AppDatabase.forTesting(
      DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
    );
    purchasesRepository = PurchasesRepository(database.purchasesDao);
    groupsRepository = GroupsRepository(database.groupsDao);
  });

  tearDown(() async {
    await database.close();
  });

  group('PurchasesRepository Tests', () {
    test('createPurchase inserts a new purchase entity referencing group', () async {
      final groupId = await groupsRepository.addGroup('Supermarket');
      final purchase = await purchasesRepository.createPurchase(groupId);
      expect(purchase.id, isPositive);
      expect(purchase.name, 'Purchase');
      expect(purchase.groupId, groupId);
    });

    test('watchPurchasesInGroup isolates and filters correctly', () async {
      final groupId1 = await groupsRepository.addGroup('Group 1');
      final groupId2 = await groupsRepository.addGroup('Group 2');
      await purchasesRepository.createPurchase(groupId1);
      final purchase2 = await purchasesRepository.createPurchase(groupId1);
      await purchasesRepository.updatePurchase(purchase2.id, 'Updated Purchase', DateTime.now());
      await purchasesRepository.createPurchase(groupId2);
      final group1Purchases = await purchasesRepository.watchPurchases(groupId1).first;
      expect(group1Purchases.length, 2);
      expect(group1Purchases.any((p) => p.name == 'Updated Purchase'), isTrue);
      final group2Purchases = await purchasesRepository.watchPurchases(groupId2).first;
      expect(group2Purchases.length, 1);
    });

    test('watchGeneralPurchases watches only purchases without a group', () async {
      final groupId = await groupsRepository.addGroup('Work');
      await purchasesRepository.createPurchase(groupId);
      await purchasesRepository.createPurchase(null);
      await purchasesRepository.createPurchase(null);
      final generalPurchases = await purchasesRepository.watchPurchases().first;
      expect(generalPurchases.length, 2);
      expect(generalPurchases.every((p) => p.groupId == null), isTrue);
    });

    test('watchPurchaseById streams updates of a specific purchase', () async {
      final purchase = await purchasesRepository.createPurchase(null);
      final initial = await purchasesRepository.watchPurchaseById(purchase.id).first;
      expect(initial.name, 'Purchase');
      final updatedDate = DateTime.now();
      await purchasesRepository.updatePurchase(purchase.id, 'New Purchase Name', updatedDate);
      final updated = await purchasesRepository.watchPurchaseById(purchase.id).first;
      expect(updated.name, 'New Purchase Name');
    });

    test('updatePurchaseBudget persists numeric values effectively', () async {
      final purchase = await purchasesRepository.createPurchase(null);
      expect(purchase.budget, null);
      await purchasesRepository.updatePurchaseBudget(purchase.id, 150.0);
      final updatedPurchase = await purchasesRepository.watchPurchaseById(purchase.id).first;
      expect(updatedPurchase.budget, 150.0);
    });

    test('deletePurchase deletes the purchase record', () async {
      final purchase = await purchasesRepository.createPurchase(null);
      final generalPurchasesBefore = await purchasesRepository.watchPurchases().first;
      expect(generalPurchasesBefore.any((p) => p.id == purchase.id), isTrue);
      await purchasesRepository.deletePurchase(purchase.id);
      final generalPurchasesAfter = await purchasesRepository.watchPurchases().first;
      expect(generalPurchasesAfter.any((p) => p.id == purchase.id), isFalse);
    });
  });
}
