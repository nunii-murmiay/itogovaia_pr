import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/seed_data.dart';
import '../repositories/product_repository.dart';

class ProductDetailScreen extends StatefulWidget {
  final int? productId;

  const ProductDetailScreen({
    super.key,
    this.productId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  Product? _product;

  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _ratingController;
  int _categoryId = 1;
  int _supplierId = 1;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _skuController = TextEditingController();
    _priceController = TextEditingController();
    _stockController = TextEditingController();
    _ratingController = TextEditingController();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    if (widget.productId == null) {
      setState(() {
        _isLoading = false;
        _priceController.text = '1000';
        _stockController.text = '10';
        _ratingController.text = '4.5';
      });
      return;
    }

    final repo = context.read<ProductRepository>();
    final found = await repo.findById(widget.productId!);
    if (found != null && mounted) {
      setState(() {
        _product = found;
        _nameController.text = found.name;
        _skuController.text = found.sku;
        _priceController.text = found.price.toString();
        _stockController.text = found.stock.toString();
        _ratingController.text = found.rating.toString();
        _categoryId = found.categoryId;
        _supplierId = found.supplierId;
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _ratingController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = context.read<ProductRepository>();
    final price = double.tryParse(_priceController.text) ?? 0.0;
    final stock = int.tryParse(_stockController.text) ?? 0;
    final rating = double.tryParse(_ratingController.text) ?? 5.0;

    if (_product == null) {
      final newProd = Product(
        id: 0,
        name: _nameController.text.trim(),
        sku: _skuController.text.trim(),
        categoryId: _categoryId,
        supplierId: _supplierId,
        price: price,
        stock: stock,
        rating: rating,
        animalTypes: ['Все'],
      );
      await repo.create(newProd);
    } else {
      final updated = _product!.copyWith(
        name: _nameController.text.trim(),
        sku: _skuController.text.trim(),
        categoryId: _categoryId,
        supplierId: _supplierId,
        price: price,
        stock: stock,
        rating: rating,
      );
      await repo.update(updated);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Товар успешно сохранен!')),
      );
      context.go('/products');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isNew = _product == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'Новый товар зоомагазина' : 'Редактирование: ${_product!.name}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/products'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isNew ? Icons.add_circle_outline : Icons.edit_note,
                            size: 28,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            isNew ? 'Карточка создания товара' : 'Редактирование данных товара',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Название товара *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Введите название товара' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _skuController,
                        decoration: const InputDecoration(
                          labelText: 'Артикул / Штрихкод',
                          hintText: 'например, PET-1099',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _categoryId,
                              decoration: const InputDecoration(
                                labelText: 'Категория',
                                border: OutlineInputBorder(),
                              ),
                              items: ProductCategory.defaultCategories.map((c) {
                                return DropdownMenuItem(value: c.id, child: Text(c.name));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _categoryId = val);
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _supplierId,
                              decoration: const InputDecoration(
                                labelText: 'Поставщик',
                                border: OutlineInputBorder(),
                              ),
                              items: seedSuppliers.map((s) {
                                return DropdownMenuItem(value: s.id, child: Text(s.name));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _supplierId = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Цена, ₽ *',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => (v == null || double.tryParse(v) == null) ? 'Укажите верную цену' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _stockController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Остаток на складе, шт. *',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => (v == null || int.tryParse(v) == null) ? 'Укажите количество' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _ratingController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Рейтинг (1.0 - 5.0)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => context.go('/products'),
                            child: const Text('Отмена'),
                          ),
                          const SizedBox(width: 16),
                          FilledButton.icon(
                            onPressed: _save,
                            icon: const Icon(Icons.save),
                            label: const Text('Сохранить'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
