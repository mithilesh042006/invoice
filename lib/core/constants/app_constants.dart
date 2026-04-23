/// Payment methods supported by the app.
enum PaymentMethod {
  cash('Cash'),
  upi('UPI'),
  card('Card');

  const PaymentMethod(this.label);
  final String label;
}

/// Discount types: percentage or flat amount.
enum DiscountType {
  percent('Percentage'),
  flat('Flat Amount');

  const DiscountType(this.label);
  final String label;
}

/// App-wide constants.
class AppConstants {
  AppConstants._();

  // ── App Info ──
  static const String appName = 'Smart Shop Manager';
  static const String appVersion = '1.0.0';

  // ── Currency ──
  static const String currencySymbol = '₹';
  static const String currencyCode = 'INR';

  // ── Invoice ──
  static const String invoicePrefix = 'INV';
  static const int invoiceNumberPadding = 5; // INV-00001

  // ── Tax ──
  static const double defaultTaxPercent = 0.0;

  // ── Database ──
  static const String databaseName = 'smart_shop_manager.db';
  static const int databaseVersion = 2;
}
