import '../models/page_result.dart';
import '../models/product.dart';
import '../models/product_query.dart';
import '../models/seed_data.dart';
import 'product_repository.dart';

class InMemoryProductRepository implements ProductRepository {
  final List<Product> _products = [...seedProducts];
  int _nextId = seedProducts.length + 1;

  @override
  Future<PageResult<Product>> find(ProductQuery q) async {
    await Future.delayed(const Duration(milliseconds: 250));

    var rows = _products.where((p) => q.includeDeleted || !p.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where((p) =>
              p.name.toLowerCase().contains(needle) ||
              p.sku.toLowerCase().contains(needle))
          .toList();
    }

    if (q.categoryId != null) {
      rows = rows.where((p) => p.categoryId == q.categoryId).toList();
    }
    if (q.supplierId != null) {
      rows = rows.where((p) => p.supplierId == q.supplierId).toList();
    }
    if (q.priceFrom != null) {
      rows = rows.where((p) => p.price >= q.priceFrom!).toList();
    }
    if (q.priceTo != null) {
      rows = rows.where((p) => p.price <= q.priceTo!).toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'price' => a.price.compareTo(b.price),
        'stock' => a.stock.compareTo(b.stock),
        'rating' => a.rating.compareTo(b.rating),
        'sku' => a.sku.toLowerCase().compareTo(b.sku.toLowerCase()),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Product>[] : rows.sublist(from, to);

    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Product?> findById(int id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final index = _products.indexWhere((p) => p.id == id);
    if (index == -1) return null;
    return _products[index];
  }

  @override
  Future<Product> create(Product product) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final newProduct = product.copyWith(
      name: product.name,
      sku: product.sku.isEmpty ? 'PET-${1000 + _nextId}' : product.sku,
    );
    final created = Product(
      id: _nextId++,
      name: newProduct.name,
      sku: newProduct.sku,
      categoryId: newProduct.categoryId,
      supplierId: newProduct.supplierId,
      price: newProduct.price,
      stock: newProduct.stock,
      rating: newProduct.rating,
      animalTypes: newProduct.animalTypes,
      deletedAt: newProduct.deletedAt,
    );
    _products.add(created);
    return created;
  }

  @override
  Future<Product> update(Product product) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final i = _products.indexWhere((p) => p.id == product.id);
    if (i == -1) throw StateError('Товар с id ${product.id} не найден');
    _products[i] = product;
    return _products[i];
  }

  @override
  Future<void> softDelete(int id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final i = _products.indexWhere((p) => p.id == id);
    if (i == -1) throw StateError('Товар с id $id не найден');
    _products[i] = _products[i].copyWith(deletedAt: DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _products.removeWhere((p) => p.id == id);
  }

  @override
  Future<void> restore(int id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final i = _products.indexWhere((p) => p.id == id);
    if (i == -1) throw StateError('Товар с id $id не найден');
    _products[i] = _products[i].copyWith(clearDeletedAt: true);
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    await Future.delayed(const Duration(milliseconds: 200));
    var count = 0;
    for (final id in ids) {
      // Исправлено: заменено неверное выражение b[i].isDeleted на p.isDeleted
      final i = _products.indexWhere((p) => p.id == id && !p.isDeleted);
      if (i != -1) {
        _products[i] = _products[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    return count;
  }

  @override
  Future<int> restoreMany(List<int> ids) async {
    await Future.delayed(const Duration(milliseconds: 200));
    var count = 0;
    for (final id in ids) {
      final i = _products.indexWhere((p) => p.id == id && p.isDeleted);
      if (i != -1) {
        _products[i] = _products[i].copyWith(clearDeletedAt: true);
        count++;
      }
    }
    return count;
  }
}
