// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchased_items_dao.dart';

// ignore_for_file: type=lint
mixin _$PurchasedItemsDaoMixin on DatabaseAccessor<AppDatabase> {
  $GroupsTable get groups => attachedDatabase.groups;
  $PurchasesTable get purchases => attachedDatabase.purchases;
  $ItemsTable get items => attachedDatabase.items;
  $PurchasedItemsTable get purchasedItems => attachedDatabase.purchasedItems;
  PurchasedItemsDaoManager get managers => PurchasedItemsDaoManager(this);
}

class PurchasedItemsDaoManager {
  final _$PurchasedItemsDaoMixin _db;
  PurchasedItemsDaoManager(this._db);
  $$GroupsTableTableManager get groups =>
      $$GroupsTableTableManager(_db.attachedDatabase, _db.groups);
  $$PurchasesTableTableManager get purchases =>
      $$PurchasesTableTableManager(_db.attachedDatabase, _db.purchases);
  $$ItemsTableTableManager get items =>
      $$ItemsTableTableManager(_db.attachedDatabase, _db.items);
  $$PurchasedItemsTableTableManager get purchasedItems =>
      $$PurchasedItemsTableTableManager(
        _db.attachedDatabase,
        _db.purchasedItems,
      );
}
