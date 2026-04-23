import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../core/constants/app_constants.dart';

/// Singleton SQLite database manager.
///
/// Uses FFI on desktop (initialized in main.dart via sqflite_common_ffi)
/// and standard sqflite on mobile platforms.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Use sqflite's getDatabasesPath() — properly overridden by sqflite_common_ffi on desktop
    final dbDir = await getDatabasesPath();

    // Ensure the directory exists (critical on desktop/FFI)
    final dir = Directory(dbDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final path = join(dbDir, AppConstants.databaseName);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // ── Products ──
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        description TEXT,
        unit TEXT,
        is_deleted INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced_at TEXT
      )
    ''');

    // ── Invoices ──
    await db.execute('''
      CREATE TABLE invoices (
        id TEXT PRIMARY KEY,
        invoice_number TEXT NOT NULL UNIQUE,
        subtotal REAL NOT NULL,
        discount_type TEXT DEFAULT 'flat',
        discount_value REAL DEFAULT 0,
        discount_amount REAL DEFAULT 0,
        tax_percent REAL DEFAULT 0,
        tax_amount REAL DEFAULT 0,
        total REAL NOT NULL,
        customer_name TEXT,
        customer_phone TEXT,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        synced_at TEXT
      )
    ''');

    // ── Invoice Items ──
    await db.execute('''
      CREATE TABLE invoice_items (
        id TEXT PRIMARY KEY,
        invoice_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        unit_price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        line_total REAL NOT NULL,
        created_at TEXT NOT NULL,
        synced_at TEXT,
        FOREIGN KEY (invoice_id) REFERENCES invoices(id)
      )
    ''');

    // ── Payments ──
    await db.execute('''
      CREATE TABLE payments (
        id TEXT PRIMARY KEY,
        invoice_id TEXT NOT NULL,
        method TEXT NOT NULL,
        amount REAL NOT NULL,
        created_at TEXT NOT NULL,
        synced_at TEXT,
        FOREIGN KEY (invoice_id) REFERENCES invoices(id)
      )
    ''');

    // ── Shop Profile (single row) ──
    await db.execute('''
      CREATE TABLE shop_profile (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        shop_name TEXT,
        address TEXT,
        phone TEXT,
        email TEXT,
        gstin TEXT,
        default_tax_percent REAL DEFAULT 0
      )
    ''');

    // Seed default shop profile row
    await db.insert('shop_profile', {
      'id': 1,
      'shop_name': 'My Shop',
      'address': '',
      'phone': '',
      'email': '',
      'gstin': '',
      'default_tax_percent': AppConstants.defaultTaxPercent,
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // v1 → v2: Add synced_at column for cloud sync tracking
      await db.execute('ALTER TABLE products ADD COLUMN synced_at TEXT');
      await db.execute('ALTER TABLE invoices ADD COLUMN synced_at TEXT');
      await db.execute('ALTER TABLE invoice_items ADD COLUMN synced_at TEXT');
      await db.execute('ALTER TABLE payments ADD COLUMN synced_at TEXT');
    }
  }

  /// Close the database connection.
  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}
