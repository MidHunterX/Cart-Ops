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
  RealColumn get budget => real().nullable()();
  BoolColumn get isChecklistMode => boolean().withDefault(const Constant(false))();
  // Optional Group
  IntColumn get groupId =>
      integer().nullable().references(Groups, #id, onDelete: KeyAction.cascade)();
}

// What - the items under a group (for autocompletion)
class Items extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get imagePath => text().nullable()(); // Store local image path
  // Optional Group
  IntColumn get groupId =>
      integer().nullable().references(Groups, #id, onDelete: KeyAction.cascade)();
}

class PurchasedItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().nullable().withLength(min: 1, max: 100)();
  TextColumn get imagePath => text().nullable()();
  RealColumn get price => real().nullable()();
  BoolColumn get isWeight => boolean().withDefault(const Constant(false))();
  RealColumn get quantity => real().nullable()(); // int => unit, float => weight
  RealColumn get discount => real().withDefault(const Constant(0.0))();
  BoolColumn get isChecked => boolean().withDefault(const Constant(false))();
  IntColumn get purchaseId => integer().references(Purchases, #id, onDelete: KeyAction.cascade)();
  IntColumn get itemId =>
      integer().nullable().references(Items, #id, onDelete: KeyAction.cascade)();
}
