import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
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
      database.purchasesDao,
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

  group('ItemsRepository Tests', () {
    test('insertItem and findItem should insert and retrieve an item', () async {
      final itemId = await itemsRepository.insertItem(
        name: 'Apple',
        imagePath: 'path/to/apple.png',
      );
      final item = await itemsRepository.findItem(itemId, null);
      expect(item, isNotNull);
      expect(item!.name, 'Apple');
      expect(item.imagePath, 'path/to/apple.png');
      expect(item.groupId, isNull);
    });

    test('watchItemsInGroup and getItemsInGroup filter items by group', () async {
      final groupId1 = await groupsRepository.addGroup('Groceries');
      final groupId2 = await groupsRepository.addGroup('Electronics');
      await itemsRepository.insertItem(name: 'Milk', groupId: groupId1);
      await itemsRepository.insertItem(name: 'Phone', groupId: groupId2);
      final itemsInGroup1 = await itemsRepository.getItemsInGroup(groupId1);
      expect(itemsInGroup1.length, 1);
      expect(itemsInGroup1.first.name, 'Milk');
      final group1Stream = await itemsRepository.watchItemsInGroup(groupId1).first;
      expect(group1Stream.length, 1);
      expect(group1Stream.first.name, 'Milk');
    });

    test(
      'watchItemsWithoutGroup and getItemsWithoutGroup return items with null groupId',
      () async {
        final groupId = await groupsRepository.addGroup('Groceries');
        await itemsRepository.insertItem(name: 'Banana');
        await itemsRepository.insertItem(name: 'Milk', groupId: groupId);
        final itemsWithoutGroup = await itemsRepository.getItemsWithoutGroup();
        expect(itemsWithoutGroup.length, 1);
        expect(itemsWithoutGroup.first.name, 'Banana');
        final streamWithoutGroup = await itemsRepository.watchItemsWithoutGroup().first;
        expect(streamWithoutGroup.length, 1);
        expect(streamWithoutGroup.first.name, 'Banana');
      },
    );

    test('updateItem updates fields and deletes old image file if exists', () async {
      final oldFile = File('${tempDir.path}/old_image.png')..createSync();
      final itemId = await itemsRepository.insertItem(name: 'Old Item', imagePath: oldFile.path);
      expect(oldFile.existsSync(), isTrue);
      await itemsRepository.updateItem(
        itemId,
        name: 'New Item Name',
        imagePath: const Value('new/path/to/image.png'),
      );
      final updatedItem = await itemsRepository.findItem(itemId, null);
      expect(updatedItem?.name, 'New Item Name');
      expect(updatedItem?.imagePath, 'new/path/to/image.png');
      expect(oldFile.existsSync(), isFalse);
    });

    test('updateItemImage updates the image path directly', () async {
      final itemId = await itemsRepository.insertItem(name: 'Orange');
      await itemsRepository.updateItemImage(itemId, 'orange.png');
      final updatedItem = await itemsRepository.findItem(itemId, null);
      expect(updatedItem?.imagePath, 'orange.png');
    });

    test('deleteItem removes item from DB and deletes local file', () async {
      final file = File('${tempDir.path}/item.png')..createSync();
      final itemId = await itemsRepository.insertItem(name: 'Deleted Item', imagePath: file.path);
      expect(file.existsSync(), isTrue);
      await itemsRepository.deleteItem(itemId);
      final item = await itemsRepository.findItem(itemId, null);
      expect(item, isNull);
      expect(file.existsSync(), isFalse);
    });

    test('searchItems returns items matching query under group context', () async {
      final groupId = await groupsRepository.addGroup('Snacks');
      await itemsRepository.insertItem(name: 'Potato Chips', groupId: groupId);
      await itemsRepository.insertItem(name: 'Chocolate Bar', groupId: groupId);
      await itemsRepository.insertItem(name: 'Potato Salad');
      final searchResultsGroup = await itemsRepository.searchItems('potato', groupId: groupId);
      expect(searchResultsGroup.length, 1);
      expect(searchResultsGroup.first.name, 'Potato Chips');
      final searchResultsNoGroup = await itemsRepository.searchItems('potato');
      expect(searchResultsNoGroup.length, 1);
      expect(searchResultsNoGroup.first.name, 'Potato Salad');
    });

    test('getPurchasedItemsForItem returns purchased items referencing this item', () async {
      final purchase = await purchasesRepository.createPurchase(null);
      final itemId = await itemsRepository.insertItem(name: 'Soda');
      await purchasedItemsRepository.addPurchasedItem(
        itemId: itemId,
        name: 'Soda',
        price: 1.5,
        qty: 3,
        discount: 0.0,
        isWeight: false,
        purchaseId: purchase.id,
        group: null,
      );
      final purchased = await itemsRepository.getPurchasedItemsForItem(itemId);
      expect(purchased.length, 1);
      expect(purchased.first.price, 1.5);
    });

    test('getPurchaseHistoryForItem, countPurchasesForItem, and getLastPurchasedDetails', () async {
      final purchase1 = await purchasesRepository.createPurchase(null);
      final itemId = await itemsRepository.insertItem(name: 'Apple');
      await purchasedItemsRepository.addPurchasedItem(
        itemId: itemId,
        name: 'Apple',
        price: 1.0,
        qty: 5.0,
        discount: 0.2,
        isWeight: false,
        purchaseId: purchase1.id,
        group: null,
      );
      final purchase2 = await purchasesRepository.createPurchase(null);
      await purchasedItemsRepository.addPurchasedItem(
        itemId: itemId,
        name: 'Apple',
        price: 1.2,
        qty: 3.0,
        discount: 0.0,
        isWeight: false,
        purchaseId: purchase2.id,
        group: null,
      );
      final history = await itemsRepository.getPurchaseHistoryForItem(itemId);
      expect(history.length, 2);
      final count = await itemsRepository.countPurchasesForItem(itemId);
      expect(count, 2);
      final lastPurchased = await itemsRepository.getLastPurchasedDetails(itemId);
      expect(lastPurchased, isNotNull);
      expect(lastPurchased?.price, 1.2);
      final hasPurchased = await itemsRepository.hasPurchasedItems(itemId);
      expect(hasPurchased, isTrue);
    });

    test('hasPurchasedItems returns false when no purchases exist', () async {
      final itemId = await itemsRepository.insertItem(name: 'Unbought Item');
      final hasPurchased = await itemsRepository.hasPurchasedItems(itemId);
      expect(hasPurchased, isFalse);
    });
  });
}
