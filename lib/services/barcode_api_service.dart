import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Result from the Open Food Facts API lookup.
class BarcodeApiResult {
  final String barcode;
  final String productName;
  final String? brand;
  final String? quantity; // e.g. "500g", "1L"
  final String? imageUrl;
  final String? categories;

  const BarcodeApiResult({
    required this.barcode,
    required this.productName,
    this.brand,
    this.quantity,
    this.imageUrl,
    this.categories,
  });

  /// A user-friendly display name combining product name + brand.
  String get displayName {
    if (brand != null && brand!.isNotEmpty && !productName.toLowerCase().contains(brand!.toLowerCase())) {
      return '$productName ($brand)';
    }
    return productName;
  }
}

/// Service for looking up barcodes via the Open Food Facts API.
///
/// This is a **secondary fallback** — always check local SQLite first.
/// The API is free, requires no API key, and has data for millions of products.
///
/// Endpoint: `https://world.openfoodfacts.org/api/v0/product/{barcode}.json`
class BarcodeApiService {
  static const _baseUrl = 'https://world.openfoodfacts.org/api/v0/product';
  static const _timeout = Duration(seconds: 3);

  /// Look up a barcode on Open Food Facts.
  ///
  /// Returns [BarcodeApiResult] if the product exists, or `null` if:
  /// - Product not found
  /// - Network error / timeout
  /// - Invalid response
  static Future<BarcodeApiResult?> lookupBarcode(String barcode) async {
    try {
      final uri = Uri.parse('$_baseUrl/$barcode.json');
      debugPrint('🌐 API lookup: $uri');

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'SmartShopManager/1.0 (Flutter; contact@smartshop.app)',
        },
      ).timeout(_timeout);

      if (response.statusCode != 200) {
        debugPrint('🌐 API returned status ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // Check if product was found
      final status = data['status'] as int?;
      if (status != 1) {
        debugPrint('🌐 Product not found in API (status: $status)');
        return null;
      }

      final product = data['product'] as Map<String, dynamic>?;
      if (product == null) return null;

      // Extract product name — try multiple fields
      final name = _extractName(product);
      if (name == null || name.isEmpty) {
        debugPrint('🌐 API product has no name, skipping');
        return null;
      }

      final result = BarcodeApiResult(
        barcode: barcode,
        productName: name,
        brand: _cleanField(product['brands'] as String?),
        quantity: _cleanField(product['quantity'] as String?),
        imageUrl: product['image_front_small_url'] as String? ??
            product['image_url'] as String?,
        categories: _cleanField(product['categories'] as String?),
      );

      debugPrint('🌐 API found: ${result.displayName}');
      return result;
    } catch (e) {
      debugPrint('🌐 API error: $e');
      return null; // Graceful failure — app works offline
    }
  }

  /// Try multiple name fields to get the best product name.
  static String? _extractName(Map<String, dynamic> product) {
    // Priority: product_name > product_name_en > generic_name
    for (final key in ['product_name', 'product_name_en', 'generic_name']) {
      final value = product[key] as String?;
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  /// Clean a field value — trim whitespace and return null if empty.
  static String? _cleanField(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
