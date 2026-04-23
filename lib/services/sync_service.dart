import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/database/database_helper.dart';

/// Firebase project configuration for Firestore REST API.
class _FirebaseConfig {
  static const String projectId = 'incoice-da864';
  static const String apiKey = 'AIzaSyDI5KKyTlEMykCuy1s0vbOHuH92rBxD7GI';
  static String get firestoreUrl =>
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';
}

/// Result of a sync operation.
class SyncResult {
  final int productsSynced;
  final int invoicesSynced;
  final String? error;
  const SyncResult({this.productsSynced = 0, this.invoicesSynced = 0, this.error});

  int get totalSynced => productsSynced + invoicesSynced;
  bool get hasError => error != null;
}

/// Cloud Sync Service — pushes local SQLite data to Firestore via REST API.
///
/// Uses Firestore REST API to avoid the C++ SDK / CMake issues on Windows desktop.
/// Sync is one-directional: SQLite → Firestore.
/// Records with `synced_at IS NULL` are considered unsynced.
class SyncService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Sync all unsynced data to Firestore.
  Future<SyncResult> syncAll() async {
    try {
      final products = await _syncProducts();
      final invoices = await _syncInvoices();
      await _syncShopProfile();
      return SyncResult(productsSynced: products, invoicesSynced: invoices);
    } catch (e) {
      return SyncResult(error: e.toString());
    }
  }

  /// Push unsynced products to Firestore.
  Future<int> _syncProducts() async {
    final db = await _dbHelper.database;
    final unsynced = await db.query('products', where: 'synced_at IS NULL AND is_deleted = 0');

    if (unsynced.isEmpty) return 0;

    final now = DateTime.now().toIso8601String();

    for (final product in unsynced) {
      final docId = product['id'] as String;
      await _upsertDocument('products', docId, _mapToFirestoreFields(product));
      await db.update('products', {'synced_at': now}, where: 'id = ?', whereArgs: [docId]);
    }

    return unsynced.length;
  }

  /// Push unsynced invoices (with items and payments) to Firestore.
  Future<int> _syncInvoices() async {
    final db = await _dbHelper.database;
    final unsynced = await db.query('invoices', where: 'synced_at IS NULL');

    if (unsynced.isEmpty) return 0;

    final now = DateTime.now().toIso8601String();

    for (final invoice in unsynced) {
      final invoiceId = invoice['id'] as String;

      // Push invoice document
      await _upsertDocument('invoices', invoiceId, _mapToFirestoreFields(invoice));

      // Push related items
      final items = await db.query('invoice_items', where: 'invoice_id = ?', whereArgs: [invoiceId]);
      for (final item in items) {
        final itemId = item['id'] as String;
        await _upsertDocument('invoices/$invoiceId/items', itemId, _mapToFirestoreFields(item));
        await db.update('invoice_items', {'synced_at': now}, where: 'id = ?', whereArgs: [itemId]);
      }

      // Push related payments
      final payments = await db.query('payments', where: 'invoice_id = ?', whereArgs: [invoiceId]);
      for (final payment in payments) {
        final payId = payment['id'] as String;
        await _upsertDocument('invoices/$invoiceId/payments', payId, _mapToFirestoreFields(payment));
        await db.update('payments', {'synced_at': now}, where: 'id = ?', whereArgs: [payId]);
      }

      // Mark invoice synced
      await db.update('invoices', {'synced_at': now}, where: 'id = ?', whereArgs: [invoiceId]);
    }

    return unsynced.length;
  }

  /// Push shop profile to Firestore.
  Future<void> _syncShopProfile() async {
    final db = await _dbHelper.database;
    final profiles = await db.query('shop_profile', where: 'id = 1');
    if (profiles.isEmpty) return;

    await _upsertDocument('shop_profile', 'main', _mapToFirestoreFields(profiles.first));
  }

  /// Upsert a document to Firestore via REST API (PATCH with updateMask).
  Future<void> _upsertDocument(String collection, String docId, Map<String, dynamic> fields) async {
    final url = '${_FirebaseConfig.firestoreUrl}/$collection/$docId?key=${_FirebaseConfig.apiKey}';

    final body = jsonEncode({'fields': fields});

    final response = await http.patch(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Firestore sync failed (${response.statusCode}): ${response.body}');
    }
  }

  /// Convert a SQLite map to Firestore REST API field format.
  /// Firestore REST uses typed values: {stringValue: "..."}, {doubleValue: ...}, etc.
  Map<String, dynamic> _mapToFirestoreFields(Map<String, dynamic> sqliteMap) {
    final fields = <String, dynamic>{};
    for (final entry in sqliteMap.entries) {
      final value = entry.value;
      if (value == null) {
        fields[entry.key] = {'nullValue': null};
      } else if (value is int) {
        fields[entry.key] = {'integerValue': value.toString()};
      } else if (value is double) {
        fields[entry.key] = {'doubleValue': value};
      } else if (value is bool) {
        fields[entry.key] = {'booleanValue': value};
      } else {
        fields[entry.key] = {'stringValue': value.toString()};
      }
    }
    // Add sync timestamp
    fields['synced_at'] = {'stringValue': DateTime.now().toIso8601String()};
    return fields;
  }
}
