import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shopping_assist/database/models.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Groups, Purchases, Items, PurchasedItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase._([QueryExecutor? executor])
    : super(executor ?? _openConnection());

  static final AppDatabase _instance = AppDatabase._(); // Singleton instance

  factory AppDatabase() {
    return _instance;
  }

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

  // Group Operations
  Stream<List<Group>> watchGroups() => select(groups).watch();
  Future<int> insertGroup(GroupsCompanion group) => into(groups).insert(group);
  Future deleteGroup(int id) =>
      (delete(groups)..where((t) => t.id.equals(id))).go();

  // Item Operations
  Stream<List<Item>> watchItemsInGroup(int groupId) {
    return (select(items)..where((t) => t.groupId.equals(groupId))).watch();
  }

  Future<int> insertItem(ItemsCompanion item) => into(items).insert(item);
}
