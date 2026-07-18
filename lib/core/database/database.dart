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
  final Item? _item;

  PurchasedItemWithDetails(this.purchasedItem, this._item);

  // Custom getter to prevent crashes on screens that try accessing linked Item details.
  Item get item =>
      _item ??
      Item(
        id: purchasedItem.itemId ?? -1,
        name: purchasedItem.name ?? '',
        imagePath: purchasedItem.imagePath,
      );
}

class PurchasedItemWithPurchase {
  final PurchasedItem purchasedItem;
  final Purchase purchase;
  PurchasedItemWithPurchase(this.purchasedItem, this.purchase);
}

@DriftDatabase(
  tables: [Groups, Purchases, Items, PurchasedItems],
  daos: [GroupsDao, PurchasesDao, ItemsDao, PurchasedItemsDao],
)
class AppDatabase extends _$AppDatabase {
  // Production constructor
  AppDatabase() : super(_openConnection());

  // Named constructor to inject memory instances
  AppDatabase.forTesting(DatabaseConnection super.connection);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.addColumn(purchases, purchases.isChecklistMode);
          await m.addColumn(purchasedItems, purchasedItems.isChecked);
        }
        if (from < 3) {
          // Convert existing fixed discount values to percentages
          await customStatement('''
            UPDATE purchased_items
            SET discount = CASE
              WHEN price IS NOT NULL AND price > 0 THEN (discount / price) * 100
              ELSE 0
            END
            WHERE discount > 0;
          ''');
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
