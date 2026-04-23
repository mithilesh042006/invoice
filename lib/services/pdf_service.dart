import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import '../core/utils/helpers.dart';
import '../data/models/invoice.dart';
import '../data/models/invoice_item.dart';
import '../data/models/payment.dart';
import '../data/repositories/invoice_repository.dart';

class PdfService {
  PdfService._();

  /// Load shop profile from DB.
  static Future<Map<String, dynamic>> _loadShopProfile() async {
    final repo = InvoiceRepository();
    final profile = await repo.getShopProfile();
    return profile ?? {
      'shop_name': 'My Shop',
      'address': '',
      'phone': '',
      'email': '',
      'gstin': '',
    };
  }

  /// Print the invoice via the system print dialog.
  static Future<void> printInvoice({
    required Invoice invoice,
    required List<InvoiceItem> items,
    required List<Payment> payments,
  }) async {
    final profile = await _loadShopProfile();
    final pdf = await _buildPdf(
      invoice: invoice, items: items, payments: payments, profile: profile,
    );
    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  /// Save the invoice as a PDF file to a user-chosen location.
  static Future<String?> savePdf({
    required Invoice invoice,
    required List<InvoiceItem> items,
    required List<Payment> payments,
  }) async {
    final profile = await _loadShopProfile();
    final pdf = await _buildPdf(
      invoice: invoice, items: items, payments: payments, profile: profile,
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

  /// Build the PDF document matching Invoice_design.md specification.
  static Future<pw.Document> _buildPdf({
    required Invoice invoice,
    required List<InvoiceItem> items,
    required List<Payment> payments,
    required Map<String, dynamic> profile,
  }) async {
    final pdf = pw.Document();

    // Load a font that properly supports ₹ symbol
    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    final baseStyle = pw.TextStyle(font: font, fontSize: 10);
    final boldStyle = pw.TextStyle(font: fontBold, fontSize: 10);
    final headerStyle = pw.TextStyle(font: fontBold, fontSize: 22);
    final subHeaderStyle = pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700);
    final grandTotalStyle = pw.TextStyle(font: fontBold, fontSize: 13);

    // Extract profile fields
    final shopName = (profile['shop_name'] ?? 'My Shop').toString();
    final address = (profile['address'] ?? '').toString();
    final phone = (profile['phone'] ?? '').toString();
    final email = (profile['email'] ?? '').toString();
    final gstin = (profile['gstin'] ?? '').toString();

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ═══════════════════════════════════════════
            // Section 1: Shop / Business Details (Header)
            // ═══════════════════════════════════════════
            pw.Center(child: pw.Text(shopName, style: headerStyle)),
            pw.SizedBox(height: 4),
            if (address.isNotEmpty)
              pw.Center(child: pw.Text(address, style: subHeaderStyle)),
            // Phone | Email | GSTIN on one line
            _buildContactLine(phone: phone, email: email, gstin: gstin, style: subHeaderStyle),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 2, color: PdfColors.grey800),
            pw.SizedBox(height: 12),

            // ═══════════════════════════════════════════
            // Section 2: Invoice Metadata + Customer
            // ═══════════════════════════════════════════
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('Invoice No: ${invoice.invoiceNumber}', style: pw.TextStyle(font: fontBold, fontSize: 13)),
                  pw.SizedBox(height: 2),
                  pw.Text('Date: ${formatDateTime(invoice.date)}', style: baseStyle),
                ]),
                if (invoice.customerName != null || invoice.customerPhone != null)
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                    if (invoice.customerName != null)
                      pw.Text('Customer: ${invoice.customerName}', style: boldStyle),
                    if (invoice.customerPhone != null)
                      pw.Text('Phone: ${invoice.customerPhone}', style: baseStyle),
                  ]),
              ],
            ),
            pw.SizedBox(height: 16),

            // ═══════════════════════════════════════════
            // Section 4: Item Table (with S.No)
            // ═══════════════════════════════════════════
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.white),
              cellStyle: pw.TextStyle(font: font, fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF333333)),
              headerPadding: const pw.EdgeInsets.all(6),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              cellAlignments: {
                0: pw.Alignment.center,       // S.No
                1: pw.Alignment.centerLeft,   // Product
                2: pw.Alignment.center,       // Qty
                3: pw.Alignment.centerRight,  // Price
                4: pw.Alignment.centerRight,  // Total
              },
              columnWidths: {
                0: const pw.FixedColumnWidth(40),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FixedColumnWidth(50),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(1.5),
              },
              headers: ['S.No', 'Product', 'Qty', 'Price', 'Total'],
              data: List.generate(items.length, (i) {
                final item = items[i];
                return [
                  '${i + 1}',
                  item.productName,
                  '${item.quantity}',
                  _fmtCurrency(item.unitPrice),
                  _fmtCurrency(item.lineTotal),
                ];
              }),
              oddRowDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF5F5F5)),
            ),
            pw.SizedBox(height: 12),

            // ═══════════════════════════════════════════
            // Section 5: Calculation Breakdown
            // ═══════════════════════════════════════════
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                width: 220,
                child: pw.Column(children: [
                  _pdfRow('Subtotal', _fmtCurrency(invoice.subtotal), style: baseStyle, boldStyle: boldStyle),
                  if (invoice.discountAmount > 0)
                    _pdfRow(
                      'Discount${invoice.discountType == 'percent' ? ' (${invoice.discountValue}%)' : ''}',
                      '- ${_fmtCurrency(invoice.discountAmount)}',
                      style: baseStyle, boldStyle: boldStyle,
                    ),
                  if (invoice.taxAmount > 0)
                    _pdfRow('Tax (${invoice.taxPercent}%)', '+ ${_fmtCurrency(invoice.taxAmount)}', style: baseStyle, boldStyle: boldStyle),
                  pw.Divider(thickness: 1.5),
                  pw.SizedBox(height: 2),
                  _pdfRow('GRAND TOTAL', _fmtCurrency(invoice.total), style: baseStyle, boldStyle: grandTotalStyle, bold: true),
                ]),
              ),
            ),
            pw.SizedBox(height: 20),

            // ═══════════════════════════════════════════
            // Section 6: Payment Details
            // ═══════════════════════════════════════════
            pw.Divider(color: PdfColors.grey400),
            pw.SizedBox(height: 8),
            ...payments.map((p) {
              final balance = p.amount - invoice.total;
              return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Row(children: [
                  pw.Text('Payment Mode: ', style: baseStyle),
                  pw.Text(p.method.toUpperCase(), style: boldStyle),
                ]),
                pw.Row(children: [
                  pw.Text('Amount Paid: ', style: baseStyle),
                  pw.Text(_fmtCurrency(p.amount), style: boldStyle),
                ]),
                pw.Row(children: [
                  pw.Text('Balance: ', style: baseStyle),
                  pw.Text(_fmtCurrency(balance >= 0 ? balance : 0), style: boldStyle),
                ]),
              ]);
            }),

            // ═══════════════════════════════════════════
            // Section 7: Footer
            // ═══════════════════════════════════════════
            pw.Spacer(),
            pw.Divider(color: PdfColors.grey400),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                'Thank you for your business!',
                style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.grey600),
              ),
            ),
          ],
        );
      },
    ));

    return pdf;
  }

  /// Format currency with ₹ symbol (using the Noto Sans font that supports it).
  static String _fmtCurrency(double amount) => formatCurrency(amount);

  /// Build the contact info line: Phone | Email | GSTIN
  static pw.Widget _buildContactLine({
    required String phone,
    required String email,
    required String gstin,
    required pw.TextStyle style,
  }) {
    final parts = <String>[];
    if (phone.isNotEmpty) parts.add('Phone: $phone');
    if (email.isNotEmpty) parts.add('Email: $email');
    if (gstin.isNotEmpty) parts.add('GSTIN: $gstin');

    if (parts.isEmpty) return pw.SizedBox.shrink();
    return pw.Center(child: pw.Text(parts.join('  |  '), style: style));
  }

  /// Summary row: label — value
  static pw.Widget _pdfRow(String label, String value, {
    required pw.TextStyle style,
    required pw.TextStyle boldStyle,
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text(label, style: bold ? boldStyle : style),
        pw.Text(value, style: bold ? boldStyle : style),
      ]),
    );
  }
}
