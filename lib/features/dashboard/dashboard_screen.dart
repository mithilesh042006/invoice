import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import 'dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.dashboard, color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          Text('Dashboard', style: Theme.of(context).textTheme.headlineMedium),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: () {
              ref.invalidate(todaySummaryProvider);
              ref.invalidate(paymentBreakdownProvider);
              ref.invalidate(dailySalesProvider);
              ref.invalidate(monthlySalesProvider);
            },
          ),
        ]),
        const SizedBox(height: 20),
        Expanded(child: SingleChildScrollView(child: Column(children: [
          // Summary cards
          _SummaryCards(),
          const SizedBox(height: 20),
          // Payment breakdown
          _PaymentBreakdown(),
          const SizedBox(height: 20),
          // Charts row
          SizedBox(height: 280, child: Row(children: [
            Expanded(child: _DailySalesChart()),
            const SizedBox(width: 20),
            Expanded(child: _MonthlySalesChart()),
          ])),
        ]))),
      ]),
    );
  }
}

class _SummaryCards extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(todaySummaryProvider);
    return summaryAsync.when(
      data: (s) => Row(children: [
        Expanded(child: _StatCard(title: "Today's Sales", value: formatCurrency(s.totalSales), icon: Icons.trending_up, color: AppColors.accent)),
        const SizedBox(width: 16),
        Expanded(child: _StatCard(title: 'Invoices', value: '${s.invoiceCount}', icon: Icons.receipt_long, color: AppColors.primary)),
        const SizedBox(width: 16),
        Expanded(child: _StatCard(title: 'Avg Invoice', value: formatCurrency(s.avgValue), icon: Icons.analytics, color: AppColors.warning)),
      ]),
      loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Text('Error: $e', style: const TextStyle(color: AppColors.error)),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w700)),
        ])),
      ])),
    );
  }
}

class _PaymentBreakdown extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breakdownAsync = ref.watch(paymentBreakdownProvider);
    return breakdownAsync.when(
      data: (data) {
        final total = data.values.fold<double>(0, (a, b) => a + b);
        return Row(children: [
          Expanded(child: _PaymentCard(label: 'Cash', amount: data['cash'] ?? 0, total: total, color: AppColors.cash, icon: Icons.payments)),
          const SizedBox(width: 16),
          Expanded(child: _PaymentCard(label: 'UPI', amount: data['upi'] ?? 0, total: total, color: AppColors.upi, icon: Icons.phone_android)),
          const SizedBox(width: 16),
          Expanded(child: _PaymentCard(label: 'Card', amount: data['card'] ?? 0, total: total, color: AppColors.card, icon: Icons.credit_card)),
        ]);
      },
      loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Text('Error: $e', style: const TextStyle(color: AppColors.error)),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final String label;
  final double amount;
  final double total;
  final Color color;
  final IconData icon;
  const _PaymentCard({required this.label, required this.amount, required this.total, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (amount / total * 100) : 0.0;
    return Card(
      child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          Text(formatCurrency(amount), style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w700)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
          child: Text('${pct.toStringAsFixed(0)}%', style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ])),
    );
  }
}

class _DailySalesChart extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyAsync = ref.watch(dailySalesProvider);
    return Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Daily Sales (7 days)', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      const SizedBox(height: 16),
      Expanded(child: dailyAsync.when(
        data: (data) {
          if (data.every((d) => (d['total'] as double) == 0)) {
            return const Center(child: Text('No sales data yet', style: TextStyle(color: AppColors.textHint)));
          }
          final maxY = data.map((d) => d['total'] as double).reduce((a, b) => a > b ? a : b);
          return BarChart(BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY * 1.2,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final d = data[group.x.toInt()]['date'] as DateTime;
                  return BarTooltipItem('${DateFormat('MMM d').format(d)}\n${formatCurrency(rod.toY)}', const TextStyle(color: Colors.white, fontSize: 12));
                },
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                final d = data[value.toInt()]['date'] as DateTime;
                return Padding(padding: const EdgeInsets.only(top: 8), child: Text(DateFormat('E').format(d), style: const TextStyle(color: AppColors.textHint, fontSize: 11)));
              })),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(data.length, (i) {
              final val = data[i]['total'] as double;
              return BarChartGroupData(x: i, barRods: [
                BarChartRodData(toY: val, color: AppColors.accent, width: 18, borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6))),
              ]);
            }),
          ));
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      )),
    ])));
  }
}

class _MonthlySalesChart extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlyAsync = ref.watch(monthlySalesProvider);
    return Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Monthly Revenue (6 months)', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      const SizedBox(height: 16),
      Expanded(child: monthlyAsync.when(
        data: (data) {
          if (data.every((d) => (d['total'] as double) == 0)) {
            return const Center(child: Text('No revenue data yet', style: TextStyle(color: AppColors.textHint)));
          }
          final maxY = data.map((d) => d['total'] as double).reduce((a, b) => a > b ? a : b);
          return LineChart(LineChartData(
            maxY: maxY * 1.2,
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (spots) => spots.map((s) {
                  final d = data[s.x.toInt()]['date'] as DateTime;
                  return LineTooltipItem('${DateFormat('MMM yyyy').format(d)}\n${formatCurrency(s.y)}', const TextStyle(color: Colors.white, fontSize: 12));
                }).toList(),
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                if (value.toInt() >= data.length) return const SizedBox.shrink();
                final d = data[value.toInt()]['date'] as DateTime;
                return Padding(padding: const EdgeInsets.only(top: 8), child: Text(DateFormat('MMM').format(d), style: const TextStyle(color: AppColors.textHint, fontSize: 11)));
              })),
            ),
            gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: AppColors.border.withValues(alpha: 0.3), strokeWidth: 1)),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i]['total'] as double)),
                isCurved: true, curveSmoothness: 0.3,
                color: AppColors.primary, barWidth: 3,
                dotData: FlDotData(show: true, getDotPainter: (s, xv, lbd, idx) => FlDotCirclePainter(radius: 4, color: AppColors.primary, strokeWidth: 2, strokeColor: AppColors.surface)),
                belowBarData: BarAreaData(show: true, color: AppColors.primary.withValues(alpha: 0.1)),
              ),
            ],
          ));
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      )),
    ])));
  }
}
