import 'package:drift/drift.dart';

// Purchase Groups Table
class PurchaseGroups extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get itemCount =>
      integer().nullable()(); // Denormalized for quick display
}

// Purchases Table (individual purchases within a group)
class Purchases extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get groupId => integer().references(PurchaseGroups, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  DateTimeColumn get purchaseDate => dateTime()();
  RealColumn get totalPrice => real().nullable()();
  RealColumn get taxRate =>
      real().nullable()(); // Can override group's tax rate
}

// Items Table (items within a purchase)
class Items extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get purchaseId => integer().references(Purchases, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  RealColumn get price => real()();
  RealColumn get quantity => real()();
  RealColumn get discount => real().withDefault(const Constant(0.0))();
  TextColumn get imagePath => text().nullable()(); // Store local image path
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}
