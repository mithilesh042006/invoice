/// Product model — represents an item available for sale.
class Product {
  final String id;
  final String name;
  final double price;
  final String? description;
  final String? unit; // "kg", "pcs", "liters", etc.
  final String? barcode; // barcode value for scanning
  final bool isDeleted; // soft delete flag
  final DateTime createdAt;
  final DateTime updatedAt;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    this.description,
    this.unit,
    this.barcode,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from SQLite row map.
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      description: map['description'] as String?,
      unit: map['unit'] as String?,
      barcode: map['barcode'] as String?,
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Convert to SQLite row map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'description': description,
      'unit': unit,
      'barcode': barcode,
      'is_deleted': isDeleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with modified fields.
  Product copyWith({
    String? id,
    String? name,
    double? price,
    String? description,
    String? unit,
    String? barcode,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      barcode: barcode ?? this.barcode,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Product(id: $id, name: $name, price: $price, barcode: $barcode)';
}
