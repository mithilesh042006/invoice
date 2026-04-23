import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/invoice.dart';
import '../../services/pdf_service.dart';
import '../../data/repositories/invoice_repository.dart';
import 'invoice_providers.dart';
import 'invoice_detail_screen.dart';

/// Shows a table of all past invoices, newest first.
class InvoiceListScreen extends ConsumerWidget {
  const InvoiceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(invoiceListProvider);
    final mobile = Responsive.isMobile(context);
    final padding = Responsive.screenPadding(context);

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              Icon(Icons.receipt_long_outlined,
                  color: AppColors.primary, size: mobile ? 24 : 28),
              const SizedBox(width: 10),
              Text('Invoices',
                  style: mobile ? Theme.of(context).textTheme.titleLarge : Theme.of(context).textTheme.headlineMedium),
              const Spacer(),
              IconButton(
                onPressed: () =>
                    ref.read(invoiceListProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── List ──
          Expanded(
            child: invoicesAsync.when(
              data: (invoices) => invoices.isEmpty
                  ? _buildEmptyState(context)
                  : mobile
                      ? _buildInvoiceCards(context, ref, invoices)
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

  // ── Mobile: Card List ──
  Widget _buildInvoiceCards(
      BuildContext context, WidgetRef ref, List<Invoice> invoices) {
    return ListView.separated(
      itemCount: invoices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final invoice = invoices[i];
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => InvoiceDetailScreen(invoiceId: invoice.id),
            )),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(invoice.invoiceNumber, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                    const Spacer(),
                    Text(formatCurrency(invoice.total), style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 16)),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    const Icon(Icons.calendar_today, size: 14, color: AppColors.textHint),
                    const SizedBox(width: 6),
                    Text(formatDate(invoice.date), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(width: 16),
                    if (invoice.customerName != null && invoice.customerName!.isNotEmpty) ...[
                      const Icon(Icons.person, size: 14, color: AppColors.textHint),
                      const SizedBox(width: 6),
                      Expanded(child: Text(invoice.customerName!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13), overflow: TextOverflow.ellipsis)),
                    ],
                  ]),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    IconButton(
                      icon: const Icon(Icons.save_alt, size: 20), color: AppColors.accent, tooltip: 'Export PDF',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _exportPdf(context, invoice),
                    ),
                    IconButton(
                      icon: const Icon(Icons.print, size: 20), color: AppColors.textSecondary, tooltip: 'Print',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _printInvoice(context, invoice),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Desktop: DataTable ──
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
                    Row(mainAxisSize: MainAxisSize.min, children: [
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
                      IconButton(
                        icon: const Icon(Icons.save_alt, size: 20),
                        color: AppColors.accent,
                        tooltip: 'Export PDF',
                        onPressed: () => _exportPdf(context, invoice),
                      ),
                      IconButton(
                        icon: const Icon(Icons.print, size: 20),
                        color: AppColors.textSecondary,
                        tooltip: 'Print',
                        onPressed: () => _printInvoice(context, invoice),
                      ),
                    ]),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context, Invoice invoice) async {
    final repo = InvoiceRepository();
    final items = await repo.getInvoiceItems(invoice.id);
    final payments = await repo.getInvoicePayments(invoice.id);

    final path = await PdfService.savePdf(
      invoice: invoice,
      items: items,
      payments: payments,
    );

    if (path != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF saved to: $path'), backgroundColor: AppColors.success),
      );
    }
  }

  Future<void> _printInvoice(BuildContext context, Invoice invoice) async {
    final repo = InvoiceRepository();
    final items = await repo.getInvoiceItems(invoice.id);
    final payments = await repo.getInvoicePayments(invoice.id);

    await PdfService.printInvoice(
      invoice: invoice,
      items: items,
      payments: payments,
    );
  }
}
