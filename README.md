# Cart-Ops

Personal commerce operator tool focusing on the expansion of human abilities through technological assistance.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![SQLite](https://img.shields.io/badge/Sqlite-003B57?style=for-the-badge&logo=sqlite&logoColor=white)

## Dev Snippets

On every DB change, run the following command:

```sh
dart run build_runner build
```

## Basic Requirements

![General Plan](./.assets/Cart-Ops-Mockup.svg)

### Settings Screen

- [x] Globally Set Currency Symbol
- [x] Globally Set Theme Colors
- [x] Globally Set Weight Unit (Metric, Imperial or Both)
- [ ] Globally Set Tax Rate (0-100) for countries that display prices without tax
- [x] CRUD General purchases + Groups Screen
- [x] CRUD purchase Screen
- [x] CRUD PurchasedItems Screen
- [x] CRUD reusable items
- [x] Settings Screen

## Future Requirements

### Analytics

- [x] Purchase history
- [x] Price history for individual items
- [ ] Price history graph for individual items
- [ ] Price history graph for all items timeline
- [ ] Monthly spend

### Imports and Exports

- [ ] Export to CSV
- [ ] Import from CSV
- [ ] Export to PDF

### QOL

- [x] Item details autocompletion while typing
- [ ] Item details autocompletion with Camera identification (tensorflow)
- [ ] Item duplication
- [x] Item suggestions while typing based on history
- [x] Easy price per item/quantity toggle
- [x] Basic Numpad
- [x] Numpad UI
- [ ] Numpad Variants (top to bottom, bottom to top)
