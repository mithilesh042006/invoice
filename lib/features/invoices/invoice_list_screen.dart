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

/// Shows a list of all past invoices with date filter and total.
class InvoiceListScreen extends ConsumerStatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  ConsumerState<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends ConsumerState<InvoiceListScreen> {
  // Date filter: null means "all"
  DateTime? _startDate;
  DateTime? _endDate;
  String _filterLabel = 'All';

  void _setFilter(String label, DateTime? start, DateTime? end) {
    setState(() {
      _filterLabel = label;
      _startDate = start;
      _endDate = end;
    });
  }

  List<Invoice> _applyDateFilter(List<Invoice> invoices) {
    if (_startDate == null && _endDate == null) return invoices;
    return invoices.where((inv) {
      if (_startDate != null && inv.date.isBefore(_startDate!)) return false;
      if (_endDate != null && inv.date.isAfter(_endDate!.add(const Duration(days: 1)))) return false;
      return true;
    }).toList();
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (range != null) {
      _setFilter(
        '${formatDate(range.start)} – ${formatDate(range.end)}',
        range.start,
        range.end,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  color: AppColors.primary, size: mobile ? 22 : 28),
              const SizedBox(width: 8),
              Text('Invoices',
                  style: mobile ? Theme.of(context).textTheme.titleLarge : Theme.of(context).textTheme.headlineMedium),
              const Spacer(),
              IconButton(
                onPressed: () =>
                    ref.read(invoiceListProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Date Filter Bar ──
          _dateFilterBar(context, mobile),
          const SizedBox(height: 8),

          // ── List ──
          Expanded(
            child: invoicesAsync.when(
              data: (invoices) {
                final filtered = _applyDateFilter(invoices);
                if (filtered.isEmpty) return _buildEmptyState(context);

                return Column(children: [
                  // Total summary strip
                  _totalStrip(filtered, mobile),
                  const SizedBox(height: 8),
                  // Invoice list
                  Expanded(
                    child: mobile
                        ? _buildInvoiceCards(context, ref, filtered)
                        : _buildInvoiceTable(context, ref, filtered),
                  ),
                ]);
              },
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

  // ── Date Filter Bar ──
  Widget _dateFilterBar(BuildContext context, bool mobile) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    final filters = <Map<String, dynamic>>[
      {'label': 'All', 'start': null, 'end': null},
      {'label': 'Today', 'start': todayStart, 'end': todayStart},
      {'label': 'This Week', 'start': weekStart, 'end': now},
      {'label': 'This Month', 'start': monthStart, 'end': now},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        ...filters.map((f) {
          final selected = _filterLabel == f['label'];
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => _setFilter(f['label'] as String, f['start'] as DateTime?, f['end'] as DateTime?),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: mobile ? 12 : 14, vertical: mobile ? 7 : 8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary.withValues(alpha: 0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.5 : 1),
                ),
                child: Text(
                  f['label'] as String,
                  style: TextStyle(
                    color: selected ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    fontSize: mobile ? 14 : 13,
                  ),
                ),
              ),
            ),
          );
        }),
        // Custom range
        GestureDetector(
          onTap: () => _pickCustomRange(context),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: mobile ? 12 : 14, vertical: mobile ? 7 : 8),
            decoration: BoxDecoration(
              color: !['All', 'Today', 'This Week', 'This Month'].contains(_filterLabel)
                  ? AppColors.accent.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: !['All', 'Today', 'This Week', 'This Month'].contains(_filterLabel)
                    ? AppColors.accent
                    : AppColors.border,
                width: 1,
              ),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.date_range, size: mobile ? 16 : 16, color: AppColors.accent),
              const SizedBox(width: 4),
              Text(
                !['All', 'Today', 'This Week', 'This Month'].contains(_filterLabel) ? _filterLabel : 'Custom',
                style: TextStyle(color: AppColors.accent, fontSize: mobile ? 14 : 13, fontWeight: FontWeight.w500),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  // ── Total Summary Strip ──
  Widget _totalStrip(List<Invoice> invoices, bool mobile) {
    final total = invoices.fold<double>(0, (sum, inv) => sum + inv.total);
    final count = invoices.length;

    return Container(
      padding: EdgeInsets.symmetric(vertical: mobile ? 10 : 10, horizontal: mobile ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Icon(Icons.summarize_outlined, size: mobile ? 18 : 18, color: AppColors.accent),
        const SizedBox(width: 8),
        Text('$count invoice${count == 1 ? '' : 's'}',
            style: TextStyle(color: AppColors.textSecondary, fontSize: mobile ? 14 : 13)),
        const Spacer(),
        Text('Total: ', style: TextStyle(color: AppColors.textSecondary, fontSize: mobile ? 14 : 13)),
        Text(formatCurrency(total),
            style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800, fontSize: mobile ? 18 : 18)),
      ]),
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
            'No invoices found',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: AppColors.textHint),
          ),
          const SizedBox(height: 8),
          Text(
            _filterLabel == 'All'
                ? 'Create your first invoice from the sidebar'
                : 'No invoices match the selected date range',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  // ── Mobile: Compact Rows ──
  Widget _buildInvoiceCards(
      BuildContext context, WidgetRef ref, List<Invoice> invoices) {
    return ListView.separated(
      itemCount: invoices.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border.withValues(alpha: 0.5)),
      itemBuilder: (_, i) {
        final invoice = invoices[i];
        return InkWell(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => InvoiceDetailScreen(invoiceId: invoice.id),
          )),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line 1: Invoice # + Total
                Row(children: [
                  Text(invoice.invoiceNumber, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 16)),
                  const Spacer(),
                  Text(formatCurrency(invoice.total), style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 17)),
                ]),
                const SizedBox(height: 4),
                // Line 2: Date + Customer + Actions
                Row(children: [
                  Text(formatDate(invoice.date), style: const TextStyle(color: AppColors.textHint, fontSize: 14)),
                  if (invoice.customerName != null && invoice.customerName!.isNotEmpty) ...[
                    const Text(' · ', style: TextStyle(color: AppColors.textHint, fontSize: 14)),
                    Expanded(child: Text(invoice.customerName!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14), overflow: TextOverflow.ellipsis)),
                  ] else
                    const Spacer(),
                  SizedBox(
                    width: 32, height: 32,
                    child: IconButton(
                      icon: const Icon(Icons.save_alt, size: 18), color: AppColors.accent,
                      padding: EdgeInsets.zero,
                      onPressed: () => _exportPdf(context, invoice),
                    ),
                  ),
                  SizedBox(
                    width: 32, height: 32,
                    child: IconButton(
                      icon: const Icon(Icons.print, size: 18), color: AppColors.textSecondary,
                      padding: EdgeInsets.zero,
                      onPressed: () => _printInvoice(context, invoice),
                    ),
                  ),
                ]),
              ],
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

    try {
      final result = await PdfService.savePdf(
        invoice: invoice,
        items: items,
        payments: payments,
      );

      if (result != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ PDF exported: $result'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: AppColors.error),
        );
      }
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
