# IRL Shopping Assistant

A shopping calculator for IRL Shopping assistance

## Basic Requirements

### Settings Screen

Settings should contain the following:

- Set Currency Symbol
- Set Weight Unit (Metric, Imperial or Both)
- Set Tax Rate (0-100) for countries that display prices without tax
- CRUD Tax Rates for catagories

### Homepage Screen

- Contains a list of purchases
- Contains groups of purchases
- CRUD purchase groups
- CRUD purchase items

### Purchases Screen

- Contains a list of purchases in a group
- Purchase item has these attributes:
  - string name
  - datetime purchase_datetime
  - ref tax_rate
  - total_price (calc)

### Items Screen (Cart)

- Contains a list of items in a purchase
- CRUD items
- Item has these attributes:
  - string name
  - image photo
  - float discount
  - float quantity
  - float price

## Future Requirements

### Imports and Exports

- Export to CSV
- Import from CSV
- Export to PDF

### QOL

- OCR data entry
- Item duplication
- Item suggestions while typing based on history
- Easy price per item/quantity toggle
- Numpad type (top to bottom, bottom to top)
