![
Cart Ops mobile app promotional banner collage in dark theme. Features multiple
screenshots showing groups and purchases lists, item entry keypad with
real-time totals and price graph, item details with price history trend, and
tracked purchased food items. Center overlay displays purple shopping cart logo
with 'CART_OPS Advanced Commerce Operator Toolset' text.
](./.assets/cartops_banner2.jpg)

# Cart Ops

Your personal commerce operator toolset focusing on cognitive delegation of
financial resource management via technological assistance.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![SQLite](https://img.shields.io/badge/Sqlite-003B57?style=for-the-badge&logo=sqlite&logoColor=white)

## 🎯 Mission Objectives

![General Plan](./.assets/Cart-Ops-Mockup.svg)

### PHASE ALPHA: GENERAL OPERATIONS

#### Configuration Parameters

- [x] Globally Set Currency Symbol
- [x] Globally Set Theme Colors
- [x] Globally Set Weight Unit (Metric, Imperial or Both)
- [ ] Globally Set Tax Rate (0-100) for countries that display prices without tax

#### Core Operations

- [x] CRUD General purchases + Groups Screen
- [x] CRUD purchase Screen
- [x] Set per purchase budget
- [x] CRUD PurchasedItems Screen
- [x] CRUD reusable items

### PHASE BRAVO: OPERATOR QUALITY OF LIFE

- [x] Item details autocompletion while typing
- [x] ~Item Camera identification (tensorflow)~ Autocompletion works way too well for needing this
- [x] ~Item duplication~ Can be done quickly with autocompletion
- [x] Item suggestions while typing based on history
- [x] Easy price per item/quantity toggle
- [x] Core Numpad UI
- [x] Numpad Variant - Calculator (bottom to top)
- [x] Numpad Variant - Telephone (top to bottom)

### PHASE CHARLIE: ADVANCED OPERATIONS

#### Intelligence & Analytics

- [x] Purchase history
- [x] Price history for individual items
- [x] Price history graph for individual items
- [x] Price history analytics on item autocompletion
- [x] Track Monthly spend

### PHASE DELTA: POLISH

- [x] Modal discount calculation mini-tool
- [x] Delete Image prompt timeout loading bar
- [x] Pop up Image viewer
- [x] Auto-detect recommended default settings
- [x] Keypad Haptics
- [x] Checklist Mode

## 🔫 Developer Operations

To generate DAOs:

```bash
dart run build_runner build
```

To generate app icons before build:

```bash
dart run flutter_launcher_icons
```

Create schema snapshot of current database for testing migrations:

```
dart run drift_dev schema dump lib/core/database/database.dart drift_schemas/
dart run drift_dev schema generate drift_schemas/ test/generated_migrations/
```

## 🚨 Known Operational Defects

### Errors hidden behind Keypad

There's a problem with Snackbar's Z-index. It shows always under BottomSheet by
default. See Issue: [#63254](https://github.com/flutter/flutter/issues/63254).
Item purchase keypad interface is implemented in showModalBottomSheet so, any
errors will be hidden behind the keypad.

### Wrong Autocompletion Details?

Autocompletion takes "last created" item details and not necessarily the "last
purchased". So, if a purchase's purchase date is manually modified, the
autocompletion will use it the next time. Just re-enter the price, after that
it will be fine again until purchase date is manually overridden.
