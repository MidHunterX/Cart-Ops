# **Software Requirements Specification (SRS)**

**Project Name:** IRL Shopping Assistant
**Author:** MidHunterX
**Version:** 1.0
**Date:** 2025-05-06

---

## **1. Introduction**

### 1.1 Purpose

The IRL Shopping Assistant aims to aid users during in-real-life (IRL) shopping by allowing them to log, categorize, and calculate purchases in real-time. It is designed for accuracy, tax support, and convenience, especially in mall environments with diverse purchase types.

### 1.2 Scope

The application will:

- Track purchases grouped by shopping trips or categories.
- Support different currencies, weight units, and tax systems.
- Offer advanced features such as discount handling, cart management, and OCR-assisted item entry.
- Operate offline and prioritize user privacy.

### 1.3 Definitions

- **Purchase Group:** A logical group representing a shopping trip or category.
- **Purchase:** A collection of items bought in one transaction or at one store.
- **Item:** A product in a purchase with attributes like name, price, and quantity.
- **Tax Rate:** Percentage applied to items for calculating final cost.

---

## **2. Overall Description**

### 2.1 Product Perspective

This is a standalone application, available on mobile (Flutter). It will store data locally and optionally support CSV/PDF export.

### 2.2 Product Functions

- CRUD operations for items, purchases, and purchase groups.
- Tax calculations and discount applications.
- Currency and unit configuration.
- Data export (CSV, PDF) and import.
- (Future) OCR for rapid entry, suggestions from history.

### 2.3 User Characteristics

- Regular shoppers (mall, groceries)
- Small business owners tracking irregular purchases
- Travelers managing multi-tax region purchases

### 2.4 Assumptions and Dependencies

- No back-end required (local storage or SQLite)
- Image capture depends on platform support
- OCR functionality will require an OCR library or API

---

## **3. Specific Requirements**

### 3.1 Functional Requirements

#### 3.1.1 Settings Screen

- F1.1: User can set default currency symbol.
- F1.2: User can choose weight unit system (Metric, Imperial, Both).
- F1.3: User can set default tax rate (0–100%).
- F1.4: User can CRUD multiple tax rate categories.

#### 3.1.2 Homepage

- F2.1: Display all purchase groups.
- F2.2: User can create, read, update, delete purchase groups.
- F2.3: User can view total spending across groups.

#### 3.1.3 Purchases Screen

- F3.1: Display list of purchases under selected group.
- F3.2: User can CRUD purchases.
- F3.3: Purchase attributes:

  - Name
  - Purchase DateTime
  - Tax Rate (from predefined list)
  - Total Price (auto-calculated from items)

#### 3.1.4 Items Screen (Cart)

- F4.1: Display all items within a purchase.
- F4.2: User can CRUD items.
- F4.3: Each item includes:

  - Name
  - Optional image/photo
  - Quantity (float)
  - Price (per item or total)
  - Discount (as % or fixed)

- F4.4: Toggle between price per quantity or total price entry.

### 3.2 Non-Functional Requirements

- N1: Offline-first
- N2: Lightweight and responsive
- N3: Intuitive UI/UX
- N4: Privacy-respecting (no third-party sync)

---

## **4. Future Requirements**

### 4.1 Import/Export

- F5.1: Export data to CSV and PDF
- F5.2: Import purchases/items from CSV

### 4.2 Quality of Life

- F6.1: OCR for auto-filling item data (receipt parsing)
- F6.2: Duplicate item/purchase
- F6.3: Item suggestion from previous history
- F6.4: Configurable calculator/numpad layout

---

## **5. Data Model (Initial Draft)**

```sql
Settings
- currency_symbol: string
- weight_unit: enum [metric, imperial, both]
- default_tax_rate: float

TaxRate
- id: uuid
- name: string
- percentage: float

PurchaseGroup
- id: uuid
- name: string
- created_at: datetime

Purchase
- id: uuid
- group_id: ref -> PurchaseGroup
- name: string
- purchase_datetime: datetime
- tax_rate_id: ref -> TaxRate

Item
- id: uuid
- purchase_id: ref -> Purchase
- name: string
- image: file (optional)
- quantity: float
- price: float
- discount: float
```
