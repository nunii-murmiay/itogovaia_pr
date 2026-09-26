import '../models/page_result.dart';
import '../models/seed_data.dart';
import '../models/supplier.dart';
import '../models/supplier_query.dart';
import 'supplier_repository.dart';

class InMemorySupplierRepository implements SupplierRepository {
  final List<Supplier> _suppliers = [...seedSuppliers];
  int _nextId = seedSuppliers.length + 1;

  @override
  Future<PageResult<Supplier>> find(SupplierQuery q) async {
    await Future.delayed(const Duration(milliseconds: 250));

    var rows = _suppliers.where((s) => q.includeDeleted || !s.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where((s) =>
              s.name.toLowerCase().contains(needle) ||
              s.country.toLowerCase().contains(needle) ||
              s.contactPerson.toLowerCase().contains(needle) ||
              s.email.toLowerCase().contains(needle))
          .toList();
    }

    if (q.country != null && q.country!.isNotEmpty) {
      rows = rows.where((s) => s.country.toLowerCase() == q.country!.toLowerCase()).toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'country' => a.country.toLowerCase().compareTo(b.country.toLowerCase()),
        'rating' => a.rating.compareTo(b.rating),
        'contactPerson' => a.contactPerson.toLowerCase().compareTo(b.contactPerson.toLowerCase()),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Supplier>[] : rows.sublist(from, to);

    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Supplier?> findById(int id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final i = _suppliers.indexWhere((s) => s.id == id);
    if (i == -1) return null;
    return _suppliers[i];
  }

  @override
  Future<Supplier> create(Supplier supplier) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final created = Supplier(
      id: _nextId++,
      name: supplier.name,
      country: supplier.country,
      contactPerson: supplier.contactPerson,
      phone: supplier.phone,
      email: supplier.email,
      rating: supplier.rating,
      deletedAt: supplier.deletedAt,
    );
    _suppliers.add(created);
    return created;
  }

  @override
  Future<Supplier> update(Supplier supplier) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final i = _suppliers.indexWhere((s) => s.id == supplier.id);
    if (i == -1) throw StateError('Поставщик с id ${supplier.id} не найден');
    _suppliers[i] = supplier;
    return _suppliers[i];
  }

  @override
  Future<void> softDelete(int id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final i = _suppliers.indexWhere((s) => s.id == id);
    if (i == -1) throw StateError('Поставщик с id $id не найден');
    _suppliers[i] = _suppliers[i].copyWith(deletedAt: DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _suppliers.removeWhere((s) => s.id == id);
  }

  @override
  Future<void> restore(int id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final i = _suppliers.indexWhere((s) => s.id == id);
    if (i == -1) throw StateError('Поставщик с id $id не найден');
    _suppliers[i] = _suppliers[i].copyWith(clearDeletedAt: true);
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    await Future.delayed(const Duration(milliseconds: 200));
    var count = 0;
    for (final id in ids) {
      final i = _suppliers.indexWhere((s) => s.id == id && !s.isDeleted);
      if (i != -1) {
        _suppliers[i] = _suppliers[i].copyWith(deletedAt: DateTime.now());
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
      final i = _suppliers.indexWhere((s) => s.id == id && s.isDeleted);
      if (i != -1) {
        _suppliers[i] = _suppliers[i].copyWith(clearDeletedAt: true);
        count++;
      }
    }
    return count;
  }
}
