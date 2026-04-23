import 'package:sqflite/sqflite.dart';
import '../models/product.dart';
import 'database_helper.dart';

/// Data Access Object for the products table.
class ProductDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Insert a new product.
  Future<void> insert(Product product) async {
    final db = await _dbHelper.database;
    await db.insert(
      'products',
      product.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update an existing product.
  Future<void> update(Product product) async {
    final db = await _dbHelper.database;
    await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  /// Soft delete a product (sets is_deleted = 1).
  /// Does NOT physically remove the row — old invoices keep their references.
  Future<void> softDelete(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'products',
      {
        'is_deleted': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get all active (non-deleted) products, ordered by name.
  Future<List<Product>> getAllActive() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'products',
      where: 'is_deleted = 0',
      orderBy: 'name ASC',
    );
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  /// Get a single product by ID.
  Future<Product?> getById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  /// Search active products by name (case-insensitive).
  Future<List<Product>> search(String query) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'products',
      where: 'is_deleted = 0 AND name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'name ASC',
    );
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  /// Get total count of active products.
  Future<int> getActiveCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM products WHERE is_deleted = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
