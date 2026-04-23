import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/analytics_dao.dart';

final analyticsDaoProvider = Provider<AnalyticsDao>((ref) => AnalyticsDao());

/// Today's sales summary.
class TodaySummary {
  final double totalSales;
  final int invoiceCount;
  final double avgValue;
  const TodaySummary({required this.totalSales, required this.invoiceCount, required this.avgValue});
}

final todaySummaryProvider = FutureProvider<TodaySummary>((ref) async {
  final dao = ref.read(analyticsDaoProvider);
  final data = await dao.getTodaySummary();
  return TodaySummary(
    totalSales: data['total_sales'] as double,
    invoiceCount: data['invoice_count'] as int,
    avgValue: data['avg_value'] as double,
  );
});

/// Payment breakdown for today.
final paymentBreakdownProvider = FutureProvider<Map<String, double>>((ref) async {
  final dao = ref.read(analyticsDaoProvider);
  return dao.getPaymentBreakdown(date: DateTime.now());
});

/// Daily sales for last 7 days.
final dailySalesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dao = ref.read(analyticsDaoProvider);
  return dao.getDailySales(days: 7);
});

/// Monthly sales for last 6 months.
final monthlySalesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dao = ref.read(analyticsDaoProvider);
  return dao.getMonthlySales(months: 6);
});

/// Unsynced record count.
final unsyncedCountProvider = FutureProvider<int>((ref) async {
  final dao = ref.read(analyticsDaoProvider);
  return dao.getUnsyncedCount();
});
