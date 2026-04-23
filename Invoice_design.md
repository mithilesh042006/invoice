# 📄 Invoice Design Guidelines

## 🎯 Purpose

This document defines the **standard structure and required fields** for generating a professional invoice in the Smart Shop Manager application.

---

# 🧾 1. Shop / Business Details (Header)

## ✅ Required Fields

* Shop Name
* Address
* Phone Number
* Email (optional)
* GSTIN (for India)

## 📌 Example

```
My Shop
123 Main Street, Chennai
Phone: 9876543210
GSTIN: 33XXXXXXXXXX
```

---

# 🧾 2. Invoice Metadata

## ✅ Required Fields

* Invoice Number
* Date

## ➕ Optional Fields

* Time
* Invoice Type (Cash / Credit)

---

# 👤 3. Customer Details (Optional)

## Fields

* Customer Name
* Phone Number

## 💡 Use Case

* Useful for credit tracking
* Helps identify repeat customers

---

# 📦 4. Item Table Structure

## ✅ Required Columns

* S.No
* Product Name
* Quantity
* Unit (kg, pcs, etc.)
* Unit Price
* Total Price

## 📌 Example

| S.No | Product | Qty | Unit | Price | Total |
| ---- | ------- | --- | ---- | ----- | ----- |
| 1    | Rice    | 2   | kg   | ₹50   | ₹100  |

---

# 💰 5. Calculation Section

## ✅ Required Breakdown

```
Subtotal: ₹500
Discount: ₹50
Tax (18%): ₹81
-------------------
Grand Total: ₹531
```

## 📌 Rules

* Apply discount first
* Apply tax on discounted amount

---

# 💳 6. Payment Details

## ✅ Required Fields

* Payment Mode (Cash / UPI / Card)
* Amount Paid
* Balance (if any)

## 📌 Example

```
Payment Mode: CASH
Amount Paid: ₹500
Balance: ₹0
```

---

# 🧾 7. Footer Section

## Recommended Content

* "Thank you for your business"
* Return policy (optional)
* Signature line (optional)

---

# 📊 8. Optional Advanced Fields

* Internal Invoice ID (UUID)
* Notes section
* Created timestamp

---

# ⚠️ 9. Known Issue: Currency Symbol

## ❌ Problem

₹ symbol not rendering correctly in PDF

## ✅ Solution

* Use Unicode-supported font
* Ensure proper font embedding in PDF

---

# 🧠 Final Invoice Layout (Reference)

```
[SHOP NAME]
[ADDRESS | PHONE | GSTIN]

Invoice No: INV-00004
Date: 23/04/2026

Customer: John

---------------------------------------
S.No | Product | Qty | Price | Total
---------------------------------------
1    | toto    | 1   | ₹500  | ₹500
---------------------------------------

Subtotal: ₹500
Discount: ₹0
Tax (18%): ₹0
-------------------------
GRAND TOTAL: ₹500

Payment Mode: CASH
Paid: ₹500
Balance: ₹0

-------------------------
Thank you for your business!
```

---

# 🚀 Implementation Priority

## 🔴 Must Have

* Currency symbol fix
* Calculation breakdown

## 🟡 Should Have

* Shop details
* Customer details

## 🟢 Nice to Have

* Footer message
* Notes section

---

# 🎯 Conclusion

A good invoice should be:

* Clear
* Accurate
* Easy to read

Focus on usability over design complexity.
