import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../data/models/invoice.dart';
import 'invoice_providers.dart';
import 'invoice_detail_screen.dart';

/// Shows a table of all past invoices, newest first.
class InvoiceListScreen extends ConsumerWidget {
  const InvoiceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(invoiceListProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined,
                  color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              Text('Invoices',
                  style: Theme.of(context).textTheme.headlineMedium),
              const Spacer(),
              IconButton(
                onPressed: () =>
                    ref.read(invoiceListProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Table ──
          Expanded(
            child: invoicesAsync.when(
              data: (invoices) => invoices.isEmpty
                  ? _buildEmptyState(context)
                  : _buildInvoiceTable(context, ref, invoices),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Error: $e',
                    style: const TextStyle(color: AppColors.error)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 80, color: AppColors.textHint.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'No invoices yet',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: AppColors.textHint),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first invoice from the sidebar',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceTable(
      BuildContext context, WidgetRef ref, List<Invoice> invoices) {
    return Card(
      child: SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: DataTable(
            headingRowHeight: 52,
            dataRowMinHeight: 56,
            dataRowMaxHeight: 56,
            columnSpacing: 24,
            columns: const [
              DataColumn(label: Text('INVOICE #')),
              DataColumn(label: Text('DATE')),
              DataColumn(label: Text('CUSTOMER')),
              DataColumn(label: Text('TOTAL'), numeric: true),
              DataColumn(label: Text('ACTIONS')),
            ],
            rows: invoices.map((invoice) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      invoice.invoiceNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  DataCell(Text(formatDate(invoice.date))),
                  DataCell(Text(invoice.customerName ?? '—')),
                  DataCell(
                    Text(
                      formatCurrency(invoice.total),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined, size: 20),
                      color: AppColors.info,
                      tooltip: 'View Details',
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) =>
                              InvoiceDetailScreen(invoiceId: invoice.id),
                        ));
                      },
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
