/// Invoice model — a completed sale transaction.
///
/// Payment information is stored separately in the [Payment] table
/// (not duplicated here) to support future split payments.
///
/// Tax is always calculated AFTER discount:
///   subtotal → discount → taxable amount → tax → total
class Invoice {
  final String id;
  final String invoiceNumber; // INV-00001
  final double subtotal;
  final String discountType; // 'percent' or 'flat'
  final double discountValue; // the input value (e.g., 10 for 10%)
  final double discountAmount; // computed: actual ₹ deducted
  final double taxPercent;
  final double taxAmount; // computed
  final double total; // computed
  final String? customerName;
  final String? customerPhone;
  final DateTime date;
  final DateTime createdAt;

  const Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.subtotal,
    this.discountType = 'flat',
    this.discountValue = 0,
    this.discountAmount = 0,
    this.taxPercent = 0,
    this.taxAmount = 0,
    required this.total,
    this.customerName,
    this.customerPhone,
    required this.date,
    required this.createdAt,
  });

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'] as String,
      invoiceNumber: map['invoice_number'] as String,
      subtotal: (map['subtotal'] as num).toDouble(),
      discountType: map['discount_type'] as String? ?? 'flat',
      discountValue: (map['discount_value'] as num? ?? 0).toDouble(),
      discountAmount: (map['discount_amount'] as num? ?? 0).toDouble(),
      taxPercent: (map['tax_percent'] as num? ?? 0).toDouble(),
      taxAmount: (map['tax_amount'] as num? ?? 0).toDouble(),
      total: (map['total'] as num).toDouble(),
      customerName: map['customer_name'] as String?,
      customerPhone: map['customer_phone'] as String?,
      date: DateTime.parse(map['date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'subtotal': subtotal,
      'discount_type': discountType,
      'discount_value': discountValue,
      'discount_amount': discountAmount,
      'tax_percent': taxPercent,
      'tax_amount': taxAmount,
      'total': total,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  Invoice copyWith({
    String? id,
    String? invoiceNumber,
    double? subtotal,
    String? discountType,
    double? discountValue,
    double? discountAmount,
    double? taxPercent,
    double? taxAmount,
    double? total,
    String? customerName,
    String? customerPhone,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      subtotal: subtotal ?? this.subtotal,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      discountAmount: discountAmount ?? this.discountAmount,
      taxPercent: taxPercent ?? this.taxPercent,
      taxAmount: taxAmount ?? this.taxAmount,
      total: total ?? this.total,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'Invoice(id: $id, number: $invoiceNumber, total: $total)';
}
