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

  // EDGE CASE SCENARIOS

  test('addPurchasedItem handles empty/whitespace name gracefully', () async {
    final purchase = await purchasesRepository.createPurchase(null);
    await purchasedItemsRepository.addPurchasedItem(
      name: '   ',
      price: 3.5,
      qty: 2.0,
      discount: 0.0,
      isWeight: false,
      purchaseId: purchase.id,
      group: null,
    );
    final purchasedItems = await purchasedItemsRepository.watchPurchasedItems(purchase.id).first;
    expect(purchasedItems.length, 1);
    expect(purchasedItems.first.purchasedItem.name, isNull);
    expect(purchasedItems.first.purchasedItem.itemId, isNull);
  });

  test('addPurchasedItem does not create item when price is null', () async {
    final purchase = await purchasesRepository.createPurchase(null);
    await purchasedItemsRepository.addPurchasedItem(
      name: 'Test Item',
      price: null,
      qty: 2.0,
      discount: 0.0,
      isWeight: false,
      purchaseId: purchase.id,
      group: null,
    );
    final purchasedItems = await purchasedItemsRepository.watchPurchasedItems(purchase.id).first;
    expect(purchasedItems.length, 1);
    expect(purchasedItems.first.purchasedItem.itemId, isNull);
    // Verify no item was created globally
    final allItems = await itemsRepository.getItemsWithoutGroup();
    expect(allItems.isEmpty, isTrue);
  });

  test('addPurchasedItem does not create item when quantity is null', () async {
    final purchase = await purchasesRepository.createPurchase(null);
    await purchasedItemsRepository.addPurchasedItem(
      name: 'Test Item',
      price: 3.5,
      qty: null,
      discount: 0.0,
      isWeight: false,
      purchaseId: purchase.id,
      group: null,
    );
    final purchasedItems = await purchasedItemsRepository.watchPurchasedItems(purchase.id).first;
    expect(purchasedItems.length, 1);
    expect(purchasedItems.first.purchasedItem.itemId, isNull);
  });

  test('addPurchasedItem handles null discount', () async {
    final purchase = await purchasesRepository.createPurchase(null);
    await purchasedItemsRepository.addPurchasedItem(
      name: 'Test Item',
      price: 10.0,
      qty: 1.0,
      discount: null,
      isWeight: false,
      purchaseId: purchase.id,
      group: null,
    );
    final purchasedItems = await purchasedItemsRepository.watchPurchasedItems(purchase.id).first;
    expect(purchasedItems.length, 1);
    expect(purchasedItems.first.purchasedItem.discount, 0.0);
  });

  test('addPurchasedItem with null imagePath default behavior', () async {
    final purchase = await purchasesRepository.createPurchase(null);
    await purchasedItemsRepository.addPurchasedItem(
      name: 'Test Item',
      price: 3.5,
      qty: 2.0,
      discount: 0.0,
      isWeight: false,
      purchaseId: purchase.id,
      group: null,
      // imagePath intentionally not provided
    );
    final purchasedItems = await purchasedItemsRepository.watchPurchasedItems(purchase.id).first;
    expect(purchasedItems.length, 1);
    expect(purchasedItems.first.purchasedItem.imagePath, isNull);
  });

  // UPDATE SCENARIOS

  test('updatePurchasedItem updates only specified fields', () async {
    final purchase = await purchasesRepository.createPurchase(null);
    await purchasedItemsRepository.addPurchasedItem(
      name: 'Original Name',
      price: 10.0,
      qty: 5.0,
      discount: 0.0,
      isWeight: false,
      purchaseId: purchase.id,
      group: null,
    );
    final items = await purchasedItemsRepository.watchPurchasedItems(purchase.id).first;
    final itemToUpdate = items.first;
    // Update only price and quantity
    await purchasedItemsRepository.updatePurchasedItem(
      id: itemToUpdate.purchasedItem.id,
      itemId: itemToUpdate.purchasedItem.itemId,
      name: null,
      price: 15.0,
      qty: 10.0,
      discount: 0.0,
      isWeight: false,
      groupId: null,
    );
    final updatedItems = await purchasedItemsRepository.watchPurchasedItems(purchase.id).first;
    final updated = updatedItems.first.purchasedItem;
    expect(updated.name, 'Original Name'); // Name unchanged
    expect(updated.price, 15.0);
    expect(updated.quantity, 10.0);
  });

  test('updatePurchasedItem handles itemId=-1 without name change', () async {
    final purchase = await purchasesRepository.createPurchase(null);
    await purchasedItemsRepository.addPurchasedItem(
      name: 'Test Item',
      price: 10.0,
      qty: 5.0,
      discount: 0.0,
      isWeight: false,
      purchaseId: purchase.id,
      group: null,
    );
    final items = await purchasedItemsRepository.watchPurchasedItems(purchase.id).first;
    final itemToUpdate = items.first;
    final originalItemId = itemToUpdate.purchasedItem.itemId;
    await purchasedItemsRepository.updatePurchasedItem(
      id: itemToUpdate.purchasedItem.id,
      itemId: -1, // Invalid itemId
      name: null, // Don't change name
      price: 20.0,
      qty: 3.0,
      discount: 0.0,
      isWeight: false,
      groupId: null,
    );
    final updatedItems = await purchasedItemsRepository.watchPurchasedItems(purchase.id).first;
    final updated = updatedItems.first.purchasedItem;
    expect(updated.itemId, originalItemId); // Item ID unchanged
    expect(updated.price, 20.0);
    expect(updated.quantity, 3.0);
  });

  test('updatePurchasedItem creates new item when name changes with invalid itemId', () async {
    final purchase = await purchasesRepository.createPurchase(null);
    await purchasedItemsRepository.addPurchasedItem(
      name: 'Old Name',
      price: 10.0,
      qty: 5.0,
      discount: 0.0,
      isWeight: false,
      purchaseId: purchase.id,
      group: null,
    );
    final items = await purchasedItemsRepository.watchPurchasedItems(purchase.id).first;
    final itemToUpdate = items.first;
    final originalItemId = itemToUpdate.purchasedItem.itemId;
    await purchasedItemsRepository.updatePurchasedItem(
      id: itemToUpdate.purchasedItem.id,
      itemId: -1,
      name: 'New Name',
      price: 10.0,
      qty: 5.0,
      discount: 0.0,
      isWeight: false,
      groupId: null,
    );
    final updatedItems = await purchasedItemsRepository.watchPurchasedItems(purchase.id).first;
    final updated = updatedItems.first.purchasedItem;
    expect(updated.name, 'New Name');
    expect(updated.itemId, isNot(originalItemId));
    // Verify new item was created globally
    final globalItem = await itemsRepository.findItem(updated.itemId!, null);
    expect(globalItem?.name, 'New Name');
  });

  test('updatePurchasedItem does NOT create item when name changes but price is null', () async {
    final purchase = await purchasesRepository.createPurchase(null);
    await purchasedItemsRepository.addPurchasedItem(
      name: 'Old Name',
      price: 10.0,
      qty: 5.0,
      discount: 0.0,
      isWeight: false,
      purchaseId: purchase.id,
      group: null,
    );
    final items = await purchasedItemsRepository.watchPurchasedItems(purchase.id).first;
    final itemToUpdate = items.first;
    final originalItemId = itemToUpdate.purchasedItem.itemId;
    await purchasedItemsRepository.updatePurchasedItem(
      id: itemToUpdate.purchasedItem.id,
      itemId: -1,
      name: 'New Name',
      price: null, // No price provided
      qty: 5.0,
      discount: 0.0,
      isWeight: false,
      groupId: null,
    );
    final updatedItems = await purchasedItemsRepository.watchPurchasedItems(purchase.id).first;
    final updated = updatedItems.first.purchasedItem;
    expect(updated.name, 'New Name');
    expect(updated.itemId, originalItemId); // No new item created
  });

  group('PurchasedItemsRepository - Total Price Calculations', () {
    test(
      'totalPrice updates correctly using price * qty * (1 - discount/100) on addition',
      () async {
        final purchase = await purchasesRepository.createPurchase(null);
        // Item 1: 10.0 * 3.0 * (1 - 20/100) = 10.0 * 3.0 * 0.8 = 24.0
        await purchasedItemsRepository.addPurchasedItem(
          name: 'Item 1',
          price: 10.0,
          qty: 3.0,
          discount: 20.0, // 20% discount
          isWeight: false,
          purchaseId: purchase.id,
          group: null,
        );
        var updatedPurchase = await purchasesRepository.watchPurchaseById(purchase.id).first;
        expect(updatedPurchase.totalPrice, 24.0);
        // Item 2: 5.0 * 1.0 * (1 - 0/100) = 5.0
        // Total should be 24.0 + 5.0 = 29.0
        await purchasedItemsRepository.addPurchasedItem(
          name: 'Item 2',
          price: 5.0,
          qty: 1.0,
          discount: 0.0, // 0% discount
          isWeight: false,
          purchaseId: purchase.id,
          group: null,
        );
        updatedPurchase = await purchasesRepository.watchPurchaseById(purchase.id).first;
        expect(updatedPurchase.totalPrice, 29.0);
      },
    );

    test('totalPrice updates correctly when an item is updated', () async {
      final purchase = await purchasesRepository.createPurchase(null);
      await purchasedItemsRepository.addPurchasedItem(
        name: 'Item 1',
        price: 10.0,
        qty: 2.0,
        discount: 0.0,
        isWeight: false,
        purchaseId: purchase.id,
        group: null,
      ); // Total: 20.0
      final items = await purchasedItemsRepository.watchPurchasedItems(purchase.id).first;
      final itemToUpdate = items.first.purchasedItem;
      // Update to: 15.0 * 3.0 * (1 - 33.33/100) ≈ 30.0
      await purchasedItemsRepository.updatePurchasedItem(
        id: itemToUpdate.id,
        price: 15.0,
        qty: 3.0,
        // NOTE: Just 33.33 causes totalPrice to be 30.0015 due to floating point math
        discount: 100.0 / 3.0, // 33.333333...% discount
        isWeight: false,
      );
      final updatedPurchase = await purchasesRepository.watchPurchaseById(purchase.id).first;
      expect(updatedPurchase.totalPrice, 30.0);
    });

    test('totalPrice updates correctly when an item is deleted', () async {
      final purchase = await purchasesRepository.createPurchase(null);
      await purchasedItemsRepository.addPurchasedItem(
        name: 'Keep',
        price: 10.0,
        qty: 1.0,
        discount: 0.0,
        isWeight: false,
        purchaseId: purchase.id,
        group: null,
      ); // 10.0
      await purchasedItemsRepository.addPurchasedItem(
        name: 'Delete Me',
        price: 20.0,
        qty: 2.0,
        discount: 25.0, // 25% discount: 20 * 2 * 0.75 = 30.0
        isWeight: false,
        purchaseId: purchase.id,
        group: null,
      ); // Total = 40.0
      final items = await purchasedItemsRepository.watchPurchasedItems(purchase.id).first;
      final itemToDelete = items
          .firstWhere((i) => i.purchasedItem.name == 'Delete Me')
          .purchasedItem;
      await purchasedItemsRepository.deletePurchasedItem(itemToDelete.id);
      final updatedPurchase = await purchasesRepository.watchPurchaseById(purchase.id).first;
      expect(updatedPurchase.totalPrice, 10.0);
    });

    test('recalculatePurchaseTotal handles null price/qty as 0.0', () async {
      final purchase = await purchasesRepository.createPurchase(null);
      await purchasedItemsRepository.addPurchasedItem(
        name: 'Null Item',
        price: null,
        qty: null,
        discount: 20.0, // 20% discount
        isWeight: false,
        purchaseId: purchase.id,
        group: null,
      );
      final updatedPurchase = await purchasesRepository.watchPurchaseById(purchase.id).first;
      // Calculation: 0.0 * 0.0 * (1 - 20/100) = 0.0
      expect(updatedPurchase.totalPrice, 0.0);
    });

    test('updatePurchasedItem creates Item under the correct Group from Purchase', () async {
      // Setup: Create a Group and a Purchase associated with it
      final groupId = await groupsRepository.addGroup('Pharmacy');
      final purchase = await purchasesRepository.createPurchase(groupId);

      final initialId = await purchasedItemsRepository.addPurchasedItem(
        name: 'Aspirin',
        price: null,
        qty: null,
        discount: null,
        purchaseId: purchase.id,
        group: null,
        isWeight: false,
      );

      // Action: Update the item with full details (name, price, qty)
      // This should trigger the creation of the master Item record.
      await purchasedItemsRepository.updatePurchasedItem(
        id: initialId,
        name: 'Aspirin Gold',
        price: 5.99,
        qty: 1.0,
        discount: 0.0,
        isWeight: false,
      );

      // Verification: Check the PurchasedItem
      final purchasedItems = await purchasedItemsRepository.watchPurchasedItems(purchase.id).first;
      final updatedPI = purchasedItems.firstWhere((it) => it.purchasedItem.id == initialId);

      expect(
        updatedPI.purchasedItem.itemId,
        isNotNull,
        reason: 'A master Item should have been created',
      );

      // Verification: Check the newly created Item in group
      final masterItem = await itemsRepository.findItem(updatedPI.purchasedItem.itemId!, groupId);

      expect(masterItem, isNotNull);
      expect(masterItem!.name, 'Aspirin Gold');
      expect(
        masterItem.groupId,
        equals(groupId),
        reason: 'The new Item must be associated with the Pharmacy group',
      );
    });

    test('updatePurchasedItem creates orphan Item when Purchase has no group', () async {
      // Setup: Create a Purchase NOT associated with any group
      final purchase = await purchasesRepository.createPurchase(null);

      final initialId = await database.purchasedItemsDao.insertPurchasedItem(
        PurchasedItemsCompanion.insert(
          name: const Value('Generic Soda'),
          purchaseId: purchase.id,
          isWeight: const Value(false),
        ),
      );

      // Action: Update to trigger Item creation
      await purchasedItemsRepository.updatePurchasedItem(
        id: initialId,
        name: 'Generic Soda',
        price: 1.50,
        qty: 1.0,
        discount: 0.0,
        isWeight: false,
      );

      // Verification
      final purchasedItems = await purchasedItemsRepository.watchPurchasedItems(purchase.id).first;
      final itemId = purchasedItems.first.purchasedItem.itemId;

      final masterItem = await itemsRepository.findItem(itemId!, null);
      expect(
        masterItem!.groupId,
        isNull,
        reason: 'The Item should be an orphan because the Purchase was not grouped',
      );
    });

    test('updatePurchasedItem recalculates purchase total after update', () async {
      final purchase = await purchasesRepository.createPurchase(null);

      final initialId = await database.purchasedItemsDao.insertPurchasedItem(
        PurchasedItemsCompanion.insert(
          name: const Value('Cheap Item'),
          price: const Value(10.0),
          quantity: const Value(1.0),
          purchaseId: purchase.id,
          isWeight: const Value(false),
        ),
      );

      await database.purchasesDao.recalculatePurchaseTotal(purchase.id);

      await purchasedItemsRepository.updatePurchasedItem(
        id: initialId,
        price: 20.0,
        qty: 2.0,
        discount: 25.0, // 20 * 2 * (1 - 25/100) = 30
        isWeight: false,
      );

      final updatedPurchase = await purchasesRepository.watchPurchaseById(purchase.id).first;
      expect(updatedPurchase.totalPrice, 30.0);
    });
  });
}
