import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../services/pdf_service.dart';
import 'invoice_providers.dart';

class InvoiceDetailScreen extends ConsumerWidget {
  final String invoiceId;
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(invoiceDetailProvider(invoiceId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Details'),
        actions: [
          detailAsync.whenOrNull(
            data: (detail) {
              if (detail == null) return const SizedBox.shrink();
              return Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  icon: const Icon(Icons.save_alt),
                  tooltip: 'Export as PDF',
                  onPressed: () async {
                    try {
                      final result = await PdfService.savePdf(
                        invoice: detail.invoice,
                        items: detail.items,
                        payments: detail.payments,
                      );
                      if (result != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('✅ PDF exported: $result'), backgroundColor: AppColors.success),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Export failed: $e'), backgroundColor: AppColors.error),
                        );
                      }
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.print),
                  tooltip: 'Print Invoice',
                  onPressed: () => PdfService.printInvoice(
                    invoice: detail.invoice,
                    items: detail.items,
                    payments: detail.payments,
                  ),
                ),
              ]);
            },
          ) ?? const SizedBox.shrink(),
        ],
      ),
      body: detailAsync.when(
        data: (detail) {
          if (detail == null) {
            return const Center(child: Text('Invoice not found'));
          }
          final inv = detail.invoice;
          final items = detail.items;
          final payments = detail.payments;

          final isMobile = MediaQuery.of(context).size.width < 600;
          final outerPad = isMobile ? 12.0 : 32.0;
          final innerPad = isMobile ? 16.0 : 32.0;

          return SingleChildScrollView(
            padding: EdgeInsets.all(outerPad),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(innerPad),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Invoice header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(inv.invoiceNumber, style: TextStyle(fontSize: isMobile ? 18 : 24, fontWeight: FontWeight.w700, color: AppColors.primary)),
                                  const SizedBox(height: 4),
                                  Text(formatDateTime(inv.date), style: const TextStyle(color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 16, vertical: isMobile ? 6 : 8),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(formatCurrency(inv.total), style: TextStyle(fontSize: isMobile ? 16 : 20, fontWeight: FontWeight.w700, color: AppColors.accent)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (inv.customerName != null || inv.customerPhone != null) ...[
                          Text('Customer: ${inv.customerName ?? ''} ${inv.customerPhone != null ? '(${inv.customerPhone})' : ''}', style: const TextStyle(color: AppColors.textSecondary)),
                          const SizedBox(height: 8),
                        ],
                        const Divider(height: 32),

                        // Items table
                        const Text('Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Table(
                          columnWidths: isMobile
                              ? const {
                                  0: FlexColumnWidth(2.5),
                                  1: FixedColumnWidth(40),
                                  2: FlexColumnWidth(1.5),
                                  3: FlexColumnWidth(1.5),
                                }
                              : const {
                                  0: FlexColumnWidth(3),
                                  1: FixedColumnWidth(60),
                                  2: FlexColumnWidth(2),
                                  3: FlexColumnWidth(2),
                                },
                          border: TableBorder(horizontalInside: BorderSide(color: AppColors.border.withValues(alpha: 0.5))),
                          children: [
                            TableRow(
                              decoration: BoxDecoration(color: AppColors.surfaceLight),
                              children: ['Product', 'Qty', 'Price', 'Total'].map((h) => Padding(
                                padding: EdgeInsets.all(isMobile ? 6 : 10),
                                child: Text(h, style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary, fontSize: isMobile ? 11 : 13)),
                              )).toList(),
                            ),
                            ...items.map((item) => TableRow(children: [
                              Padding(padding: EdgeInsets.all(isMobile ? 6 : 10), child: Text(item.productName, style: TextStyle(fontSize: isMobile ? 12 : 14))),
                              Padding(padding: EdgeInsets.all(isMobile ? 6 : 10), child: Text('${item.quantity}', style: TextStyle(fontSize: isMobile ? 12 : 14))),
                              Padding(padding: EdgeInsets.all(isMobile ? 6 : 10), child: Text(formatCurrency(item.unitPrice), style: TextStyle(fontSize: isMobile ? 12 : 14))),
                              Padding(padding: EdgeInsets.all(isMobile ? 6 : 10), child: Text(formatCurrency(item.lineTotal), style: TextStyle(fontWeight: FontWeight.w500, fontSize: isMobile ? 12 : 14))),
                            ])),
                          ],
                        ),
                        const Divider(height: 32),

                        // Summary
                        _summaryRow('Subtotal', formatCurrency(inv.subtotal)),
                        if (inv.discountAmount > 0)
                          _summaryRow('Discount (${inv.discountType == 'percent' ? '${inv.discountValue}%' : 'Flat'})', '- ${formatCurrency(inv.discountAmount)}', color: AppColors.warning),
                        if (inv.taxAmount > 0)
                          _summaryRow('Tax (${inv.taxPercent}%)', '+ ${formatCurrency(inv.taxAmount)}'),
                        const Divider(),
                        _summaryRow('Total', formatCurrency(inv.total), isBold: true, color: AppColors.accent, fontSize: 18),
                        const SizedBox(height: 16),

                        // Payment — use Wrap so chips don't overflow on mobile
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text('Paid via: ', style: TextStyle(color: AppColors.textSecondary)),
                            ...payments.map((p) {
                              Color c = p.method == 'cash' ? AppColors.cash : p.method == 'upi' ? AppColors.upi : AppColors.card;
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: c)),
                                child: Text('${p.method.toUpperCase()} — ${formatCurrency(p.amount)}', style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: isMobile ? 12 : 14)),
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false, Color? color, double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: AppColors.textSecondary, fontWeight: isBold ? FontWeight.w700 : FontWeight.w400, fontSize: fontSize)),
        Text(value, style: TextStyle(color: color ?? AppColors.textPrimary, fontWeight: isBold ? FontWeight.w700 : FontWeight.w500, fontSize: fontSize)),
      ]),
    );
  }
}
