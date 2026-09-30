import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/brand.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/supplier.dart';
import '../repositories/brand_repository.dart';
import '../repositories/category_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/supplier_repository.dart';
import '../validation/validators.dart';
import '../widgets/chip_multi_select.dart';
import '../widgets/entity_form_shell.dart';

class ProductFormScreen extends StatefulWidget {
  final int? id;
  const ProductFormScreen({super.key, this.id});
  bool get isEditing => id != null;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _ratingCtrl = TextEditingController();

  int? _supplierId;
  List<int> _categoryIds = [];
  List<int> _brandIds = [];
  bool _loading = true;
  bool _dirty = false;
  String? _skuUniqueError;
  Product? _existing;

  List<Supplier> _suppliers = [];
  List<ProductCategory> _categories = [];
  List<Brand> _brands = [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final suppliers = await context.read<SupplierRepository>().findAll();
    final categories = await context.read<CategoryRepository>().findAll();
    final brands = await context.read<BrandRepository>().findAll();

    if (widget.id != null) {
      final found = await context.read<ProductRepository>().findById(widget.id!);
      if (found != null) {
        _existing = found;
        _nameCtrl.text = found.name;
        _skuCtrl.text = found.sku;
        _priceCtrl.text = found.price.toStringAsFixed(0);
        _stockCtrl.text = found.stock.toString();
        _ratingCtrl.text = found.rating.toString();
        _supplierId = found.supplierId;
        _categoryIds = [...found.categoryIds];
        _brandIds = [...found.brandIds];
      }
    } else {
      _priceCtrl.text = '1000';
      _stockCtrl.text = '10';
      _ratingCtrl.text = '4.5';
    }

    if (mounted) {
      setState(() {
        _suppliers = suppliers;
        _categories = categories;
        _brands = brands;
        _loading = false;
      });
    }
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  /// Каскад: после выбора поставщика остаются только связанные бренды.
  List<Brand> get _availableBrands {
    if (_supplierId == null) return const [];
    return _brands
        .where((b) => b.supplierIds.contains(_supplierId))
        .toList();
  }

  Future<void> _onSkuChanged(String value) async {
    _markDirty();
    final format = AppValidators.sku(value);
    if (format != null) {
      setState(() => _skuUniqueError = null);
      return;
    }
    final taken = await context.read<ProductRepository>().isSkuTaken(
          value,
          excludeId: _existing?.id,
        );
    if (!mounted) return;
    setState(() => _skuUniqueError = taken ? 'Такой артикул уже существует' : null);
  }

  Future<void> _save() async {
    // финальная проверка уникальности перед validate
    final taken = await context.read<ProductRepository>().isSkuTaken(
          _skuCtrl.text,
          excludeId: _existing?.id,
        );
    if (!mounted) return;
    setState(() => _skuUniqueError = taken ? 'Такой артикул уже существует' : null);

    if (!_formKey.currentState!.validate()) return;
    if (_skuUniqueError != null) return;

    final repo = context.read<ProductRepository>();
    final product = Product(
      id: _existing?.id ?? 0,
      name: _nameCtrl.text.trim(),
      sku: _skuCtrl.text.trim().toUpperCase(),
      supplierId: _supplierId!,
      categoryIds: _categoryIds,
      brandIds: _brandIds,
      price: double.parse(_priceCtrl.text.trim().replaceAll(',', '.')),
      stock: int.parse(_stockCtrl.text.trim()),
      rating: double.parse(_ratingCtrl.text.trim().replaceAll(',', '.')),
      deletedAt: _existing?.deletedAt,
    );

    if (_existing == null) {
      await repo.create(product);
    } else {
      await repo.update(product);
    }

    if (mounted) {
      setState(() => _dirty = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_existing == null ? 'Товар создан' : 'Товар сохранён')),
      );
      context.go('/products');
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _skuCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _ratingCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return EntityFormShell(
      title: widget.isEditing ? 'Редактирование товара' : 'Новый товар',
      subtitle: widget.isEditing ? 'Изменение карточки товара' : 'Создание товара зоомагазина',
      icon: widget.isEditing ? Icons.edit_note : Icons.add_circle_outline,
      formKey: _formKey,
      isDirty: _dirty,
      isEditing: widget.isEditing,
      onCancel: () => context.go('/products'),
      onSave: _save,
      children: [
        TextFormField(
          controller: _nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Название *',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _markDirty(),
          validator: (v) => AppValidators.lengthRange(v, min: 3, max: 120, field: 'Название'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _skuCtrl,
          decoration: InputDecoration(
            labelText: 'Артикул (SKU) *',
            hintText: 'PET-1099',
            border: const OutlineInputBorder(),
            errorText: _skuUniqueError,
          ),
          onChanged: _onSkuChanged,
          validator: (v) => AppValidators.sku(v) ?? _skuUniqueError,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          value: _supplierId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Поставщик *',
            border: OutlineInputBorder(),
            helperText: 'При выборе поставщика список брендов сужается',
          ),
          items: _suppliers
              .map((s) => DropdownMenuItem(
                    value: s.id,
                    child: Text(s.name, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (v) {
            setState(() {
              _supplierId = v;
              _dirty = true;
              final allowed = _availableBrands.map((b) => b.id).toSet();
              _brandIds = _brandIds.where(allowed.contains).toList();
            });
          },
          validator: (v) => AppValidators.requiredId(v, field: 'поставщика'),
        ),
        const SizedBox(height: 16),
        ChipMultiSelectFormField(
          label: 'Категории *',
          value: _categoryIds,
          options: _categories.map((c) => (id: c.id, name: c.name)).toList(),
          onChanged: (next) => setState(() {
            _categoryIds = next;
            _dirty = true;
          }),
          validator: (v) => AppValidators.nonEmptyIds(v, field: 'категорию'),
        ),
        const SizedBox(height: 16),
        ChipMultiSelectFormField(
          label: 'Бренды *',
          value: _brandIds,
          options: _availableBrands.map((b) => (id: b.id, name: b.name)).toList(),
          emptyHint: _supplierId == null
              ? 'Сначала выберите поставщика'
              : 'Нет брендов у этого поставщика',
          onChanged: (next) => setState(() {
            _brandIds = next;
            _dirty = true;
          }),
          validator: (v) => AppValidators.nonEmptyIds(v, field: 'бренд'),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Цена, ₽ *',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _markDirty(),
                validator: (v) => AppValidators.positiveNumber(v, field: 'Цена'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _stockCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Остаток, шт. *',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _markDirty(),
                validator: (v) => AppValidators.nonNegativeInt(v, field: 'Остаток'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _ratingCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Рейтинг *',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _markDirty(),
                validator: (v) =>
                    AppValidators.rangeDouble(v, min: 1, max: 5, field: 'Рейтинг'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
