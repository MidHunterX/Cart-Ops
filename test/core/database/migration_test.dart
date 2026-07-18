import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_assist/core/database/database.dart';

void main() {
  group('Database Migration Tests', () {
    test('upgrade from v1 to v3 adds columns and converts discount percentages', () async {
      // NOTE: Drift officially recommends using the SchemaVerifier package.
      // However, this requires maintaining a historical output folder of your
      // schema dumps using drift_dev for every version. Since there is no
      // drift_schemas folder in project tree, generating it now would only
      // dump version 3, making it impossible for SchemaVerifier to test
      // upgrades from v1 without manually rewinding Git history to reconstruct
      // the old schemas.

      // Create an in-memory database and seed it with V1 schema and data
      // BEFORE Drift takes over the connection.
      final connection = DatabaseConnection(
        NativeDatabase.memory(
          setup: (rawDb) {
            // Setup V1 schema manually
            rawDb.execute('''
              CREATE TABLE groups (
                id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL
              );
              CREATE TABLE purchases (
                id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                purchase_date INTEGER NOT NULL,
                total_price REAL,
                tax_rate REAL,
                budget REAL,
                group_id INTEGER REFERENCES groups (id) ON DELETE CASCADE
              );
              CREATE TABLE items (
                id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                image_path TEXT,
                group_id INTEGER REFERENCES groups (id) ON DELETE CASCADE
              );
              CREATE TABLE purchased_items (
                id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
                name TEXT,
                image_path TEXT,
                price REAL,
                is_weight INTEGER NOT NULL DEFAULT 0,
                quantity REAL,
                discount REAL NOT NULL DEFAULT 0.0,
                purchase_id INTEGER NOT NULL REFERENCES purchases (id) ON DELETE CASCADE,
                item_id INTEGER REFERENCES items (id) ON DELETE CASCADE
              );
            ''');

            // Insert V1 mock data
            rawDb.execute('INSERT INTO groups (id, name) VALUES (?, ?)', [1, 'Groceries']);

            final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
            rawDb.execute(
              'INSERT INTO purchases'
              '(id, name, purchase_date, group_id)'
              'VALUES (?, ?, ?, ?)',
              [1, 'Test Purchase', nowSeconds, 1],
            );

            // Item with price 50.0, fixed discount of 10.0. (Should convert to 20% in V3).
            rawDb.execute(
              'INSERT INTO purchased_items (id, price, quantity, discount, is_weight, purchase_id) '
              'VALUES (1, 50.0, 1.0, 10.0, 0, 1);',
            );

            // Set current version to 1 so Drift triggers onUpgrade(from: 1, to: 3)
            rawDb.execute('PRAGMA user_version = 1;');
          },
        ),
        closeStreamsSynchronously: true, // Standard for tests
      );

      final db = AppDatabase.forTesting(connection);

      // Trigger migration
      // Drift opens the database and runs the `migration` logic upon the first query.
      final purchases = await db.select(db.purchases).get();
      final items = await db.select(db.purchasedItems).get();

      // V2 Migration checks: new columns should exist with default values
      expect(
        purchases.first.isChecklistMode,
        false,
        reason: 'isChecklistMode should default to false from v2 migration',
      );
      expect(
        items.first.isChecked,
        false,
        reason: 'isChecked should default to false from v2 migration',
      );

      // V3 Migration checks: discount should be converted to percentage
      // Formula in customStatement: (10.0 / 50.0) * 100 = 20.0
      expect(
        items.first.discount,
        20.0,
        reason: 'Fixed discount should be converted to percentage in v3 migration',
      );

      // Cleanup
      await db.close();
    });
  });
}
