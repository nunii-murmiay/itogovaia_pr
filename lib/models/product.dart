class Product {
  final int id;
  final String name;
  final String sku;
  final int categoryId;
  final int supplierId;
  final double price;
  final int stock;
  final double rating;
  final List<String> animalTypes;
  final DateTime? deletedAt;

  const Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.categoryId,
    required this.supplierId,
    required this.price,
    required this.stock,
    required this.rating,
    required this.animalTypes,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Product copyWith({
    String? name,
    String? sku,
    int? categoryId,
    int? supplierId,
    double? price,
    int? stock,
    double? rating,
    List<String>? animalTypes,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      categoryId: categoryId ?? this.categoryId,
      supplierId: supplierId ?? this.supplierId,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      rating: rating ?? this.rating,
      animalTypes: animalTypes ?? this.animalTypes,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}
