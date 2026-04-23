import 'package:uuid/uuid.dart';
import '../../core/utils/helpers.dart';
import '../database/invoice_dao.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../models/payment.dart';

/// Repository layer for Invoice operations.
class InvoiceRepository {
  final InvoiceDao _dao = InvoiceDao();
  final Uuid _uuid = const Uuid();

  /// Create a complete invoice with items and payment.
  ///
  /// Handles: UUID generation, invoice number generation, and
  /// atomic database insertion.
  Future<Invoice> createInvoice({
    required List<InvoiceItem> cartItems,
    required double subtotal,
    required String discountType,
    required double discountValue,
    required double discountAmount,
    required double taxPercent,
    required double taxAmount,
    required double total,
    required String paymentMethod,
    String? customerName,
    String? customerPhone,
  }) async {
    final now = DateTime.now();
    final invoiceId = _uuid.v4();

    // Generate sequential invoice number
    final seq = await _dao.getNextInvoiceSequence();
    final invoiceNumber = generateInvoiceNumber(seq);

    // Build invoice model
    final invoice = Invoice(
      id: invoiceId,
      invoiceNumber: invoiceNumber,
      subtotal: subtotal,
      discountType: discountType,
      discountValue: discountValue,
      discountAmount: discountAmount,
      taxPercent: taxPercent,
      taxAmount: taxAmount,
      total: total,
      customerName:
          customerName?.trim().isEmpty == true ? null : customerName?.trim(),
      customerPhone:
          customerPhone?.trim().isEmpty == true ? null : customerPhone?.trim(),
      date: now,
      createdAt: now,
    );

    // Build invoice items with proper IDs
    final items = cartItems.map((item) {
      return InvoiceItem(
        id: _uuid.v4(),
        invoiceId: invoiceId,
        productId: item.productId,
        productName: item.productName,
        unitPrice: item.unitPrice,
        quantity: item.quantity,
        lineTotal: item.lineTotal,
        createdAt: now,
      );
    }).toList();

    // Build payment record
    final payment = Payment(
      id: _uuid.v4(),
      invoiceId: invoiceId,
      method: paymentMethod,
      amount: total,
      createdAt: now,
    );

    // Atomic insert
    await _dao.createInvoice(
      invoice: invoice,
      items: items,
      payment: payment,
    );

    return invoice;
  }

  Future<List<Invoice>> getAllInvoices() => _dao.getAllInvoices();

  Future<List<Invoice>> getInvoicesByDate(DateTime date) =>
      _dao.getInvoicesByDate(date);

  Future<Invoice?> getInvoiceById(String id) => _dao.getInvoiceById(id);

  Future<List<InvoiceItem>> getInvoiceItems(String invoiceId) =>
      _dao.getInvoiceItems(invoiceId);

  Future<List<Payment>> getInvoicePayments(String invoiceId) =>
      _dao.getInvoicePayments(invoiceId);

  Future<Map<String, dynamic>?> getShopProfile() => _dao.getShopProfile();

  Future<void> updateShopProfile(Map<String, dynamic> profile) =>
      _dao.updateShopProfile(profile);
}
