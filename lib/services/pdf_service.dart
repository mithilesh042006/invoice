import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import '../core/utils/helpers.dart';
import '../data/models/invoice.dart';
import '../data/models/invoice_item.dart';
import '../data/models/payment.dart';

class PdfService {
  PdfService._();

  /// Print the invoice via the system print dialog.
  static Future<void> printInvoice({
    required Invoice invoice,
    required List<InvoiceItem> items,
    required List<Payment> payments,
    String shopName = 'My Shop',
    String shopAddress = '',
    String shopPhone = '',
    String? gstin,
  }) async {
    final pdf = _buildPdf(
      invoice: invoice, items: items, payments: payments,
      shopName: shopName, shopAddress: shopAddress, shopPhone: shopPhone, gstin: gstin,
    );
    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  /// Save the invoice as a PDF file to a user-chosen location.
  /// Returns the file path if saved, or null if cancelled.
  static Future<String?> savePdf({
    required Invoice invoice,
    required List<InvoiceItem> items,
    required List<Payment> payments,
    String shopName = 'My Shop',
    String shopAddress = '',
    String shopPhone = '',
    String? gstin,
  }) async {
    final pdf = _buildPdf(
      invoice: invoice, items: items, payments: payments,
      shopName: shopName, shopAddress: shopAddress, shopPhone: shopPhone, gstin: gstin,
    );

    final bytes = await pdf.save();
    final defaultName = '${invoice.invoiceNumber}.pdf';

    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Invoice PDF',
      fileName: defaultName,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null) return null;

    final file = File(result);
    await file.writeAsBytes(bytes);
    return result;
  }

  /// Build the PDF document (shared between print and save).
  static pw.Document _buildPdf({
    required Invoice invoice,
    required List<InvoiceItem> items,
    required List<Payment> payments,
    String shopName = 'My Shop',
    String shopAddress = '',
    String shopPhone = '',
    String? gstin,
  }) {
    final pdf = pw.Document();

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Shop header
            pw.Center(child: pw.Text(shopName, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold))),
            if (shopAddress.isNotEmpty) pw.Center(child: pw.Text(shopAddress, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700))),
            if (shopPhone.isNotEmpty) pw.Center(child: pw.Text('Phone: $shopPhone', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700))),
            if (gstin != null && gstin.isNotEmpty) pw.Center(child: pw.Text('GSTIN: $gstin', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700))),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 2),
            pw.SizedBox(height: 10),

            // Invoice info
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Invoice: ${invoice.invoiceNumber}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.Text('Date: ${formatDate(invoice.date)}', style: const pw.TextStyle(fontSize: 10)),
              ]),
              if (invoice.customerName != null) pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Text('Customer: ${invoice.customerName}', style: const pw.TextStyle(fontSize: 10)),
                if (invoice.customerPhone != null) pw.Text('Phone: ${invoice.customerPhone}', style: const pw.TextStyle(fontSize: 10)),
              ]),
            ]),
            pw.SizedBox(height: 20),

            // Items table
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              cellPadding: const pw.EdgeInsets.all(6),
              cellAlignments: {0: pw.Alignment.centerLeft, 1: pw.Alignment.center, 2: pw.Alignment.centerRight, 3: pw.Alignment.centerRight},
              headers: ['Product', 'Qty', 'Unit Price', 'Total'],
              data: items.map((item) => [
                item.productName,
                '${item.quantity}',
                formatCurrency(item.unitPrice),
                formatCurrency(item.lineTotal),
              ]).toList(),
            ),
            pw.SizedBox(height: 10),
            pw.Divider(),

            // Totals
            pw.Align(alignment: pw.Alignment.centerRight, child: pw.Container(
              width: 200,
              child: pw.Column(children: [
                _pdfRow('Subtotal', formatCurrency(invoice.subtotal)),
                if (invoice.discountAmount > 0) _pdfRow('Discount', '- ${formatCurrency(invoice.discountAmount)}'),
                if (invoice.taxAmount > 0) _pdfRow('Tax (${invoice.taxPercent}%)', '+ ${formatCurrency(invoice.taxAmount)}'),
                pw.Divider(),
                _pdfRow('TOTAL', formatCurrency(invoice.total), bold: true),
              ]),
            )),
            pw.SizedBox(height: 16),

            // Payment
            pw.Text('Payment: ${payments.map((p) => '${p.method.toUpperCase()} — ${formatCurrency(p.amount)}').join(', ')}', style: const pw.TextStyle(fontSize: 10)),
            pw.Spacer(),
            pw.Center(child: pw.Text('Thank you for your purchase!', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600))),
          ],
        );
      },
    ));

    return pdf;
  }

  static pw.Widget _pdfRow(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      ]),
    );
  }
}
