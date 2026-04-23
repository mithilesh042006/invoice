import '../database/product_dao.dart';
import '../models/product.dart';

/// Repository layer for Product operations.
/// Wraps the DAO and provides a clean API for providers.
class ProductRepository {
  final ProductDao _dao = ProductDao();

  Future<List<Product>> getAllActiveProducts() => _dao.getAllActive();

  Future<Product?> getProductById(String id) => _dao.getById(id);

  Future<List<Product>> searchProducts(String query) => _dao.search(query);

  Future<void> addProduct(Product product) => _dao.insert(product);

  Future<void> updateProduct(Product product) => _dao.update(product);

  /// Soft-deletes the product (keeps row in DB for historical invoices).
  Future<void> deleteProduct(String id) => _dao.softDelete(id);

  Future<int> getActiveProductCount() => _dao.getActiveCount();
}
