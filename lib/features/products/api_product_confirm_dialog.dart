import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../data/models/product.dart';
import '../../services/barcode_api_service.dart';
import 'product_providers.dart';

/// Dialog shown when a barcode is found via the Open Food Facts API.
///
/// Pre-fills the product name and brand from the API, but requires the user
/// to enter a price (since API doesn't provide shop-specific pricing).
///
/// Returns the saved [Product] if confirmed, or `null` if cancelled.
class ApiProductConfirmDialog extends ConsumerStatefulWidget {
  final BarcodeApiResult apiResult;

  const ApiProductConfirmDialog({super.key, required this.apiResult});

  @override
  ConsumerState<ApiProductConfirmDialog> createState() =>
      _ApiProductConfirmDialogState();
}

class _ApiProductConfirmDialogState
    extends ConsumerState<ApiProductConfirmDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _descriptionCtrl;
  String? _selectedUnit;
  bool _isSaving = false;

  static const _units = [
    'pcs', 'kg', 'g', 'liters', 'ml', 'meters', 'box', 'pack', 'dozen'
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.apiResult.productName);
    _priceCtrl = TextEditingController(); // Always empty — user must enter
    _descriptionCtrl = TextEditingController(
      text: _buildDescription(),
    );

    // Try to guess unit from quantity string
    _selectedUnit = _guessUnit(widget.apiResult.quantity);
  }

  String _buildDescription() {
    final parts = <String>[];
    if (widget.apiResult.brand != null) parts.add(widget.apiResult.brand!);
    if (widget.apiResult.quantity != null) parts.add(widget.apiResult.quantity!);
    return parts.join(' • ');
  }

  String? _guessUnit(String? quantity) {
    if (quantity == null) return 'pcs';
    final q = quantity.toLowerCase();
    if (q.contains('kg')) return 'kg';
    if (q.contains('g')) return 'g';
    if (q.contains('ml')) return 'ml';
    if (q.contains('l')) return 'liters';
    return 'pcs';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return AlertDialog(
      title: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.cloud_done, color: AppColors.success, size: 20),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text('Product Found Online', overflow: TextOverflow.ellipsis),
        ),
      ]),
      content: SizedBox(
        width: isMobile ? MediaQuery.of(context).size.width * 0.9 : 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── API source badge ──
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.qr_code, size: 16, color: AppColors.info),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Barcode: ${widget.apiResult.barcode}',
                        style: const TextStyle(
                          color: AppColors.info,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Open Food Facts',
                        style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),

                // ── Product Name ──
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Product Name *',
                    prefixIcon: Icon(Icons.inventory_2_outlined, size: 20),
                  ),
                  validator: (v) => validateRequired(v, 'Product name'),
                ),
                const SizedBox(height: 16),

                // ── Price (REQUIRED — not from API) ──
                TextFormField(
                  controller: _priceCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Price *',
                    hintText: 'Enter your selling price',
                    prefixIcon: const Icon(Icons.currency_rupee, size: 20),
                    filled: true,
                    fillColor: AppColors.accent.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.accent.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.accent, width: 2),
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Price is required';
                    final price = double.tryParse(v.trim());
                    if (price == null || price <= 0) return 'Enter a valid price';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // ── Unit ──
                DropdownButtonFormField<String>(
                  initialValue: _selectedUnit,
                  decoration: const InputDecoration(
                    labelText: 'Unit',
                    prefixIcon: Icon(Icons.straighten, size: 20),
                  ),
                  items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                  onChanged: (v) => setState(() => _selectedUnit = v),
                ),
                const SizedBox(height: 12),

                // ── Description ──
                TextFormField(
                  controller: _descriptionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    prefixIcon: Icon(Icons.notes, size: 20),
                  ),
                  maxLines: 2,
                ),

                // ── API info hint ──
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(children: [
                    Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Product name is from the API. Price must be set by you. This product will be saved locally for future scans.',
                        style: TextStyle(color: AppColors.warning, fontSize: 11),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveAndReturn,
          icon: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save, size: 18),
          label: Text(_isSaving ? 'Saving...' : 'Save & Add to Cart'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.black,
          ),
        ),
      ],
    );
  }

  Future<void> _saveAndReturn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final price = double.parse(_priceCtrl.text.trim());
      final now = DateTime.now();
      final product = Product(
        id: const Uuid().v4(),
        name: _nameCtrl.text.trim(),
        price: price,
        description: _descriptionCtrl.text.trim().isEmpty
            ? null
            : _descriptionCtrl.text.trim(),
        unit: _selectedUnit,
        barcode: widget.apiResult.barcode,
        createdAt: now,
        updatedAt: now,
      );

      // Save to SQLite via provider
      final notifier = ref.read(productListProvider.notifier);
      await notifier.addProduct(
        name: product.name,
        price: product.price,
        description: product.description,
        unit: product.unit,
        barcode: product.barcode,
      );

      // Re-fetch the product from DB to get the actual saved instance
      final repo = ref.read(productRepositoryProvider);
      final saved = await repo.getProductByBarcode(widget.apiResult.barcode);

      if (mounted) {
        Navigator.pop(context, saved ?? product);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
