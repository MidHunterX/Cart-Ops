import 'package:drift/drift.dart' hide isNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_assist/core/database/database.dart';

import 'generated_migrations/schema.dart';

void main() {
  group('Database Migration V4 Tests', () {
    late SchemaVerifier verifier;

    setUpAll(() {
      verifier = SchemaVerifier(GeneratedHelper());
    });

    test('upgrade from v3 to v4 adds description and iconKey columns to groups', () async {
      final connection = await verifier.startAt(3);
      final db = AppDatabase.forTesting(connection);

      await verifier.migrateAndValidate(db, 4);

      // Verify data insertion works with the newly added V4 columns
      // using Drift's type-safe Companion classes instead of raw SQL.
      await db
          .into(db.groups)
          .insert(
            const GroupsCompanion(
              name: Value('New Year Trip'),
              description: Value('Groceries and supplies for the trip'),
              iconKey: Value('grocery'),
            ),
          );

      final groups = await db.select(db.groups).get();

      expect(groups, hasLength(1));

      final migratedGroup = groups.first;
      expect(migratedGroup.name, 'New Year Trip');

      // Ensure the new V4 columns hold the correct values and don't throw errors
      expect(
        migratedGroup.description,
        'Groceries and supplies for the trip',
        reason: 'description column should be accessible and store data correctly in V4',
      );
      expect(
        migratedGroup.iconKey,
        'grocery',
        reason: 'iconKey column should be accessible and store data correctly in V4',
      );

      // Cleanup
      await db.close();
    });

    test(
      'existing v3 data receives default values for new columns after migration to v4',
      () async {
        final connection = await verifier.startAt(3);
        final db = AppDatabase.forTesting(connection);

        // Insert sample groups using raw SQL (v3 schema has only id and name)
        await db.customStatement('INSERT INTO groups (name) VALUES (?)', ['Existing Group 1']);
        await db.customStatement('INSERT INTO groups (name) VALUES (?)', ['Existing Group 2']);

        // Migrate from v3 to v4 – this adds description and iconKey with default NULL
        await verifier.migrateAndValidate(db, 4);

        // Query all groups using Drift's type-safe API (now v4 columns exist)
        final groups = await db.select(db.groups).get();

        // Assertions
        expect(groups, hasLength(2));
        for (final group in groups) {
          // New columns should be null for old records
          expect(group.description, isNull);
          expect(group.iconKey, isNull);
        }
        // Verify names are preserved
        expect(groups.map((g) => g.name), containsAll(['Existing Group 1', 'Existing Group 2']));

        await db.close();
      },
    );
  });
}
