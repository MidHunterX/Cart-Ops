import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/features/groups/repositories/groups_repository.dart';
import 'package:shopping_assist/features/purchases/repositories/purchases_repository.dart';
import 'package:shopping_assist/features/purchased_items/repositories/purchased_items_repository.dart';
import 'package:shopping_assist/features/items/repositories/items_repository.dart';

void main() {
  late AppDatabase database;
  late PurchasedItemsRepository purchasedItemsRepository;
  late PurchasesRepository purchasesRepository;
  late GroupsRepository groupsRepository;
  late ItemsRepository itemsRepository;
  late Directory tempDir;

  setUp(() {
    database = AppDatabase.forTesting(
      DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
    );
    purchasedItemsRepository = PurchasedItemsRepository(
      database.purchasedItemsDao,
      database.itemsDao,
    );
    purchasesRepository = PurchasesRepository(database.purchasesDao);
    groupsRepository = GroupsRepository(database.groupsDao);
    itemsRepository = ItemsRepository(database.itemsDao);
    tempDir = Directory.systemTemp.createTempSync();
  });

  tearDown(() async {
    await database.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('PurchasedItemsRepository Tests', () {
    test('addPurchasedItem creates both Item and PurchasedItem together', () async {
      final groupId = await groupsRepository.addGroup('Groceries');
      final purchase = await purchasesRepository.createPurchase(groupId);
      final group = await database.groupsDao.watchGroups().first.then((g) => g.first);
      await purchasedItemsRepository.addPurchasedItem(
        name: 'Milk',
        price: 3.5,
        qty: 2.0,
        discount: 0.0,
        isWeight: false,
        purchaseId: purchase.id,
        group: group,
      );
      final purchasedItems = await purchasedItemsRepository.watchPurchasedItems(purchase.id).first;
      expect(purchasedItems.length, 1);
      expect(purchasedItems.first.purchasedItem.name, 'Milk');
      expect(purchasedItems.first.purchasedItem.price, 3.5);
      final items = await itemsRepository.getItemsInGroup(groupId);
      expect(items.length, 1);
      expect(items.first.name, 'Milk');
      expect(purchasedItems.first.purchasedItem.itemId, items.first.id);
    });

    test('addPurchasedItem uses existing itemId when provided', () async {
      final itemId = await itemsRepository.insertItem(name: 'Apple Juice');
      final purchase = await purchasesRepository.createPurchase(null);
      await purchasedItemsRepository.addPurchasedItem(
        itemId: itemId,
        name: 'Apple Juice Extra',
        price: 2.5,
        qty: 1.0,
        discount: 0.0,
        isWeight: false,
        purchaseId: purchase.id,
        group: null,
        imagePath: const Value('new_apple_juice.png'),
      );
      final purchasedItems = await purchasedItemsRepository.watchPurchasedItems(purchase.id).first;
      expect(purchasedItems.length, 1);
      expect(purchasedItems.first.purchasedItem.itemId, itemId);
      final updatedItem = await itemsRepository.findItem(itemId, null);
      expect(updatedItem?.imagePath, 'new_apple_juice.png');
    });

    test('updatePurchasedItem merges field updates seamlessly', () async {
      final purchase = await purchasesRepository.createPurchase(null);
      await purchasedItemsRepository.addPurchasedItem(
        name: 'Bread',
        price: 2.0,
        qty: 1.0,
        discount: 0.0,
        isWeight: false,
        purchaseId: purchase.id,
        group: null,
      );
      final purchasedItems = await purchasedItemsRepository.watchPurchasedItems(purchase.id).first;
      final itemToUpdate = purchasedItems.first;
      await purchasedItemsRepository.updatePurchasedItem(
        id: itemToUpdate.purchasedItem.id,
        itemId: itemToUpdate.purchasedItem.itemId,
        name: 'Whole Wheat Bread',
        price: 2.5,
        qty: 2.0,
        discount: 0.5,
        isWeight: false,
        groupId: null,
      );
      final updatedItems = await purchasedItemsRepository.watchPurchasedItems(purchase.id).first;
      final updatedItem = updatedItems.first.purchasedItem;
      expect(updatedItem.name, 'Whole Wheat Bread');
      expect(updatedItem.price, 2.5);
      expect(updatedItem.quantity, 2.0);
      expect(updatedItem.discount, 0.5);
    });

    test(
      'updatePurchasedItem creates a new global Item if name is updated but target item does not exist',
      () async {
        final purchase = await purchasesRepository.createPurchase(null);
        await purchasedItemsRepository.addPurchasedItem(
          name: 'Cookie',
          price: 1.0,
          qty: 5.0,
          discount: 0.0,
          isWeight: false,
          purchaseId: purchase.id,
          group: null,
        );
        final purchasedItems = await purchasedItemsRepository
            .watchPurchasedItems(purchase.id)
            .first;
        final itemToUpdate = purchasedItems.first;
        await purchasedItemsRepository.updatePurchasedItem(
          id: itemToUpdate.purchasedItem.id,
          itemId: -1,
          name: 'Premium Cookie',
          price: 1.5,
          qty: 5.0,
          discount: 0.0,
          isWeight: false,
          groupId: null,
        );
        final updatedItems = await purchasedItemsRepository.watchPurchasedItems(purchase.id).first;
        final updatedItem = updatedItems.first.purchasedItem;
        expect(updatedItem.name, 'Premium Cookie');
        expect(updatedItem.price, 1.5);
        expect(updatedItem.itemId, isNotNull);
        expect(updatedItem.itemId, isNot(itemToUpdate.purchasedItem.itemId));
        final globalItem = await itemsRepository.findItem(updatedItem.itemId!, null);
        expect(globalItem?.name, 'Premium Cookie');
      },
    );

    test('deletePurchasedItem removes record and deletes local image file if exists', () async {
      final purchase = await purchasesRepository.createPurchase(null);
      final file = File('${tempDir.path}/purchased_item.png')..createSync();
      await purchasedItemsRepository.addPurchasedItem(
        name: 'Watermelon',
        price: 4.0,
        qty: 1.0,
        discount: 0.0,
        isWeight: true,
        purchaseId: purchase.id,
        group: null,
        imagePath: Value(file.path),
      );
      final purchasedItems = await purchasedItemsRepository.watchPurchasedItems(purchase.id).first;
      expect(purchasedItems.length, 1);
      final purchasedItemId = purchasedItems.first.purchasedItem.id;
      expect(file.existsSync(), isTrue);
      await purchasedItemsRepository.deletePurchasedItem(purchasedItemId);
      final afterDelete = await purchasedItemsRepository.watchPurchasedItems(purchase.id).first;
      expect(afterDelete.isEmpty, isTrue);
      expect(file.existsSync(), isFalse);
    });

    test('getAvailableItems filters global items appropriately by group', () async {
      final groupId = await groupsRepository.addGroup('Pets');
      await itemsRepository.insertItem(name: 'Dog Food', groupId: groupId);
      await itemsRepository.insertItem(name: 'Cat Food', groupId: groupId);
      await itemsRepository.insertItem(name: 'Toothbrush');
      final petsItems = await purchasedItemsRepository.getAvailableItems(groupId);
      expect(petsItems.length, 2);
      expect(petsItems.any((i) => i.name == 'Dog Food'), isTrue);
      expect(petsItems.any((i) => i.name == 'Cat Food'), isTrue);
      final generalItems = await purchasedItemsRepository.getAvailableItems(null);
      expect(generalItems.length, 1);
      expect(generalItems.first.name, 'Toothbrush');
    });
  });
}
