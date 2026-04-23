import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/invoice.dart';
import '../../data/models/invoice_item.dart';
import '../../data/models/payment.dart';
import '../../data/models/product.dart';
import '../../data/repositories/invoice_repository.dart';

// ── Repository Provider ──
final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  return InvoiceRepository();
});

// ── Invoice List Provider ──
final invoiceListProvider =
    AsyncNotifierProvider<InvoiceListNotifier, List<Invoice>>(
  InvoiceListNotifier.new,
);

class InvoiceListNotifier extends AsyncNotifier<List<Invoice>> {
  @override
  Future<List<Invoice>> build() async {
    final repo = ref.read(invoiceRepositoryProvider);
    return repo.getAllInvoices();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

// ═══════════════════════════════════════════════════════════════
// CART STATE — manages the in-progress invoice being created
// ═══════════════════════════════════════════════════════════════

/// A temporary cart item (before invoice is saved).
class CartItem {
  final String productId;
  final String productName;
  final double unitPrice;
  final String? unit;
  int quantity;

  CartItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    this.unit,
    this.quantity = 1,
  });

  double get lineTotal => unitPrice * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      productId: productId,
      productName: productName,
      unitPrice: unitPrice,
      unit: unit,
      quantity: quantity ?? this.quantity,
    );
  }
}

/// Cart state notifier — manages adding/removing/updating cart items.
class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addProduct(Product product) {
    // If product already in cart, increment quantity
    final existingIndex =
        state.indexWhere((item) => item.productId == product.id);
    if (existingIndex >= 0) {
      final updated = [...state];
      updated[existingIndex] = updated[existingIndex]
          .copyWith(quantity: updated[existingIndex].quantity + 1);
      state = updated;
    } else {
      state = [
        ...state,
        CartItem(
          productId: product.id,
          productName: product.name,
          unitPrice: product.price,
          unit: product.unit,
        ),
      ];
    }
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    state = state.map((item) {
      if (item.productId == productId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();
  }

  void removeItem(String productId) {
    state = state.where((item) => item.productId != productId).toList();
  }

  void clearCart() {
    state = [];
  }
}

final cartProvider =
    StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

// ═══════════════════════════════════════════════════════════════
// INVOICE CALCULATION — derived from cart + discount + tax
// ═══════════════════════════════════════════════════════════════

/// Discount state.
class DiscountState {
  final String type; // 'percent' or 'flat'
  final double value;

  const DiscountState({this.type = 'flat', this.value = 0});

  DiscountState copyWith({String? type, double? value}) {
    return DiscountState(
      type: type ?? this.type,
      value: value ?? this.value,
    );
  }
}

final discountProvider = StateProvider<DiscountState>(
  (ref) => const DiscountState(),
);

final taxPercentProvider = StateProvider<double>((ref) => 0.0);
final paymentMethodProvider = StateProvider<String>((ref) => 'cash');
final customerNameProvider = StateProvider<String>((ref) => '');
final customerPhoneProvider = StateProvider<String>((ref) => '');

/// Calculated invoice totals — locked calculation order (Fix #3):
///   Subtotal → Discount → Taxable Amount → Tax → Total
class InvoiceCalculation {
  final double subtotal;
  final double discountAmount;
  final double taxableAmount;
  final double taxAmount;
  final double total;

  const InvoiceCalculation({
    required this.subtotal,
    required this.discountAmount,
    required this.taxableAmount,
    required this.taxAmount,
    required this.total,
  });
}

final invoiceCalculationProvider = Provider<InvoiceCalculation>((ref) {
  final cart = ref.watch(cartProvider);
  final discount = ref.watch(discountProvider);
  final taxPercent = ref.watch(taxPercentProvider);

  // Step 1: Subtotal
  final subtotal = cart.fold<double>(0, (sum, item) => sum + item.lineTotal);

  // Step 2: Discount
  double discountAmount;
  if (discount.type == 'percent') {
    discountAmount = subtotal * (discount.value / 100);
  } else {
    discountAmount = discount.value;
  }
  // Clamp discount to subtotal (can't discount more than the subtotal)
  if (discountAmount > subtotal) discountAmount = subtotal;

  // Step 3: Taxable amount
  final taxableAmount = subtotal - discountAmount;

  // Step 4: Tax
  final taxAmount = taxableAmount * (taxPercent / 100);

  // Step 5: Total
  final total = taxableAmount + taxAmount;

  return InvoiceCalculation(
    subtotal: subtotal,
    discountAmount: discountAmount,
    taxableAmount: taxableAmount,
    taxAmount: taxAmount,
    total: total,
  );
});

// ═══════════════════════════════════════════════════════════════
// INVOICE DETAIL — loads a saved invoice with items and payments
// ═══════════════════════════════════════════════════════════════

class InvoiceDetail {
  final Invoice invoice;
  final List<InvoiceItem> items;
  final List<Payment> payments;

  const InvoiceDetail({
    required this.invoice,
    required this.items,
    required this.payments,
  });
}

final invoiceDetailProvider =
    FutureProvider.family<InvoiceDetail?, String>((ref, invoiceId) async {
  final repo = ref.read(invoiceRepositoryProvider);
  final invoice = await repo.getInvoiceById(invoiceId);
  if (invoice == null) return null;

  final items = await repo.getInvoiceItems(invoiceId);
  final payments = await repo.getInvoicePayments(invoiceId);

  return InvoiceDetail(
    invoice: invoice,
    items: items,
    payments: payments,
  );
});
