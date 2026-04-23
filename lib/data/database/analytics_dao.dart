import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

/// Data Access Object for analytics aggregate queries.
class AnalyticsDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Get today's sales summary: total revenue, invoice count, average.
  Future<Map<String, dynamic>> getTodaySummary() async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();
    final todayEnd = DateTime(now.year, now.month, now.day + 1).toIso8601String();

    final result = await db.rawQuery('''
      SELECT
        COALESCE(SUM(total), 0) as total_sales,
        COUNT(*) as invoice_count,
        COALESCE(AVG(total), 0) as avg_value
      FROM invoices
      WHERE date >= ? AND date < ?
    ''', [todayStart, todayEnd]);

    if (result.isEmpty) {
      return {'total_sales': 0.0, 'invoice_count': 0, 'avg_value': 0.0};
    }
    return {
      'total_sales': (result.first['total_sales'] as num).toDouble(),
      'invoice_count': result.first['invoice_count'] as int,
      'avg_value': (result.first['avg_value'] as num).toDouble(),
    };
  }

  /// Get payment method breakdown for a given date.
  Future<Map<String, double>> getPaymentBreakdown({DateTime? date}) async {
    final db = await _dbHelper.database;
    String whereClause = '';
    List<String> whereArgs = [];

    if (date != null) {
      final dayStart = DateTime(date.year, date.month, date.day).toIso8601String();
      final dayEnd = DateTime(date.year, date.month, date.day + 1).toIso8601String();
      whereClause = 'WHERE p.created_at >= ? AND p.created_at < ?';
      whereArgs = [dayStart, dayEnd];
    }

    final result = await db.rawQuery('''
      SELECT
        p.method,
        COALESCE(SUM(p.amount), 0) as total
      FROM payments p
      $whereClause
      GROUP BY p.method
    ''', whereArgs);

    final breakdown = <String, double>{'cash': 0, 'upi': 0, 'card': 0};
    for (final row in result) {
      final method = row['method'] as String;
      breakdown[method] = (row['total'] as num).toDouble();
    }
    return breakdown;
  }

  /// Get daily sales for the last N days.
  Future<List<Map<String, dynamic>>> getDailySales({int days = 7}) async {
    final db = await _dbHelper.database;
    final startDate = DateTime.now().subtract(Duration(days: days - 1));
    final startStr = DateTime(startDate.year, startDate.month, startDate.day).toIso8601String();

    final result = await db.rawQuery('''
      SELECT
        DATE(date) as day,
        COALESCE(SUM(total), 0) as total
      FROM invoices
      WHERE date >= ?
      GROUP BY DATE(date)
      ORDER BY day ASC
    ''', [startStr]);

    // Fill in missing days with 0
    final salesMap = <String, double>{};
    for (final row in result) {
      salesMap[row['day'] as String] = (row['total'] as num).toDouble();
    }

    final dailyData = <Map<String, dynamic>>[];
    for (int i = 0; i < days; i++) {
      final d = DateTime(startDate.year, startDate.month, startDate.day + i);
      final key = d.toIso8601String().substring(0, 10);
      dailyData.add({'date': d, 'total': salesMap[key] ?? 0.0});
    }
    return dailyData;
  }

  /// Get monthly sales for the last N months.
  Future<List<Map<String, dynamic>>> getMonthlySales({int months = 6}) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final startMonth = DateTime(now.year, now.month - months + 1, 1);
    final startStr = startMonth.toIso8601String();

    final result = await db.rawQuery('''
      SELECT
        strftime('%Y-%m', date) as month,
        COALESCE(SUM(total), 0) as total
      FROM invoices
      WHERE date >= ?
      GROUP BY strftime('%Y-%m', date)
      ORDER BY month ASC
    ''', [startStr]);

    final salesMap = <String, double>{};
    for (final row in result) {
      salesMap[row['month'] as String] = (row['total'] as num).toDouble();
    }

    final monthlyData = <Map<String, dynamic>>[];
    for (int i = 0; i < months; i++) {
      final m = DateTime(startMonth.year, startMonth.month + i, 1);
      final key = '${m.year}-${m.month.toString().padLeft(2, '0')}';
      monthlyData.add({'date': m, 'total': salesMap[key] ?? 0.0});
    }
    return monthlyData;
  }

  /// Count records that haven't been synced yet.
  Future<int> getUnsyncedCount() async {
    final db = await _dbHelper.database;
    final products = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM products WHERE synced_at IS NULL AND is_deleted = 0'));
    final invoices = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM invoices WHERE synced_at IS NULL'));
    return (products ?? 0) + (invoices ?? 0);
  }
}
