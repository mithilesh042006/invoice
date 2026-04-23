import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/responsive.dart';
import 'product_providers.dart';
import 'product_form_dialog.dart';
import '../../data/models/product.dart';

/// Product list screen — DataTable on desktop, card list on mobile.
class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(filteredProductListProvider);
    final mobile = Responsive.isMobile(context);
    final padding = Responsive.screenPadding(context);

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          _buildHeader(context, ref, mobile),
          const SizedBox(height: 16),

          // ── Search Bar ──
          _buildSearchBar(ref, mobile),
          const SizedBox(height: 16),

          // ── Product List ──
          Expanded(
            child: productsAsync.when(
              data: (products) => products.isEmpty
                  ? _buildEmptyState(context)
                  : mobile
                      ? _buildProductCards(context, ref, products)
                      : _buildProductTable(context, ref, products),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Error: $e',
                    style: const TextStyle(color: AppColors.error)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, bool mobile) {
    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 24),
            const SizedBox(width: 10),
            Text('Products', style: Theme.of(context).textTheme.titleLarge),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showProductForm(context, ref),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add Product'),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 28),
        const SizedBox(width: 12),
        Text('Products', style: Theme.of(context).textTheme.headlineMedium),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () => _showProductForm(context, ref),
          icon: const Icon(Icons.add, size: 20),
          label: const Text('Add Product'),
        ),
      ],
    );
  }

  Widget _buildSearchBar(WidgetRef ref, bool mobile) {
    return SizedBox(
      width: mobile ? double.infinity : 400,
      child: TextField(
        onChanged: (value) {
          ref.read(productSearchQueryProvider.notifier).state = value;
        },
        decoration: const InputDecoration(
          hintText: 'Search products...',
          prefixIcon: Icon(Icons.search, color: AppColors.textHint),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 80, color: AppColors.textHint.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'No products yet',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: AppColors.textHint),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first product to get started',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  // ── Mobile: Card List ──
  Widget _buildProductCards(BuildContext context, WidgetRef ref, List<Product> products) {
    return ListView.separated(
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Product icon
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.inventory_2, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    // Name & description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontSize: 15,
                            ),
                          ),
                          if (product.description != null && product.description!.isNotEmpty)
                            Text(
                              product.description!,
                              style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    // Price
                    Text(
                      formatCurrency(product.price),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Bottom row: unit + barcode + actions
                Row(
                  children: [
                    if (product.unit != null && product.unit!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          product.unit!,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ),
                    if (product.barcode != null && product.barcode!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.qr_code, size: 12, color: AppColors.accent),
                          const SizedBox(width: 4),
                          Text(product.barcode!, style: const TextStyle(fontSize: 11, color: AppColors.accent)),
                        ]),
                      ),
                    ],
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      color: AppColors.info,
                      tooltip: 'Edit',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _showProductForm(context, ref, product: product),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: AppColors.error,
                      tooltip: 'Delete',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _confirmDelete(context, ref, product),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Desktop: DataTable ──
  Widget _buildProductTable(BuildContext context, WidgetRef ref, List<Product> products) {
    return Card(
      child: SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: DataTable(
            headingRowHeight: 52,
            dataRowMinHeight: 56,
            dataRowMaxHeight: 56,
            columnSpacing: 32,
            columns: const [
              DataColumn(label: Text('#')),
              DataColumn(label: Text('NAME')),
              DataColumn(label: Text('PRICE')),
              DataColumn(label: Text('UNIT')),
              DataColumn(label: Text('ACTIONS')),
            ],
            rows: List.generate(products.length, (index) {
              final product = products[index];
              return DataRow(
                cells: [
                  DataCell(Text('${index + 1}')),
                  DataCell(
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (product.description != null && product.description!.isNotEmpty)
                          Text(
                            product.description!,
                            style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  DataCell(Text(
                    formatCurrency(product.price),
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.accent),
                  )),
                  DataCell(Text(product.unit ?? '—')),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          color: AppColors.info,
                          tooltip: 'Edit',
                          onPressed: () => _showProductForm(context, ref, product: product),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          color: AppColors.error,
                          tooltip: 'Delete',
                          onPressed: () => _confirmDelete(context, ref, product),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  void _showProductForm(BuildContext context, WidgetRef ref, {Product? product}) {
    showDialog(
      context: context,
      builder: (ctx) => ProductFormDialog(product: product),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
          'Are you sure you want to delete "${product.name}"?\n'
          'This product will be hidden but old invoices will still reference it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ref.read(productListProvider.notifier).deleteProduct(product.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('"${product.name}" deleted')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
