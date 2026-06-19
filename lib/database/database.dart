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
  int get schemaVersion => 1;

  // Database connection
  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'shopping_assist.db',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}
