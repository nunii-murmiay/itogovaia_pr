import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../models/loyalty_card.dart';
import '../repositories/customer_repository.dart';
import '../validation/validators.dart';
import '../widgets/entity_form_shell.dart';

class CustomerFormScreen extends StatefulWidget {
  final int? id;
  const CustomerFormScreen({super.key, this.id});
  bool get isEditing => id != null;

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cardNumberCtrl = TextEditingController();
  final _pointsCtrl = TextEditingController();
  String _level = 'Стандарт';
  DateTime _issuedAt = DateTime.now();
  bool _loading = true;
  bool _dirty = false;
  String? _emailUniqueError;
  Customer? _existing;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.id != null) {
      final found = await context.read<CustomerRepository>().findById(widget.id!);
      if (found != null) {
        _existing = found;
        _nameCtrl.text = found.fullName;
        _emailCtrl.text = found.email;
        _phoneCtrl.text = found.phone;
        _cardNumberCtrl.text = found.card.number;
        _pointsCtrl.text = found.card.points.toString();
        _level = found.card.level;
        _issuedAt = found.card.issuedAt;
      }
    } else {
      _cardNumberCtrl.text = 'LC-${DateTime.now().millisecondsSinceEpoch % 100000}';
      _pointsCtrl.text = '0';
    }
    if (mounted) setState(() => _loading = false);
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _onEmailChanged(String value) async {
    _markDirty();
    final format = AppValidators.email(value);
    if (format != null) {
      setState(() => _emailUniqueError = null);
      return;
    }
    final taken = await context.read<CustomerRepository>().isEmailTaken(
          value,
          excludeId: _existing?.id,
        );
    if (!mounted) return;
    setState(() => _emailUniqueError = taken ? 'Этот email уже зарегистрирован' : null);
  }

  Future<void> _save() async {
    final taken = await context.read<CustomerRepository>().isEmailTaken(
          _emailCtrl.text,
          excludeId: _existing?.id,
        );
    if (!mounted) return;
    setState(() => _emailUniqueError = taken ? 'Этот email уже зарегистрирован' : null);
    if (!_formKey.currentState!.validate()) return;
    if (_emailUniqueError != null) return;

    final repo = context.read<CustomerRepository>();
    final item = Customer(
      id: _existing?.id ?? 0,
      fullName: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      card: LoyaltyCard(
        number: _cardNumberCtrl.text.trim(),
        issuedAt: _issuedAt,
        points: int.parse(_pointsCtrl.text.trim()),
        level: _level,
      ),
      deletedAt: _existing?.deletedAt,
    );
    if (_existing == null) {
      await repo.create(item);
    } else {
      await repo.update(item);
    }
    if (mounted) {
      setState(() => _dirty = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Клиент сохранён')),
      );
      context.go('/customers');
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _cardNumberCtrl.dispose();
    _pointsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return EntityFormShell(
      title: widget.isEditing ? 'Редактирование клиента' : 'Новый клиент',
      subtitle: 'Клиент и карта лояльности',
      icon: Icons.person_outline,
      formKey: _formKey,
      isDirty: _dirty,
      isEditing: widget.isEditing,
      onCancel: () => context.go('/customers'),
      onSave: _save,
      children: [
        TextFormField(
          controller: _nameCtrl,
          decoration: const InputDecoration(labelText: 'ФИО *', border: OutlineInputBorder()),
          onChanged: (_) => _markDirty(),
          validator: (v) => AppValidators.lengthRange(v, min: 3, max: 100, field: 'ФИО'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailCtrl,
          decoration: InputDecoration(
            labelText: 'Email *',
            border: const OutlineInputBorder(),
            errorText: _emailUniqueError,
          ),
          onChanged: _onEmailChanged,
          validator: (v) => AppValidators.email(v) ?? _emailUniqueError,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneCtrl,
          decoration: const InputDecoration(labelText: 'Телефон *', border: OutlineInputBorder()),
          onChanged: (_) => _markDirty(),
          validator: (v) => AppValidators.phone(v),
        ),
        const SizedBox(height: 24),
        Text(
          'Карта лояльности',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Связь один к одному: карта редактируется прямо в форме клиента',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _cardNumberCtrl,
          decoration: const InputDecoration(
            labelText: 'Номер карты *',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _markDirty(),
          validator: (v) => AppValidators.minLength(v, 4, field: 'Номер карты'),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _pointsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Баллы *',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _markDirty(),
                validator: (v) => AppValidators.nonNegativeInt(v, field: 'Баллы'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _level,
                decoration: const InputDecoration(
                  labelText: 'Уровень *',
                  border: OutlineInputBorder(),
                ),
                items: LoyaltyCard.levels
                    .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _level = v;
                    _dirty = true;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Дата выдачи карты'),
          subtitle: Text('${_issuedAt.day.toString().padLeft(2, '0')}.'
              '${_issuedAt.month.toString().padLeft(2, '0')}.'
              '${_issuedAt.year}'),
          trailing: OutlinedButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _issuedAt,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() {
                  _issuedAt = picked;
                  _dirty = true;
                });
              }
            },
            child: const Text('Выбрать'),
          ),
        ),
      ],
    );
  }
}
