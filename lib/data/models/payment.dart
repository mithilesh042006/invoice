/// Payment model — records how an invoice was paid.
///
/// This is the SINGLE source of truth for payment method (Fix #1).
/// The Invoice model does NOT store paymentMethod to avoid duplication
/// and to support future split payments.
class Payment {
  final String id;
  final String invoiceId;
  final String method; // 'cash', 'upi', 'card'
  final double amount;
  final DateTime createdAt;

  const Payment({
    required this.id,
    required this.invoiceId,
    required this.method,
    required this.amount,
    required this.createdAt,
  });

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as String,
      invoiceId: map['invoice_id'] as String,
      method: map['method'] as String,
      amount: (map['amount'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_id': invoiceId,
      'method': method,
      'amount': amount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() =>
      'Payment(invoiceId: $invoiceId, method: $method, amount: $amount)';
}
