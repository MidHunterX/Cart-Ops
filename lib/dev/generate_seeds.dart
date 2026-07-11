import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:drift/drift.dart';
import 'package:faker/faker.dart';
import 'package:shopping_assist/core/database/database.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shopping_assist/dev/base_64_images.dart';
import 'package:uuid/uuid.dart';

/// Configuration for the database seeder to control data volume.
class SeederConfig {
  final int numGroups;
  final int minItemsPerGroup;
  final int maxItemsPerGroup;
  final int minPurchasesPerGroup;
  final int maxPurchasesPerGroup;
  final int numOrphanItems;
  final int numOrphanPurchases;
  final int minPurchasedItems;
  final int maxPurchasedItems;

  const SeederConfig({
    this.numGroups = 1,

    this.minItemsPerGroup = 10,
    this.maxItemsPerGroup = 25,

    this.minPurchasesPerGroup = 3,
    this.maxPurchasesPerGroup = 8,

    this.numOrphanItems = 5,
    this.numOrphanPurchases = 10,

    this.minPurchasedItems = 2,
    this.maxPurchasedItems = 12,
  });
}

class DatabaseSeeder {
  final AppDatabase _db;
  final SeederConfig _config;
  final Faker _faker;
  final Random _random;

  DatabaseSeeder(this._db, {this._config = const SeederConfig()})
    : _faker = Faker(),
      _random = Random();

  Future<void> personalSeed() async {
    print('Starting Personal Database Seeder...');

    final imgpathFruits = await _createSeedImageFromBase64(baseFruits);
    final imgpathLunch = await _createSeedImageFromBase64(baseLunch);
    final imgpathMurukku = await _createSeedImageFromBase64(baseMurukku);
    final imgpathPickle = await _createSeedImageFromBase64(basePickle);

    final purchaseId = await _db.purchasesDao.insertPurchase(
      PurchasesCompanion.insert(
        name: "${_faker.company.name()} ${_faker.company.suffix()}",
        purchaseDate: DateTime.now(),
        budget: Value(1500),
      ),
    );

    await _db.purchasedItemsDao.insertPurchasedItem(
      PurchasedItemsCompanion.insert(
        name: Value.absent(),
        price: Value(150),
        quantity: Value(1.33),
        isWeight: Value(true),
        discount: Value.absent(),
        imagePath: Value(imgpathMurukku),
        purchaseId: purchaseId,
      ),
    );

    await _db.purchasedItemsDao.insertPurchasedItem(
      PurchasedItemsCompanion.insert(
        name: Value.absent(),
        price: Value(325),
        quantity: Value(2),
        isWeight: Value(false),
        discount: Value.absent(),
        imagePath: Value(imgpathPickle),
        purchaseId: purchaseId,
      ),
    );

    await _db.purchasedItemsDao.insertPurchasedItem(
      PurchasedItemsCompanion.insert(
        name: Value.absent(),
        price: Value(25),
        quantity: Value(4),
        isWeight: Value(false),
        discount: Value.absent(),
        purchaseId: purchaseId,
      ),
    );

    await _db.purchasedItemsDao.insertPurchasedItem(
      PurchasedItemsCompanion.insert(
        name: Value.absent(),
        price: Value(25),
        quantity: Value(3.57),
        isWeight: Value(true),
        discount: Value.absent(),
        purchaseId: purchaseId,
      ),
    );

    await _db.purchasedItemsDao.insertPurchasedItem(
      PurchasedItemsCompanion.insert(
        name: Value("Weight Only"),
        price: Value.absent(),
        quantity: Value(3.57),
        isWeight: Value(true),
        discount: Value.absent(),
        purchaseId: purchaseId,
      ),
    );

    await _db.purchasedItemsDao.insertPurchasedItem(
      PurchasedItemsCompanion.insert(
        name: Value("Item Only"),
        price: Value.absent(),
        quantity: Value(4),
        isWeight: Value(false),
        discount: Value.absent(),
        purchaseId: purchaseId,
      ),
    );

    await _db.purchasedItemsDao.insertPurchasedItem(
      PurchasedItemsCompanion.insert(
        name: Value("Mentos Large"),
        price: Value(20),
        quantity: Value.absent(),
        isWeight: Value(false),
        discount: Value.absent(),
        purchaseId: purchaseId,
      ),
    );

    await _db.purchasedItemsDao.insertPurchasedItem(
      PurchasedItemsCompanion.insert(
        name: Value("Onion Red"),
        price: Value(35),
        quantity: Value.absent(),
        isWeight: Value(true),
        discount: Value.absent(),
        purchaseId: purchaseId,
      ),
    );

    await _db.purchasedItemsDao.insertPurchasedItem(
      PurchasedItemsCompanion.insert(
        name: Value("Fresh Fruits"),
        price: Value(25),
        quantity: Value(3.57),
        isWeight: Value(true),
        discount: Value(4),
        imagePath: Value(imgpathFruits),
        purchaseId: purchaseId,
      ),
    );

    await _db.purchasedItemsDao.insertPurchasedItem(
      PurchasedItemsCompanion.insert(
        name: Value("Rice Lunch"),
        price: Value(25),
        quantity: Value(4),
        isWeight: Value(false),
        discount: Value(5),
        imagePath: Value(imgpathLunch),
        purchaseId: purchaseId,
      ),
    );

    await _db.purchasesDao.recalculatePurchaseTotal(purchaseId);

    print('Personal Seed Complete');
  }

  /// Clears existing data and seeds the database with random data.
  Future<void> seed() async {
    print('Starting Database Seeder...');

    // Optional: Clear existing data before seeding
    await _clearDatabase();

    // 1. Seed Groups
    final Map<int, List<int>> groupItemsMap = {};
    final List<int> groupIds = [];

    for (int i = 0; i < _config.numGroups; i++) {
      final groupName = '${_faker.company.name()} ${_faker.company.suffix()}';
      final groupId = await _db.groupsDao.insertGroup(GroupsCompanion.insert(name: groupName));
      groupIds.add(groupId);
      groupItemsMap[groupId] = [];
    }
    print('Seeded ${_config.numGroups} Groups');

    // 2. Seed Items (Grouped)
    for (final groupId in groupIds) {
      final numItems =
          _random.nextInt(_config.maxItemsPerGroup - _config.minItemsPerGroup) +
          _config.minItemsPerGroup;
      for (int i = 0; i < numItems; i++) {
        final itemId = await _db.itemsDao.insertItem(
          ItemsCompanion.insert(name: _generateItemName(), groupId: Value(groupId)),
        );
        groupItemsMap[groupId]!.add(itemId);
      }
    }

    // 3. Seed Items (Orphans / No Group)
    final List<int> orphanItemIds = [];
    for (int i = 0; i < _config.numOrphanItems; i++) {
      final itemId = await _db.itemsDao.insertItem(
        ItemsCompanion.insert(name: _generateItemName()),
      );
      orphanItemIds.add(itemId);
    }
    print('Seeded Items');

    // Collect all purchase intents to interleave and sort them chronologically
    final pendingPurchases = <({int? groupId, List<int> availableItemIds})>[];

    for (final groupId in groupIds) {
      final numPurchases =
          _random.nextInt(_config.maxPurchasesPerGroup - _config.minPurchasesPerGroup) +
          _config.minPurchasesPerGroup;

      for (int i = 0; i < numPurchases; i++) {
        pendingPurchases.add((groupId: groupId, availableItemIds: groupItemsMap[groupId]!));
      }
    }

    for (int i = 0; i < _config.numOrphanPurchases; i++) {
      pendingPurchases.add((groupId: null, availableItemIds: orphanItemIds));
    }

    // Shuffle so purchases from different groups are mixed randomly in time
    pendingPurchases.shuffle(_random);

    // Generate sequential random dates for all purchases
    final purchaseDates = List.generate(pendingPurchases.length, (_) {
      final daysAgo = _random.nextInt(180);
      final hoursAgo = _random.nextInt(24);
      final minutesAgo = _random.nextInt(60);
      return DateTime.now().subtract(Duration(days: daysAgo, hours: hoursAgo, minutes: minutesAgo));
    });

    // Sort dates from oldest to newest to mimic real-life chronological purchasing
    purchaseDates.sort((a, b) => a.compareTo(b));

    // 5. Execute all purchases in chronological sequential order
    for (int i = 0; i < pendingPurchases.length; i++) {
      final intent = pendingPurchases[i];
      await _createPurchaseWithItems(intent.groupId, intent.availableItemIds, purchaseDates[i]);
    }

    print('Seeded Purchases and Purchased Items');
    print('Database Seeding Completed!');
  }

  /// Helper to generate realistic item names
  String _generateItemName() {
    final categories = [
      _faker.food.dish(),
      _faker.food.cuisine(),
      '${_faker.lorem.word()} Brand ${_faker.food.dish()}',
      'Fresh ${_faker.food.dish()}',
    ];
    // Capitalize first letter
    String name = categories[_random.nextInt(categories.length)];
    return name[0].toUpperCase() + name.substring(1);
  }

  /// Helper to create a purchase and populate it with items
  Future<void> _createPurchaseWithItems(
    int? groupId,
    List<int> availableItemIds,
    DateTime purchaseDate,
  ) async {
    // Extract real month from the sorted sequence date rather than a random faker string
    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final monthName = monthNames[purchaseDate.month - 1];

    final purchaseName = groupId == null ? 'Quick Run - $monthName' : 'Shopping at $monthName';

    // Create the Purchase entry
    final purchaseId = await _db.purchasesDao.insertPurchase(
      PurchasesCompanion.insert(
        name: purchaseName,
        purchaseDate: purchaseDate,
        groupId: Value(groupId),
        budget: Value(_random.nextDouble() * 200 + 50), // Budget between 50 and 250
      ),
    );

    // Add random items to this purchase
    final numItems =
        _random.nextInt(_config.maxPurchasedItems - _config.minPurchasedItems) +
        _config.minPurchasedItems;

    // Shuffle available items to pick random unique ones for this purchase
    final shuffledItems = List<int>.from(availableItemIds)..shuffle(_random);
    final selectedItems = shuffledItems.take(numItems).toList();

    double totalPrice = 0.0;

    for (final itemId in selectedItems) {
      // Fetch the base item to copy its name to the purchased item record
      final item = await _db.itemsDao.findItem(itemId, groupId);

      final price = double.parse(
        (_random.nextDouble() * 40 + 1).toStringAsFixed(2),
      ); // Price $1 to $41
      final isWeight = _random.nextBool();
      final qty = isWeight
          ? double.parse((_random.nextDouble() * 4 + 0.5).toStringAsFixed(2)) // 0.5kg to 4.5kg
          : (_random.nextInt(5) + 1).toDouble(); // 1 to 5 units

      final discount = _random.nextDouble() > 0.8
          ? double.parse((_random.nextDouble() * 5).toStringAsFixed(2)) // 20% chance of discount
          : 0.0;

      await _db.purchasedItemsDao.insertPurchasedItem(
        PurchasedItemsCompanion.insert(
          name: Value(item?.name),
          price: Value(price),
          quantity: Value(qty),
          isWeight: Value(isWeight),
          discount: Value(discount),
          purchaseId: purchaseId,
          itemId: Value(itemId),
        ),
      );

      totalPrice += (price * qty) - discount;
    }

    // Update the purchase with the calculated total price
    await _db.purchasesDao.updatePurchase(
      PurchasesCompanion(id: Value(purchaseId), totalPrice: Value(totalPrice)),
    );
  }

  /// Clears the entire database (Cascade deletion handles child tables)
  Future<void> _clearDatabase() async {
    await _db.customStatement('DELETE FROM purchased_items');
    await _db.customStatement('DELETE FROM purchases');
    await _db.customStatement('DELETE FROM items');
    await _db.customStatement('DELETE FROM groups');
  }

  Future<String> _createSeedImageFromBase64(String base64) async {
    final bytes = base64Decode(base64);
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'seed_${const Uuid().v4()}.png';
    final file = File('${directory.path}/$fileName');

    await file.writeAsBytes(bytes);
    return file.path;
  }
}
