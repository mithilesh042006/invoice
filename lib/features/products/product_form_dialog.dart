import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../data/models/product.dart';
import '../scanner/scanner_screen.dart';
import 'product_providers.dart';

/// Dialog for adding or editing a product.
class ProductFormDialog extends ConsumerStatefulWidget {
  final Product? product; // null = add mode, non-null = edit mode
  final String? initialBarcode; // pre-fill barcode from scanner

  const ProductFormDialog({super.key, this.product, this.initialBarcode});

  @override
  ConsumerState<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _barcodeController;
  String? _selectedUnit;
  bool _isLoading = false;

  bool get isEditing => widget.product != null;

  static const _units = ['pcs', 'kg', 'g', 'liters', 'ml', 'meters', 'box', 'pack', 'dozen'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _priceController = TextEditingController(
      text: widget.product != null ? widget.product!.price.toString() : '',
    );
    _descriptionController =
        TextEditingController(text: widget.product?.description ?? '');
    _barcodeController =
        TextEditingController(text: widget.product?.barcode ?? widget.initialBarcode ?? '');
    _selectedUnit = widget.product?.unit;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );

    if (scannedCode != null && mounted) {
      setState(() {
        _barcodeController.text = scannedCode;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isEditing ? Icons.edit_outlined : Icons.add_circle_outline,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Text(isEditing ? 'Edit Product' : 'Add Product'),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width < 600
            ? MediaQuery.of(context).size.width * 0.9
            : 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Name ──
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name *',
                  hintText: 'e.g., Rice, Sugar, Laptop',
                ),
                validator: (v) => validateRequired(v, 'Product name'),
                autofocus: true,
              ),
              const SizedBox(height: 16),

              // ── Price & Unit (side by side) ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price (₹) *',
                        hintText: '0.00',
                        prefixText: '₹ ',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => validatePositiveNumber(v, 'Price'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('None'),
                        ),
                        ..._units.map((u) => DropdownMenuItem(
                              value: u,
                              child: Text(u),
                            )),
                      ],
                      onChanged: (v) => setState(() => _selectedUnit = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Barcode ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _barcodeController,
                      decoration: const InputDecoration(
                        labelText: 'Barcode (optional)',
                        hintText: 'e.g., 8901234567890',
                        prefixIcon: Icon(Icons.qr_code, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: IconButton.filled(
                      onPressed: _scanBarcode,
                      icon: const Icon(Icons.camera_alt, size: 20),
                      tooltip: 'Scan Barcode',
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Description ──
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Brief description...',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final notifier = ref.read(productListProvider.notifier);
      final price = double.parse(_priceController.text.trim());
      final barcode = _barcodeController.text.trim().isEmpty
          ? null
          : _barcodeController.text.trim();

      if (isEditing) {
        await notifier.updateProduct(
          existing: widget.product!,
          name: _nameController.text,
          price: price,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          unit: _selectedUnit,
          barcode: barcode,
        );
      } else {
        await notifier.addProduct(
          name: _nameController.text,
          price: price,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          unit: _selectedUnit,
          barcode: barcode,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'Product updated' : 'Product added',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
