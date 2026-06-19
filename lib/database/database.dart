import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shopping_assist/database/models.dart';
import 'package:shopping_assist/database/daos/groups_dao.dart';
import 'package:shopping_assist/database/daos/purchases_dao.dart';
import 'package:shopping_assist/database/daos/items_dao.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [Groups, Purchases, Items, PurchasedItems],
  daos: [GroupsDao, PurchasesDao, ItemsDao],
)
class AppDatabase extends _$AppDatabase {
  // Just a simple constructor, no singleton. Provider manage instance
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

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
    /*getApplicationSupportDirectory().then((dir) {
      print("DATABASE DIR: ${dir.path}");
    });*/
    return driftDatabase(
      name: 'shopping_assist.db',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}
