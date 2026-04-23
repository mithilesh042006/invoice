/// A single line item within an invoice.
///
/// Stores snapshot copies of [productName] and [unitPrice] at the time of sale
/// so old invoices remain accurate even if the product's price changes later.
class InvoiceItem {
  final String id;
  final String invoiceId;
  final String productId;
  final String productName; // snapshot
  final double unitPrice; // snapshot
  final int quantity;
  final double lineTotal; // quantity × unitPrice
  final DateTime createdAt;

  const InvoiceItem({
    required this.id,
    required this.invoiceId,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
    required this.createdAt,
  });

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id'] as String,
      invoiceId: map['invoice_id'] as String,
      productId: map['product_id'] as String,
      productName: map['product_name'] as String,
      unitPrice: (map['unit_price'] as num).toDouble(),
      quantity: map['quantity'] as int,
      lineTotal: (map['line_total'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'product_id': productId,
      'product_name': productName,
      'unit_price': unitPrice,
      'quantity': quantity,
      'line_total': lineTotal,
      'created_at': createdAt.toIso8601String(),
    };
  }

  InvoiceItem copyWith({
    String? id,
    String? invoiceId,
    String? productId,
    String? productName,
    double? unitPrice,
    int? quantity,
    double? lineTotal,
    DateTime? createdAt,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      lineTotal: lineTotal ?? this.lineTotal,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'InvoiceItem(product: $productName, qty: $quantity, total: $lineTotal)';
}
