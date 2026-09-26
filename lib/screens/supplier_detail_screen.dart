import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/supplier.dart';
import '../repositories/supplier_repository.dart';

class SupplierDetailScreen extends StatefulWidget {
  final int? supplierId;

  const SupplierDetailScreen({
    super.key,
    this.supplierId,
  });

  @override
  State<SupplierDetailScreen> createState() => _SupplierDetailScreenState();
}

class _SupplierDetailScreenState extends State<SupplierDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  Supplier? _supplier;

  late TextEditingController _nameController;
  late TextEditingController _countryController;
  late TextEditingController _contactPersonController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _ratingController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _countryController = TextEditingController();
    _contactPersonController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _ratingController = TextEditingController();
    _loadSupplier();
  }

  Future<void> _loadSupplier() async {
    if (widget.supplierId == null) {
      setState(() {
        _isLoading = false;
        _ratingController.text = '4.5';
        _countryController.text = 'Россия';
      });
      return;
    }

    final repo = context.read<SupplierRepository>();
    final found = await repo.findById(widget.supplierId!);
    if (found != null && mounted) {
      setState(() {
        _supplier = found;
        _nameController.text = found.name;
        _countryController.text = found.country;
        _contactPersonController.text = found.contactPerson;
        _phoneController.text = found.phone;
        _emailController.text = found.email;
        _ratingController.text = found.rating.toString();
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _countryController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _ratingController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final repo = context.read<SupplierRepository>();
    final rating = double.tryParse(_ratingController.text) ?? 5.0;

    if (_supplier == null) {
      final newSupp = Supplier(
        id: 0,
        name: _nameController.text.trim(),
        country: _countryController.text.trim(),
        contactPerson: _contactPersonController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        rating: rating,
      );
      await repo.create(newSupp);
    } else {
      final updated = _supplier!.copyWith(
        name: _nameController.text.trim(),
        country: _countryController.text.trim(),
        contactPerson: _contactPersonController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        rating: rating,
      );
      await repo.update(updated);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Поставщик успешно сохранен!')),
      );
      context.go('/suppliers');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isNew = _supplier == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'Новый поставщик' : 'Редактирование: ${_supplier!.name}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/suppliers'),
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
                            isNew ? Icons.add_business : Icons.business,
                            size: 28,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            isNew ? 'Новая карточка поставщика' : 'Данные поставщика',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Название компании / бренда *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Введите название' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _countryController,
                              decoration: const InputDecoration(
                                labelText: 'Страна *',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Укажите страну' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _ratingController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Рейтинг надежности',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _contactPersonController,
                        decoration: const InputDecoration(
                          labelText: 'Контактное лицо',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Телефон',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
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
                            onPressed: () => context.go('/suppliers'),
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
