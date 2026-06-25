import 'package:drift/drift.dart';

// Where - Shops, Malls, Type of Shopping etc.
class Groups extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
}

// When - the event of buying items under group
class Purchases extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  DateTimeColumn get purchaseDate => dateTime()();
  RealColumn get totalPrice => real().nullable()();
  RealColumn get taxRate => real().nullable()(); // override global tax rate
  // Optional Group
  IntColumn get groupId => integer().nullable().references(
    Groups,
    #id,
    onDelete: KeyAction.cascade,
  )();
}

// What - the items under a group (for autocompletion)
class Items extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get imagePath => text().nullable()(); // Store local image path
  // Optional Group
  IntColumn get groupId => integer().nullable().references(
    Groups,
    #id,
    onDelete: KeyAction.cascade,
  )();
}

class PurchasedItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get price => real()();
  BoolColumn get isWeight => boolean().withDefault(const Constant(false))();
  RealColumn get quantity => real()(); // int => unit, float => weight
  RealColumn get discount => real().withDefault(const Constant(0.0))();
  IntColumn get purchaseId =>
      integer().references(Purchases, #id, onDelete: KeyAction.cascade)();
  IntColumn get itemId =>
      integer().references(Items, #id, onDelete: KeyAction.cascade)();
}
