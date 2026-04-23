import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/product.dart';
import '../../data/repositories/product_repository.dart';

// ── Repository Provider ──
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

// ── Product List Provider ──
final productListProvider =
    AsyncNotifierProvider<ProductListNotifier, List<Product>>(
  ProductListNotifier.new,
);

class ProductListNotifier extends AsyncNotifier<List<Product>> {
  late ProductRepository _repository;

  @override
  Future<List<Product>> build() async {
    _repository = ref.read(productRepositoryProvider);
    return _repository.getAllActiveProducts();
  }

  Future<void> addProduct({
    required String name,
    required double price,
    String? description,
    String? unit,
  }) async {
    final now = DateTime.now();
    final product = Product(
      id: const Uuid().v4(),
      name: name.trim(),
      price: price,
      description: description?.trim(),
      unit: unit?.trim(),
      createdAt: now,
      updatedAt: now,
    );
    await _repository.addProduct(product);
    ref.invalidateSelf();
  }

  Future<void> updateProduct({
    required Product existing,
    required String name,
    required double price,
    String? description,
    String? unit,
  }) async {
    final updated = existing.copyWith(
      name: name.trim(),
      price: price,
      description: description?.trim(),
      unit: unit?.trim(),
      updatedAt: DateTime.now(),
    );
    await _repository.updateProduct(updated);
    ref.invalidateSelf();
  }

  Future<void> deleteProduct(String id) async {
    await _repository.deleteProduct(id);
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

// ── Search Query Provider ──
final productSearchQueryProvider = StateProvider<String>((ref) => '');

// ── Filtered Product List Provider ──
final filteredProductListProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final query = ref.watch(productSearchQueryProvider).toLowerCase();
  final productsAsync = ref.watch(productListProvider);

  return productsAsync.whenData((products) {
    if (query.isEmpty) return products;
    return products
        .where((p) => p.name.toLowerCase().contains(query))
        .toList();
  });
});
