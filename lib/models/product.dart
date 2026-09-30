class Product {
  final int id;
  final String name;
  final String sku;
  final int supplierId;
  final List<int> categoryIds;
  final List<int> brandIds;
  final double price;
  final int stock;
  final double rating;
  final DateTime? deletedAt;

  const Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.supplierId,
    required this.categoryIds,
    required this.brandIds,
    required this.price,
    required this.stock,
    required this.rating,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Product copyWith({
    int? id,
    String? name,
    String? sku,
    int? supplierId,
    List<int>? categoryIds,
    List<int>? brandIds,
    double? price,
    int? stock,
    double? rating,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      supplierId: supplierId ?? this.supplierId,
      categoryIds: categoryIds ?? this.categoryIds,
      brandIds: brandIds ?? this.brandIds,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      rating: rating ?? this.rating,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sku': sku,
        'supplierId': supplierId,
        'categoryIds': categoryIds,
        'brandIds': brandIds,
        'price': price,
        'stock': stock,
        'rating': rating,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        sku: json['sku'] as String? ?? '',
        supplierId: (json['supplierId'] as num?)?.toInt() ?? 0,
        categoryIds: _toIntList(json['categoryIds'] ?? json['categoryId']),
        brandIds: _toIntList(json['brandIds']),
        price: (json['price'] as num?)?.toDouble() ?? 0,
        stock: (json['stock'] as num?)?.toInt() ?? 0,
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        deletedAt: json['deletedAt'] == null
            ? null
            : DateTime.tryParse(json['deletedAt'].toString()),
      );

  static List<int> _toIntList(dynamic value) {
    if (value is List) {
      return value.map((e) => (e as num).toInt()).toList();
    }
    if (value is num) return [value.toInt()];
    return const [];
  }
}
