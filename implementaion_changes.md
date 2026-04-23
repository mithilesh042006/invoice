# 📄 implementation_changes.md

## 🎯 Purpose

This document captures **critical fixes and improvements** to the Phase 1 (MVP) implementation plan for the Smart Shop Manager desktop application.

These changes ensure:

* Clean architecture
* Scalability
* Fewer bugs in future phases

---

# 🔴 1. Payment Model Fix

## ❌ Problem

Duplicate payment information stored in both:

* `Invoice.paymentMethod`
* `Payment.method`

## ✅ Solution

* **Remove `paymentMethod` from Invoice model**
* Use only `Payment` table

## 💡 Benefit

* Supports future **split payments**
* Avoids data inconsistency

---

# 🟡 2. Discount Model Fix

## ❌ Problem

Using both:

* `discountPercent`
* `discountAmount`

This can create ambiguity.

## ✅ Solution

Replace with:

```dart
String discountType; // 'percent' or 'flat'
double discountValue;
```

## 💡 Benefit

* Cleaner logic
* Prevents calculation conflicts

---

# 🟡 3. Tax Calculation Rule (Lock This Early)

## ✅ Standard Flow

```
Subtotal → Discount → Taxable Amount → Tax → Final Total
```

## 💡 Important

* Tax must always be applied **after discount**
* Do not change this logic later

---

# 🔴 4. SQLite Desktop Initialization Fix

## ❌ Problem

SQLite will not work on desktop without FFI initialization

## ✅ Solution (Add in main.dart)

```dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  runApp(const MyApp());
}
```

---

# 🟡 5. Invoice Number Generation Fix

## ❌ Problem

Auto-increment formatted IDs (e.g., INV-00001) are not supported natively

## ✅ Solution

* Use UUID for primary key
* Generate invoice number manually

Example:

```
INV-00001
INV-00002
```

OR

```
INV-20260422-001
```

---

# 🟡 6. Shop Profile Storage Fix

## ❌ Problem

Using `SharedPreferences` for structured data

## ✅ Solution

Store shop profile in SQLite table:

```
shop_profile
```

## 💡 Benefit

* Easier migration
* Consistent data handling

---

# 🟡 7. Reduce Initial Complexity

## ❌ Problem

Too many files (~30) for MVP

## ✅ Solution

Start with minimal implementation:

### Only build:

* Product CRUD
* Basic Invoice screen
* Save invoice to DB

### Add later:

* Settings screen
* Advanced providers
* Full modular structure

---

# 💡 8. Add createdAt Field Everywhere

## ✅ Update all tables:

* products
* invoices
* invoice_items
* payments

```dart
DateTime createdAt;
```

## 💡 Benefit

* Enables analytics later
* Sorting & filtering

---

# 💡 9. Soft Delete for Products (Optional but Recommended)

## ❌ Problem

Deleting products can break old invoices

## ✅ Solution

```sql
is_deleted INTEGER DEFAULT 0
```

## 💡 Benefit

* Keeps historical data intact

---

# 💡 10. Keep Invoice Snapshot Fields (Important)

Ensure invoice items store:

```dart
productName
unitPrice
```

## 💡 Benefit

* Old invoices remain accurate even if product price changes

---

# 🚀 Final Summary

## ✅ MUST DO (Critical)

* Fix payment model
* Fix discount model
* Initialize SQLite FFI
* Lock tax calculation logic

## ⚠️ SHOULD DO

* Move shop profile to SQLite
* Improve invoice number generation

## 💡 OPTIONAL (Recommended)

* Add createdAt fields
* Soft delete support

---

# 🎯 Outcome

After applying these changes, your system will be:

* Cleanly structured
* Scalable for future phases
* Safer for financial data handling
* Easier to maintain and extend
