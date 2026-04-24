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
      return Row(children: [
        const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 22),
        const SizedBox(width: 8),
        Text('Products', style: Theme.of(context).textTheme.titleLarge),
        const Spacer(),
        SizedBox(
          height: 36,
          child: ElevatedButton.icon(
            onPressed: () => _showProductForm(context, ref),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add', style: TextStyle(fontSize: 13)),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
          ),
        ),
      ]);
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

  // ── Mobile: Compact Rows ──
  Widget _buildProductCards(BuildContext context, WidgetRef ref, List<Product> products) {
    return ListView.separated(
      itemCount: products.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border.withValues(alpha: 0.5)),
      itemBuilder: (context, index) {
        final product = products[index];
        return InkWell(
          onTap: () => _showProductForm(context, ref, product: product),
          onLongPress: () => _confirmDelete(context, ref, product),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Row(children: [
              // Product name
              Expanded(
                child: Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textPrimary, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Price
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  formatCurrency(product.price),
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.accent, fontSize: 16),
                ),
              ),
              // Edit
              SizedBox(
                width: 34, height: 34,
                child: IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: AppColors.info,
                  padding: EdgeInsets.zero,
                  onPressed: () => _showProductForm(context, ref, product: product),
                ),
              ),
              // Delete
              SizedBox(
                width: 34, height: 34,
                child: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: AppColors.error,
                  padding: EdgeInsets.zero,
                  onPressed: () => _confirmDelete(context, ref, product),
                ),
              ),
            ]),
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
