# 📄 Product Requirements Document (PRD)

## 🧾 Product Name

**Smart Shop Manager (Desktop App)**

---

# 🎯 1. Product Overview

A simple, offline-first desktop application built using **Flutter + Firebase** to help small shop owners:

* Generate invoices
* Track payments (cash / UPI / card)
* Manage workers and salaries
* View daily business summaries and analytics

The app is designed for **single-user (shop owner only)** with **no role complexity**.

---

# 🧠 2. Problem Statement

Small local shops face issues such as:

* Manual billing errors
* No clear tracking of payment modes
* Difficulty managing worker salaries
* Lack of insights into daily profit/loss

Existing solutions are often:

* Too complex
* Overloaded with features
* Not user-friendly for small shop owners

---

# 💡 3. Solution

Build a **simple, fast, and offline-first desktop app** that combines:

* Billing system
* Payment tracking
* Worker management
* Daily analytics dashboard

---

# 👤 4. Target Users

* Small shop owners
* Retail stores
* Local vendors using desktop/laptop for billing

---

# 🧱 5. Core Modules

1. Product Management
2. Invoice & Billing System
3. Payment Tracking
4. Worker Management
5. Salary Management
6. Daily Shop Summary
7. Analytics Dashboard

---

# 🏗️ 6. Technical Stack

## Frontend

* Flutter (Desktop - Windows focus)

## Backend

* Firebase (optional sync)

## Database

* Local: SQLite / Hive (offline-first)
* Cloud: Firebase Firestore

## Other

* PDF Generation: Flutter PDF package
* Charts: fl_chart

---

# 📦 7. Feature Breakdown (Phase-wise)

---

## 🚀 Phase 1: MVP (Billing Core)

### Features:

### 1. Product Management

* Add product
* Edit product
* Delete product
* Store price & basic info

### 2. Invoice Generation

* Select products
* Enter quantity
* Auto calculation (total)

### 3. Payment Tracking

* Select payment mode:

  * Cash
  * UPI
  * Card

### 4. Invoice Output

* Generate PDF invoice
* Save locally

---

## 🧩 Phase 2: Worker & Salary Management

### 1. Worker Management

* Add worker
* Store:

  * Name
  * Phone
  * Salary type (daily/monthly)
  * Salary amount

### 2. Attendance Tracking

* Mark daily attendance

### 3. Salary Calculation

* Daily wage = days × wage
* Monthly salary = fixed

### 4. Salary Records

* Store payments made

---

## 📊 Phase 3: Analytics & Dashboard

### 1. Daily Shop Summary (KEY FEATURE)

Show:

* Total sales
* Cash / UPI / Card breakdown
* Total salary paid
* Net income (basic)

### 2. Graphs

* Daily sales graph
* Monthly sales graph
* Payment mode pie chart
* Salary expense graph

---

## ☁️ Phase 4: Cloud Sync (Optional)

### Features:

* Sync local data to Firebase
* Backup & restore
* Multi-device access (future)

---

## 🔥 Phase 5: Advanced Features (Optional)

* Voice-based billing
* Auto insights ("UPI usage increased")
* Export reports (PDF/Excel)

---

# 🔄 8. User Flow

## Billing Flow

User → Select Product → Enter Quantity → Choose Payment → Generate Invoice → Save

## Worker Flow

User → Add Worker → Mark Attendance → Calculate Salary → Record Payment

## Summary Flow

System → Aggregate Data → Display Dashboard

---

# 🗄️ 9. Database Design (Simplified)

## Products

* id
* name
* price

## Invoices

* id
* total
* date

## Payments

* invoice_id
* method
* amount

## Workers

* id
* name
* salary_type
* salary_amount

## Attendance

* worker_id
* date
* present

## Salaries

* worker_id
* total_paid
* month

---

# 🎨 10. UI/UX Principles

* Simple and clean interface
* Large buttons (easy for shop use)
* Minimal steps for billing
* Fast interaction (no lag)

---

# ⚠️ 11. Constraints

* Must work offline
* Should run on low-end PCs
* Easy installation

---

# 📈 12. Success Metrics

* Time to generate invoice < 10 seconds
* User can learn app in < 15 minutes
* Daily summary accuracy = 100%

---

# 🚀 13. Future Scope

* Mobile app version
* Multi-shop support
* GST compliance features

---

# ✅ 14. Conclusion

This application aims to simplify shop management by combining billing, payments, worker management, and analytics into a single easy-to-use desktop solution.
