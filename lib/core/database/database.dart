import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shopping_assist/core/database/models.dart';
import 'package:shopping_assist/core/database/daos/groups_dao.dart';
import 'package:shopping_assist/core/database/daos/purchases_dao.dart';
import 'package:shopping_assist/core/database/daos/items_dao.dart';
import 'package:shopping_assist/core/database/daos/purchased_items_dao.dart';

part 'database.g.dart';

// Drift basically creates classes like these based on tables, daos etc.
// So, this is kept here in database
class PurchasedItemWithDetails {
  final PurchasedItem purchasedItem;
  final Item item;
  PurchasedItemWithDetails(this.purchasedItem, this.item);
}

@DriftDatabase(
  tables: [Groups, Purchases, Items, PurchasedItems],
  daos: [GroupsDao, PurchasesDao, ItemsDao, PurchasedItemsDao],
)
class AppDatabase extends _$AppDatabase {
  // Just a simple constructor, no singleton. Provider manage instance
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from == 1) {
          await m.createTable(groups);
          await m.createTable(purchases);
          await m.createTable(items);
          await m.createTable(purchasedItems);
        }
      },
      beforeOpen: (details) async {
        // SQLite disables foreign keys by default O_o
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  // Database connection
  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'shopping_assist.db',
      native: const DriftNativeOptions(databaseDirectory: getApplicationSupportDirectory),
    );
  }
}
