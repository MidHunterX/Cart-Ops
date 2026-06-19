// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'items_dao.dart';

// ignore_for_file: type=lint
mixin _$ItemsDaoMixin on DatabaseAccessor<AppDatabase> {
  $GroupsTable get groups => attachedDatabase.groups;
  $ItemsTable get items => attachedDatabase.items;
  ItemsDaoManager get managers => ItemsDaoManager(this);
}

class ItemsDaoManager {
  final _$ItemsDaoMixin _db;
  ItemsDaoManager(this._db);
  $$GroupsTableTableManager get groups =>
      $$GroupsTableTableManager(_db.attachedDatabase, _db.groups);
  $$ItemsTableTableManager get items =>
      $$ItemsTableTableManager(_db.attachedDatabase, _db.items);
}
