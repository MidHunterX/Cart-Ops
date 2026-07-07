import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:shopping_assist/features/groups/repositories/groups_repository.dart';

void main() {
  late AppDatabase database;
  late GroupsRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true, // prevents drift leaks in tests
      ),
    );
    repository = GroupsRepository(database.groupsDao);
  });

  tearDown(() async {
    await database.close();
  });

  group('watchGroups', () {
    test('emits empty list when no groups exist', () async {
      final groups = await repository.watchGroups().first;
      expect(groups, isEmpty);
    });

    test('emits updated list after adding a group', () async {
      await repository.addGroup('Groceries');

      final groups = await repository.watchGroups().first;
      expect(groups.length, 1);
      expect(groups.first.name, 'Groceries');
    });

    test('emits updated list after deleting a group', () async {
      final id = await repository.addGroup('Groceries');
      await repository.deleteGroup(id);

      final groups = await repository.watchGroups().first;
      expect(groups, isEmpty);
    });

    test('emits multiple groups in correct order', () async {
      await repository.addGroup('Groceries');
      await repository.addGroup('Electronics');
      await repository.addGroup('Clothing');

      final groups = await repository.watchGroups().first;
      expect(groups.length, 3);
      expect(groups.map((g) => g.name).toList(), ['Groceries', 'Electronics', 'Clothing']);
    });

    test('emits distinct snapshots for each change', () async {
      final emittedGroups = <List<Group>>[];
      final subscription = repository.watchGroups().listen(emittedGroups.add);

      // Wait for initial emission
      await Future.delayed(Duration.zero);

      // Initial state should be empty
      expect(emittedGroups.length, 1);
      expect(emittedGroups[0], isEmpty);

      // Add first group and wait for it to complete
      final id = await repository.addGroup('First');
      await Future.delayed(Duration.zero);

      // Now we should have [First]
      expect(emittedGroups.length, 2);
      expect(emittedGroups[1].length, 1);
      expect(emittedGroups[1].first.name, 'First');

      // Add second group
      await repository.addGroup('Second');
      await Future.delayed(Duration.zero);

      // Now we should have [First, Second]
      expect(emittedGroups.length, 3);
      expect(emittedGroups[2].length, 2);
      expect(emittedGroups[2].map((g) => g.name), containsAll(['First', 'Second']));

      // Delete first group
      await repository.deleteGroup(id);
      await Future.delayed(Duration.zero);

      // Final state should have only [Second]
      expect(emittedGroups.length, 4);
      expect(emittedGroups[3].length, 1);
      expect(emittedGroups[3].first.name, 'Second');

      await subscription.cancel();
    });
  });

  group('addGroup', () {
    test('correctly stores a new group record', () async {
      final id = await repository.addGroup('Groceries');
      expect(id, isPositive);

      final groups = await repository.watchGroups().first;
      expect(groups.length, 1);
      expect(groups.first.name, 'Groceries');
    });

    test('returns incrementing ids for multiple groups', () async {
      final id1 = await repository.addGroup('Group A');
      final id2 = await repository.addGroup('Group B');
      final id3 = await repository.addGroup('Group C');

      expect(id2, id1 + 1);
      expect(id3, id2 + 1);
    });

    test('stores group with name at minimum length boundary', () async {
      final id = await repository.addGroup('A');
      expect(id, isPositive);

      final groups = await repository.watchGroups().first;
      expect(groups.first.name, 'A');
    });

    test('stores group with name at maximum length boundary', () async {
      final longName = 'A' * 50;
      final id = await repository.addGroup(longName);
      expect(id, isPositive);

      final groups = await repository.watchGroups().first;
      expect(groups.first.name, longName);
    });

    test('allows duplicate group names', () async {
      await repository.addGroup('Groceries');
      final id2 = await repository.addGroup('Groceries');

      final groups = await repository.watchGroups().first;
      expect(groups.length, 2);
      expect(groups.where((g) => g.name == 'Groceries').length, 2);
      expect(id2, isPositive);
    });

    test('allows special characters in group name', () async {
      final specialName = 'Groceries & More - 50% Off! (Test)';
      final id = await repository.addGroup(specialName);
      expect(id, isPositive);

      final groups = await repository.watchGroups().first;
      expect(groups.first.name, specialName);
    });

    test('allows unicode characters in group name', () async {
      final unicodeName = '超市 🛒 生活用品';
      final id = await repository.addGroup(unicodeName);
      expect(id, isPositive);

      final groups = await repository.watchGroups().first;
      expect(groups.first.name, unicodeName);
    });

    test('allows whitespace-only name (if schema permits)', () async {
      // Note: This tests behavior if schema allows it; drift withLength(min: 1)
      // will accept a single space since it has length 1
      final id = await repository.addGroup(' ');
      expect(id, isPositive);

      final groups = await repository.watchGroups().first;
      expect(groups.first.name, ' ');
    });

    test('allows empty string name (if schema permits)', () async {
      // Note: withLength(min: 1) should reject this, but we verify behavior
      // This may throw or fail depending on drift validation
      expect(() => repository.addGroup(''), throwsA(anything));
    });
  });

  group('deleteGroup', () {
    test('removes an existing group', () async {
      final id = await repository.addGroup('To Delete');
      await repository.deleteGroup(id);

      final groups = await repository.watchGroups().first;
      expect(groups, isEmpty);
    });

    test('returns normally when deleting non-existent id', () async {
      // Should not throw
      await repository.deleteGroup(999);

      final groups = await repository.watchGroups().first;
      expect(groups, isEmpty);
    });

    test('only deletes the specified group', () async {
      final id1 = await repository.addGroup('Keep');
      final id2 = await repository.addGroup('Delete');
      await repository.deleteGroup(id2);

      final groups = await repository.watchGroups().first;
      expect(groups.length, 1);
      expect(groups.first.id, id1);
      expect(groups.first.name, 'Keep');
    });

    test('deleting same id twice is idempotent', () async {
      final id = await repository.addGroup('Once');
      await repository.deleteGroup(id);
      // Second delete should not throw
      await repository.deleteGroup(id);

      final groups = await repository.watchGroups().first;
      expect(groups, isEmpty);
    });

    test('cascades delete to associated purchases', () async {
      final groupId = await repository.addGroup('Groceries');

      // Insert a purchase associated with the group
      await database
          .into(database.purchases)
          .insert(
            PurchasesCompanion.insert(
              name: 'Weekly Shop',
              purchaseDate: DateTime.now(),
              groupId: Value(groupId),
            ),
          );

      // Verify purchase exists
      final purchasesBefore = await database.select(database.purchases).get();
      expect(purchasesBefore.length, 1);

      // Delete the group
      await repository.deleteGroup(groupId);

      // Verify group is gone
      final groups = await repository.watchGroups().first;
      expect(groups, isEmpty);

      // Verify cascade deleted the purchase
      final purchasesAfter = await database.select(database.purchases).get();
      expect(purchasesAfter, isEmpty);
    });

    test('cascades delete to associated items', () async {
      final groupId = await repository.addGroup('Groceries');

      // Insert an item associated with the group
      await database
          .into(database.items)
          .insert(ItemsCompanion.insert(name: 'Apple', groupId: Value(groupId)));

      // Verify item exists
      final itemsBefore = await database.select(database.items).get();
      expect(itemsBefore.length, 1);

      // Delete the group
      await repository.deleteGroup(groupId);

      // Verify cascade deleted the item
      final itemsAfter = await database.select(database.items).get();
      expect(itemsAfter, isEmpty);
    });
  });

  group('integration scenarios', () {
    test('full lifecycle: add, verify, delete, verify', () async {
      // Add
      final id = await repository.addGroup('Lifecycle Test');
      expect(id, isPositive);

      // Verify
      var groups = await repository.watchGroups().first;
      expect(groups.length, 1);
      expect(groups.first.name, 'Lifecycle Test');

      // Delete
      await repository.deleteGroup(id);

      // Verify
      groups = await repository.watchGroups().first;
      expect(groups, isEmpty);
    });

    test('multiple add and delete operations in sequence', () async {
      final id1 = await repository.addGroup('A');
      final id2 = await repository.addGroup('B');
      final id3 = await repository.addGroup('C');

      var groups = await repository.watchGroups().first;
      expect(groups.length, 3);

      await repository.deleteGroup(id2);
      groups = await repository.watchGroups().first;
      expect(groups.length, 2);
      expect(groups.map((g) => g.name).toList(), ['A', 'C']);

      await repository.deleteGroup(id1);
      groups = await repository.watchGroups().first;
      expect(groups.length, 1);
      expect(groups.first.name, 'C');

      await repository.deleteGroup(id3);
      groups = await repository.watchGroups().first;
      expect(groups, isEmpty);
    });

    test('group with associated data can be fully cleaned up', () async {
      final groupId = await repository.addGroup('Full Cleanup');

      // Create item
      await database
          .into(database.items)
          .insert(ItemsCompanion.insert(name: 'Item', groupId: Value(groupId)));

      // Create purchase
      final purchaseId = await database
          .into(database.purchases)
          .insert(
            PurchasesCompanion.insert(
              name: 'Purchase',
              purchaseDate: DateTime.now(),
              groupId: Value(groupId),
            ),
          );

      // Create purchased item
      await database
          .into(database.purchasedItems)
          .insert(
            PurchasedItemsCompanion.insert(name: Value('Purchased Item'), purchaseId: purchaseId),
          );

      // Verify all exist
      expect((await database.select(database.groups).get()).length, 1);
      expect((await database.select(database.items).get()).length, 1);
      expect((await database.select(database.purchases).get()).length, 1);
      expect((await database.select(database.purchasedItems).get()).length, 1);

      // Delete group - should cascade to items and purchases (which cascade to purchasedItems)
      await repository.deleteGroup(groupId);

      // Verify all cleaned up
      expect((await database.select(database.groups).get()), isEmpty);
      expect((await database.select(database.items).get()), isEmpty);
      expect((await database.select(database.purchases).get()), isEmpty);
      expect((await database.select(database.purchasedItems).get()), isEmpty);
    });

    test('watchGroups stream remains active across multiple operations', () async {
      final events = <List<Group>>[];
      final subscription = repository.watchGroups().listen(events.add);

      final id1 = await repository.addGroup('First');
      await Future.delayed(Duration(milliseconds: 10));

      await repository.addGroup('Second');
      await Future.delayed(Duration(milliseconds: 10));

      await repository.deleteGroup(id1);
      await Future.delayed(Duration(milliseconds: 10));

      await subscription.cancel();

      expect(events.length, greaterThanOrEqualTo(3));
      expect(events.any((e) => e.length == 1 && e.first.name == 'First'), isTrue);
      expect(events.any((e) => e.length == 2), isTrue);
      expect(events.last.length, 1);
      expect(events.last.first.name, 'Second');
    });
  });
}
