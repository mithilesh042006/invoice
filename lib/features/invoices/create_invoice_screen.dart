import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/helpers.dart';
import '../../services/barcode_api_service.dart';
import '../products/product_providers.dart';
import '../products/api_product_confirm_dialog.dart';
import '../scanner/scanner_screen.dart';
import '../../data/models/invoice_item.dart';
import '../../data/models/product.dart';
import '../../data/repositories/product_repository.dart';
import '../products/product_form_dialog.dart';
import 'invoice_providers.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  final VoidCallback? onInvoiceCreated;
  const CreateInvoiceScreen({super.key, this.onInvoiceCreated});

  @override
  ConsumerState<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  final _customerNameCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();
  final _discountCtrl = TextEditingController(text: '0');
  final _taxCtrl = TextEditingController(text: '0');
  final _searchCtrl = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _discountCtrl.dispose();
    _taxCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mobile = Responsive.isMobile(context);
    final padding = Responsive.screenPadding(context);

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.add_shopping_cart, color: AppColors.primary, size: mobile ? 24 : 28),
            const SizedBox(width: 10),
            Text('New Invoice', style: mobile ? Theme.of(context).textTheme.titleLarge : Theme.of(context).textTheme.headlineMedium),
          ]),
          const SizedBox(height: 16),
          if (mobile)
            Expanded(
              child: SingleChildScrollView(
                child: Column(children: [
                  SizedBox(height: 300, child: _productPicker(mobile: true)),
                  const SizedBox(height: 12),
                  _cartPanel(mobile: true),
                ]),
              ),
            )
          else
            Expanded(child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _productPicker()),
                const SizedBox(width: 20),
                Expanded(flex: 4, child: _cartPanel()),
              ],
            )),
        ],
      ),
    );
  }

  Future<void> _scanAndAddProduct() async {
    // ── Step 1: Scan barcode ──
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );

    if (scannedCode == null || !mounted) return;

    debugPrint('📦 Scanned barcode: "$scannedCode"');

    // ── Step 2: Check local database (PRIMARY) ──
    final repo = ProductRepository();
    final localProduct = await repo.getProductByBarcode(scannedCode);

    if (localProduct != null) {
      // Found locally → add to cart (auto-increments if already in cart)
      ref.read(cartProvider.notifier).addProduct(localProduct);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Added "${localProduct.name}" to cart'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 1),
          ),
        );
      }
      return;
    }

    // ── Step 3: API fallback (SECONDARY) ──
    if (!mounted) return;

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(children: [
          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
          SizedBox(width: 12),
          Text('Looking up barcode online...'),
        ]),
        backgroundColor: AppColors.info,
        duration: Duration(seconds: 4),
      ),
    );

    final apiResult = await BarcodeApiService.lookupBarcode(scannedCode);

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (apiResult != null) {
      // API found the product → show confirmation dialog
      final savedProduct = await showDialog<Product>(
        context: context,
        barrierDismissible: false,
        builder: (_) => ApiProductConfirmDialog(apiResult: apiResult),
      );

      if (savedProduct != null && mounted) {
        // User confirmed → add to cart
        ref.read(cartProvider.notifier).addProduct(savedProduct);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Saved & added "${savedProduct.name}" to cart'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Not found anywhere → offer manual entry
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product not found for barcode "$scannedCode"'),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Add Manually',
              textColor: Colors.white,
              onPressed: () => _showAddProductWithBarcode(scannedCode),
            ),
          ),
        );
      }
    }
  }

  void _showAddProductWithBarcode(String barcode) {
    showDialog(
      context: context,
      builder: (ctx) => ProductFormDialog(initialBarcode: barcode),
    );
  }

  Widget _productPicker({bool mobile = false}) {
    final productsAsync = ref.watch(productListProvider);
    return Card(child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Products', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const Spacer(),
          Tooltip(
            message: 'Scan Barcode',
            child: ElevatedButton.icon(
              onPressed: _scanAndAddProduct,
              icon: const Icon(Icons.qr_code_scanner, size: 18),
              label: const Text('Scan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        TextField(
          controller: _searchCtrl,
          decoration: const InputDecoration(hintText: 'Search products or barcode...', prefixIcon: Icon(Icons.search, size: 20), isDense: true),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        // On mobile: use a fixed-height container instead of Expanded
        if (mobile)
          SizedBox(
            height: 180,
            child: _productList(productsAsync),
          )
        else
          Expanded(child: _productList(productsAsync)),
      ]),
    ));
  }

  Widget _productList(AsyncValue productsAsync) {
    return productsAsync.when(
      data: (products) {
        final q = _searchCtrl.text.toLowerCase();
        final filtered = q.isEmpty ? products : products.where((p) => p.name.toLowerCase().contains(q) || (p.barcode != null && p.barcode!.contains(q))).toList();
        if (filtered.isEmpty) return const Center(child: Text('No products found', style: TextStyle(color: AppColors.textHint)));
        return ListView.separated(
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final p = filtered[i];
            return ListTile(
              dense: true,
              title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
              subtitle: Text('${formatCurrency(p.price)}${p.unit != null ? ' / ${p.unit}' : ''}', style: const TextStyle(color: AppColors.accent, fontSize: 13)),
              trailing: IconButton(icon: const Icon(Icons.add_circle, color: AppColors.primary), onPressed: () => ref.read(cartProvider.notifier).addProduct(p)),
              onTap: () => ref.read(cartProvider.notifier).addProduct(p),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _cartPanel({bool mobile = false}) {
    final cart = ref.watch(cartProvider);
    final calc = ref.watch(invoiceCalculationProvider);
    return Card(child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          const Text('Cart', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
            child: Text('${cart.length} items', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          const Spacer(),
          if (cart.isNotEmpty) TextButton.icon(
            onPressed: () => ref.read(cartProvider.notifier).clearCart(),
            icon: const Icon(Icons.clear_all, size: 18), label: const Text('Clear'),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
          ),
        ]),
        const Divider(),
        // Cart items — fixed height on mobile, Expanded on desktop
        if (mobile)
          SizedBox(
            height: cart.isEmpty ? 60 : (cart.length * 56.0).clamp(60, 200),
            child: cart.isEmpty
              ? const Center(child: Text('Tap a product to add it here', style: TextStyle(color: AppColors.textHint)))
              : ListView.builder(itemCount: cart.length, itemBuilder: (_, i) => _cartItem(cart[i])),
          )
        else
          Expanded(child: cart.isEmpty
            ? const Center(child: Text('Tap a product to add it here', style: TextStyle(color: AppColors.textHint)))
            : ListView.builder(itemCount: cart.length, itemBuilder: (_, i) => _cartItem(cart[i]))),
        const Divider(),
        // Customer
        if (mobile)
          Column(children: [
            TextField(controller: _customerNameCtrl, decoration: const InputDecoration(labelText: 'Customer Name', isDense: true, prefixIcon: Icon(Icons.person_outline, size: 18)), onChanged: (v) => ref.read(customerNameProvider.notifier).state = v),
            const SizedBox(height: 10),
            TextField(controller: _customerPhoneCtrl, decoration: const InputDecoration(labelText: 'Phone', isDense: true, prefixIcon: Icon(Icons.phone_outlined, size: 18)), onChanged: (v) => ref.read(customerPhoneProvider.notifier).state = v),
          ])
        else
          Row(children: [
            Expanded(child: TextField(controller: _customerNameCtrl, decoration: const InputDecoration(labelText: 'Customer Name', isDense: true, prefixIcon: Icon(Icons.person_outline, size: 18)), onChanged: (v) => ref.read(customerNameProvider.notifier).state = v)),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: _customerPhoneCtrl, decoration: const InputDecoration(labelText: 'Phone', isDense: true, prefixIcon: Icon(Icons.phone_outlined, size: 18)), onChanged: (v) => ref.read(customerPhoneProvider.notifier).state = v)),
          ]),
        const SizedBox(height: 12),
        // Discount & Tax
        _discountTaxRow(),
        const SizedBox(height: 12),
        // Summary
        _summary(calc),
        const SizedBox(height: 12),
        // Payment mode
        _paymentSelector(),
        const SizedBox(height: 16),
        // Generate button
        SizedBox(width: double.infinity, height: 48, child: ElevatedButton.icon(
          onPressed: cart.isEmpty || _isCreating ? null : _generate,
          icon: _isCreating ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.receipt),
          label: Text(_isCreating ? 'Creating...' : 'Generate Invoice'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.black, textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        )),
      ]),
    ));
  }

  Widget _cartItem(CartItem item) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [
      Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        Text(formatCurrency(item.unitPrice), style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
      ])),
      _qtyBtn(Icons.remove, () => ref.read(cartProvider.notifier).updateQuantity(item.productId, item.quantity - 1)),
      Container(width: 40, alignment: Alignment.center, child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 15))),
      _qtyBtn(Icons.add, () => ref.read(cartProvider.notifier).updateQuantity(item.productId, item.quantity + 1)),
      const SizedBox(width: 16),
      SizedBox(width: 90, child: Text(formatCurrency(item.lineTotal), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.accent))),
      IconButton(icon: const Icon(Icons.close, size: 18), color: AppColors.error, onPressed: () => ref.read(cartProvider.notifier).removeItem(item.productId)),
    ]));
  }

  Widget _qtyBtn(IconData icon, VoidCallback onPressed) {
    return InkWell(onTap: onPressed, borderRadius: BorderRadius.circular(6), child: Container(
      width: 30, height: 30,
      decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.border)),
      child: Icon(icon, size: 16, color: AppColors.textPrimary),
    ));
  }

  Widget _discountTaxRow() {
    final discount = ref.watch(discountProvider);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ToggleButtons(
          isSelected: [discount.type == 'flat', discount.type == 'percent'],
          onPressed: (i) => ref.read(discountProvider.notifier).state = discount.copyWith(type: i == 0 ? 'flat' : 'percent'),
          borderRadius: BorderRadius.circular(8), selectedColor: Colors.white, fillColor: AppColors.primary, color: AppColors.textSecondary,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 36),
          children: const [Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('₹')), Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('%'))],
        ),
        SizedBox(width: 100, child: TextField(controller: _discountCtrl, decoration: InputDecoration(labelText: 'Discount', isDense: true, suffixText: discount.type == 'percent' ? '%' : '₹'), keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (v) => ref.read(discountProvider.notifier).state = discount.copyWith(value: double.tryParse(v) ?? 0))),
        SizedBox(width: 100, child: TextField(controller: _taxCtrl, decoration: const InputDecoration(labelText: 'Tax %', isDense: true, suffixText: '%'), keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (v) => ref.read(taxPercentProvider.notifier).state = double.tryParse(v) ?? 0)),
      ],
    );
  }

  Widget _summary(InvoiceCalculation calc) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
      child: Column(children: [
        _row('Subtotal', formatCurrency(calc.subtotal)),
        if (calc.discountAmount > 0) _row('Discount', '- ${formatCurrency(calc.discountAmount)}', color: AppColors.warning),
        if (calc.taxAmount > 0) _row('Tax', '+ ${formatCurrency(calc.taxAmount)}'),
        const Divider(),
        _row('Total', formatCurrency(calc.total), isBold: true, color: AppColors.accent, fontSize: 18),
      ]),
    );
  }

  Widget _row(String label, String value, {bool isBold = false, Color? color, double fontSize = 14}) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: AppColors.textSecondary, fontWeight: isBold ? FontWeight.w700 : FontWeight.w400, fontSize: fontSize)),
      Text(value, style: TextStyle(color: color ?? AppColors.textPrimary, fontWeight: isBold ? FontWeight.w700 : FontWeight.w500, fontSize: fontSize)),
    ]));
  }

  Widget _paymentSelector() {
    final selected = ref.watch(paymentMethodProvider);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
      const Text('Payment: ', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
      ...PaymentMethod.values.map((m) {
        final sel = selected == m.name;
        final c = m == PaymentMethod.cash ? AppColors.cash : m == PaymentMethod.upi ? AppColors.upi : AppColors.card;
        return Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(
          label: Text(m.label), selected: sel, onSelected: (_) => ref.read(paymentMethodProvider.notifier).state = m.name,
          selectedColor: c.withValues(alpha: 0.25), side: BorderSide(color: sel ? c : AppColors.border, width: sel ? 2 : 1),
          labelStyle: TextStyle(color: sel ? c : AppColors.textSecondary, fontWeight: sel ? FontWeight.w700 : FontWeight.w400), showCheckmark: false,
        ));
      }),
    ]);
  }

  Future<void> _generate() async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;
    setState(() => _isCreating = true);
    try {
      final calc = ref.read(invoiceCalculationProvider);
      final discount = ref.read(discountProvider);
      final repo = ref.read(invoiceRepositoryProvider);
      final items = cart.map((c) => InvoiceItem(id: '', invoiceId: '', productId: c.productId, productName: c.productName, unitPrice: c.unitPrice, quantity: c.quantity, lineTotal: c.lineTotal, createdAt: DateTime.now())).toList();
      await repo.createInvoice(cartItems: items, subtotal: calc.subtotal, discountType: discount.type, discountValue: discount.value, discountAmount: calc.discountAmount, taxPercent: ref.read(taxPercentProvider), taxAmount: calc.taxAmount, total: calc.total, paymentMethod: ref.read(paymentMethodProvider), customerName: _customerNameCtrl.text, customerPhone: _customerPhoneCtrl.text);
      ref.read(cartProvider.notifier).clearCart();
      ref.read(discountProvider.notifier).state = const DiscountState();
      ref.read(taxPercentProvider.notifier).state = 0;
      _customerNameCtrl.clear(); _customerPhoneCtrl.clear(); _discountCtrl.text = '0'; _taxCtrl.text = '0';
      ref.read(invoiceListProvider.notifier).refresh();
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Invoice created successfully!'), backgroundColor: AppColors.success)); widget.onInvoiceCreated?.call(); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }
}
