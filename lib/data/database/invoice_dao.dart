import 'package:sqflite/sqflite.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../models/payment.dart';
import 'database_helper.dart';

/// Data Access Object for invoices, invoice_items, and payments tables.
class InvoiceDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Create a complete invoice in a single transaction:
  /// inserts invoice row + all item rows + payment row.
  Future<void> createInvoice({
    required Invoice invoice,
    required List<InvoiceItem> items,
    required Payment payment,
  }) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.insert('invoices', invoice.toMap());
      for (final item in items) {
        await txn.insert('invoice_items', item.toMap());
      }
      await txn.insert('payments', payment.toMap());
    });
  }

  /// Get all invoices, newest first.
  Future<List<Invoice>> getAllInvoices() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'invoices',
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Invoice.fromMap(m)).toList();
  }

  /// Get invoices for a specific date.
  Future<List<Invoice>> getInvoicesByDate(DateTime date) async {
    final db = await _dbHelper.database;
    final dateStr = DateTime(date.year, date.month, date.day).toIso8601String();
    final nextDateStr =
        DateTime(date.year, date.month, date.day + 1).toIso8601String();

    final maps = await db.query(
      'invoices',
      where: 'date >= ? AND date < ?',
      whereArgs: [dateStr, nextDateStr],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Invoice.fromMap(m)).toList();
  }

  /// Get a single invoice by ID.
  Future<Invoice?> getInvoiceById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'invoices',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Invoice.fromMap(maps.first);
  }

  /// Get all items for an invoice.
  Future<List<InvoiceItem>> getInvoiceItems(String invoiceId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'invoice_items',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
    );
    return maps.map((m) => InvoiceItem.fromMap(m)).toList();
  }

  /// Get the payment(s) for an invoice.
  Future<List<Payment>> getInvoicePayments(String invoiceId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'payments',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
    );
    return maps.map((m) => Payment.fromMap(m)).toList();
  }

  /// Get the next sequential invoice number.
  /// Queries the max existing number and returns +1.
  Future<int> getNextInvoiceSequence() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM invoices',
    );
    final count = Sqflite.firstIntValue(result) ?? 0;
    return count + 1;
  }

  /// Get the shop profile.
  Future<Map<String, dynamic>?> getShopProfile() async {
    final db = await _dbHelper.database;
    final maps = await db.query('shop_profile', where: 'id = 1');
    if (maps.isEmpty) return null;
    return maps.first;
  }

  /// Update the shop profile.
  Future<void> updateShopProfile(Map<String, dynamic> profile) async {
    final db = await _dbHelper.database;
    profile['id'] = 1;
    await db.update(
      'shop_profile',
      profile,
      where: 'id = 1',
    );
  }
}
