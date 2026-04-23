# 📄 Barcode Camera Scanning Feature Guide

## 🎯 Purpose

This document explains how to implement **camera-based barcode scanning** in the Smart Shop Manager application and how it integrates with the existing billing system.

---

# 🧠 Feature Overview

The barcode scanning feature allows users to:

* Scan a product barcode using camera
* Automatically fetch product details
* Add the product to the invoice/cart

---

# 🔄 Core Flow

```
Camera Scan → Barcode Value → SQLite Lookup → Add to Invoice → Update Total
```

---

# 📦 Technology Choice

## Recommended Package

```
mobile_scanner
```

### Why?

* Works on mobile and desktop (webcam)
* Fast and lightweight
* Easy integration with Flutter

---

# 🗄️ Database Requirement

## Add Barcode Field to Product Table

```sql
barcode TEXT UNIQUE
```

### Example Product Record

```json
{
  "id": "p1",
  "name": "Rice",
  "price": 50,
  "barcode": "8901234567890"
}
```

---

# 🧱 Implementation Steps

## 1. Update Product Form

Add:

* Barcode input field
* "Scan Barcode" button (recommended)

---

## 2. Create Scanner Screen

### File Path

```
lib/features/scanner/scanner_screen.dart
```

### Basic Implementation

```dart
MobileScanner(
  onDetect: (barcode, args) {
    final String? code = barcode.rawValue;
    if (code != null) {
      Navigator.pop(context, code);
    }
  },
)
```

---

## 3. Integrate with Invoice Screen

### Add Scan Button

On click:

```dart
final scannedCode = await Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => ScannerScreen()),
);

if (scannedCode != null) {
  final product = await repo.getByBarcode(scannedCode);

  if (product != null) {
    addToInvoice(product);
  } else {
    showSnackBar("Product not found");
  }
}
```

---

# 💡 UX Enhancements

## 1. Continuous Scan Mode (Advanced)

* Toggle ON/OFF
* Camera stays active
* Automatically adds items on scan

---

## 2. Smart Quantity Handling

* If product already exists in cart:

  * Increase quantity instead of adding duplicate

---

## 3. Feedback System

* Beep sound on successful scan
* Highlight last added product

---

# ⚠️ Desktop Considerations

## 1. Camera Permissions

* Users must allow camera access manually

## 2. Multiple Cameras

* Provide option to select camera

## 3. Performance

* Desktop scanning may be slower than mobile

---

# 🔥 Recommended Usage Strategy

## Desktop App

* Default: Manual search + selection
* Optional: Scan button for camera input

## Mobile App (Future)

* Camera-first experience

---

# ❌ Common Mistakes to Avoid

* ❌ Directly adding scanned data without lookup
* ❌ Not storing barcode in database
* ❌ Blocking UI during scan

---

# 🚀 Future Enhancements

* AI-based product recognition
* Batch scanning mode
* Barcode auto-generation for products

---

# 🎯 Conclusion

Camera-based barcode scanning enhances speed and usability but should be treated as an **optional feature**.

The core billing system must remain fully functional without it.


