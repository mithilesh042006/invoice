import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// Format a number as Indian Rupees: ₹1,234.56
String formatCurrency(double amount) {
  final formatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: AppConstants.currencySymbol,
    decimalDigits: 2,
  );
  return formatter.format(amount);
}

/// Format a DateTime as DD/MM/YYYY.
String formatDate(DateTime date) {
  return DateFormat('dd/MM/yyyy').format(date);
}

/// Format a DateTime as DD/MM/YYYY hh:mm a.
String formatDateTime(DateTime date) {
  return DateFormat('dd/MM/yyyy hh:mm a').format(date);
}

/// Generate an invoice number string from a sequential integer.
/// e.g., 1 → "INV-00001", 42 → "INV-00042"
String generateInvoiceNumber(int sequentialNumber) {
  final padded = sequentialNumber
      .toString()
      .padLeft(AppConstants.invoiceNumberPadding, '0');
  return '${AppConstants.invoicePrefix}-$padded';
}

// ── Form Validators ──

/// Returns an error message if the value is null or empty.
String? validateRequired(String? value, [String fieldName = 'This field']) {
  if (value == null || value.trim().isEmpty) {
    return '$fieldName is required';
  }
  return null;
}

/// Returns an error message if the value is not a positive number.
String? validatePositiveNumber(String? value, [String fieldName = 'Value']) {
  if (value == null || value.trim().isEmpty) {
    return '$fieldName is required';
  }
  final number = double.tryParse(value);
  if (number == null || number <= 0) {
    return '$fieldName must be a positive number';
  }
  return null;
}

/// Returns an error message if the value is not a non-negative number.
String? validateNonNegativeNumber(String? value,
    [String fieldName = 'Value']) {
  if (value == null || value.trim().isEmpty) {
    return null; // optional field
  }
  final number = double.tryParse(value);
  if (number == null || number < 0) {
    return '$fieldName must be a non-negative number';
  }
  return null;
}
