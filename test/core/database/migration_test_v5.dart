import 'package:drift/drift.dart' hide isNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_assist/core/database/database.dart';

import 'generated_migrations/schema.dart';

void main() {
  group('Database Migration V5 Tests', () {
    late SchemaVerifier verifier;

    setUpAll(() {
      verifier = SchemaVerifier(GeneratedHelper());
    });

    test('upgrade from v4 to v5 adds packQuantity column to purchased_items', () async {
      final connection = await verifier.startAt(4);
      final db = AppDatabase.forTesting(connection);

      await verifier.migrateAndValidate(db, 5);

      final purchaseId = await db
          .into(db.purchases)
          .insert(
            PurchasesCompanion(
              name: const Value('Weekly Groceries'),
              purchaseDate: Value(DateTime.now()),
            ),
          );

      // Verify data insertion works with the newly added V5 column
      await db
          .into(db.purchasedItems)
          .insert(
            PurchasedItemsCompanion(
              name: const Value('Apples'),
              price: const Value(3.50),
              quantity: const Value(1.5),
              packQuantity: const Value(4.0),
              isWeight: const Value(true),
              purchaseId: Value(purchaseId),
            ),
          );

      final items = await db.select(db.purchasedItems).get();

      expect(items, hasLength(1));

      final migratedItem = items.first;
      expect(migratedItem.name, 'Apples');

      // Ensure the new V5 column holds the correct value and doesn't throw errors
      expect(
        migratedItem.packQuantity,
        4.0,
        reason: 'packQuantity column should be accessible and store data correctly in V5',
      );

      // Cleanup
      await db.close();
    });

    test('existing v4 data receives default values for new columns after migration to v5', () async {
      final connection = await verifier.startAt(4);
      final db = AppDatabase.forTesting(connection);

      // Insert sample purchase and purchased items using raw SQL (v4 schema)
      await db.customStatement(
        "INSERT INTO purchases (id, name, purchase_date, is_checklist_mode) VALUES (1, 'Old Purchase', '2026-01-01T00:00:00.000', 0)",
      );
      await db.customStatement(
        "INSERT INTO purchased_items (name, price, is_weight, quantity, purchase_id) VALUES ('Bananas', 2.0, 0, 6.0, 1)",
      );

      // Migrate from v4 to v5 – this adds packQuantity with default NULL
      await verifier.migrateAndValidate(db, 5);

      // Query all purchased items using Drift's type-safe API (now v5 column exists)
      final items = await db.select(db.purchasedItems).get();

      // Assertions
      expect(items, hasLength(1));
      final item = items.first;

      // New column should be null for old records
      expect(
        item.packQuantity,
        isNull,
        reason: 'packQuantity should be null for existing V4 records',
      );

      // Verify existing values are preserved
      expect(item.name, 'Bananas');
      expect(item.price, 2.0);
      expect(item.quantity, 6.0);

      await db.close();
    });
  });
}
