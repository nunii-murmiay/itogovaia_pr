import 'package:flutter/foundation.dart';
import '../models/page_result.dart';
import '../models/supplier.dart';
import '../models/supplier_query.dart';
import '../repositories/supplier_repository.dart';
import 'product_list_notifier.dart';

class SupplierListNotifier extends ChangeNotifier {
  final SupplierRepository _repository;

  SupplierListNotifier(this._repository);

  SupplierQuery _query = const SupplierQuery();
  PageResult<Supplier> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};

  SupplierQuery get query => _query;
  PageResult<Supplier> get result => _result;
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
      _error = 'Не удалось загрузить список поставщиков: $e';
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> applyQuery(SupplierQuery next) async {
    _query = next;
    _selected.clear();
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

  void simulateError() {
    _status = LoadStatus.error;
    _error = 'Ошибка подключения к базе данных поставщиков (имитация сбоя)';
    notifyListeners();
  }
}
