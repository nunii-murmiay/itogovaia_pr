import 'package:flutter/foundation.dart';
import '../models/page_result.dart';
import '../models/product.dart';
import '../models/product_query.dart';
import '../repositories/product_repository.dart';

enum LoadStatus { idle, loading, success, error }

class ProductListNotifier extends ChangeNotifier {
  final ProductRepository _repository;

  ProductListNotifier(this._repository);

  ProductQuery _query = const ProductQuery();
  PageResult<Product> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};

  ProductQuery get query => _query;
  PageResult<Product> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();

    try {
      _result = await _repository.find(_query);
      _status = LoadStatus.success;
    } catch (e) {
      _error = 'Не удалось загрузить список товаров: $e';
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> applyQuery(ProductQuery next) async {
    _query = next;
    _selected.clear(); // выделение теряет смысл при смене условий отбора
    await load();
  }

  void toggleSelection(int id) {
    if (_selected.contains(id)) {
      _selected.remove(id);
    } else {
      _selected.add(id);
    }
    notifyListeners();
  }

  void toggleSelectAll(List<int> visibleIds) {
    final allSelected = visibleIds.every(_selected.contains);
    if (allSelected) {
      for (final id in visibleIds) {
        _selected.remove(id);
      }
    } else {
      _selected.addAll(visibleIds);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selected.clear();
    notifyListeners();
  }

  Future<void> deleteSelected() async {
    if (_selected.isEmpty) return;
    await _repository.deleteMany(_selected.toList());
    _selected.clear();
    await load();
  }

  Future<void> restoreSelected() async {
    if (_selected.isEmpty) return;
    await _repository.restoreMany(_selected.toList());
    _selected.clear();
    await load();
  }

  Future<void> softDelete(int id) async {
    await _repository.softDelete(id);
    _selected.remove(id);
    await load();
  }

  Future<void> hardDelete(int id) async {
    await _repository.hardDelete(id);
    _selected.remove(id);
    await load();
  }

  Future<void> restore(int id) async {
    await _repository.restore(id);
    await load();
  }

  /// Метод для демонстрации состояния ошибки (для проверок и тестов)
  void simulateError() {
    _status = LoadStatus.error;
    _error = 'Ошибка подключения к хранилищу (имитация сбоя для тестирования)';
    notifyListeners();
  }
}
