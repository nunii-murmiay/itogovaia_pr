import 'dart:async';
import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/product_query.dart';
import '../models/seed_data.dart';
import '../models/supplier_query.dart';

class DebouncedSearchBar extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;
  final String hintText;

  const DebouncedSearchBar({
    super.key,
    required this.initialValue,
    required this.onChanged,
    this.hintText = 'Поиск...',
  });

  @override
  State<DebouncedSearchBar> createState() => _DebouncedSearchBarState();
}

class _DebouncedSearchBarState extends State<DebouncedSearchBar> {
  late TextEditingController _controller;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant DebouncedSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        _controller.text != widget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onTextChange(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      widget.onChanged(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: _controller,
      onChanged: _onTextChange,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                  widget.onChanged('');
                },
              )
            : null,
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class ProductFilterPanel extends StatelessWidget {
  final ProductQuery query;
  final ValueChanged<ProductQuery> onQueryChanged;
  final VoidCallback onReset;

  const ProductFilterPanel({
    super.key,
    required this.query,
    required this.onQueryChanged,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.filter_list, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Фильтры поиска',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Сбросить все'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // 1. Категория
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<int?>(
                    value: query.categoryId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Категория',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Все категории', overflow: TextOverflow.ellipsis),
                      ),
                      ...ProductCategory.defaultCategories.map(
                        (c) => DropdownMenuItem<int?>(
                          value: c.id,
                          child: Text(c.name, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      onQueryChanged(query.copyWith(categoryId: val));
                    },
                  ),
                ),

                // 2. Поставщик / Бренд
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<int?>(
                    value: query.supplierId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Поставщик',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Все поставщики', overflow: TextOverflow.ellipsis),
                      ),
                      ...seedSuppliers.map(
                        (s) => DropdownMenuItem<int?>(
                          value: s.id,
                          child: Text(s.name, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      onQueryChanged(query.copyWith(supplierId: val));
                    },
                  ),
                ),

                // 3. Диапазон цен (от)
                SizedBox(
                  width: 140,
                  child: TextFormField(
                    initialValue: query.priceFrom?.toString() ?? '',
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Цена от, ₽',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      onQueryChanged(query.copyWith(priceFrom: parsed));
                    },
                  ),
                ),

                // 3. Диапазон цен (до)
                SizedBox(
                  width: 140,
                  child: TextFormField(
                    initialValue: query.priceTo?.toString() ?? '',
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Цена до, ₽',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      onQueryChanged(query.copyWith(priceTo: parsed));
                    },
                  ),
                ),

                // Переключатель "Показывать удаленные"
                FilterChip(
                  avatar: Icon(
                    query.includeDeleted ? Icons.visibility : Icons.visibility_off,
                    size: 16,
                  ),
                  label: const Text('Удаленные записи'),
                  selected: query.includeDeleted,
                  onSelected: (val) {
                    onQueryChanged(query.copyWith(includeDeleted: val));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SupplierFilterPanel extends StatelessWidget {
  final SupplierQuery query;
  final ValueChanged<SupplierQuery> onQueryChanged;
  final VoidCallback onReset;

  const SupplierFilterPanel({
    super.key,
    required this.query,
    required this.onQueryChanged,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final countries = ['Франция', 'США', 'Германия', 'Италия', 'Нидерланды', 'Россия', 'Бельгия'];

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.filter_list, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Фильтры поставщиков',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Сбросить все'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String?>(
                    value: query.country,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Страна',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Все страны', overflow: TextOverflow.ellipsis),
                      ),
                      ...countries.map(
                        (c) => DropdownMenuItem<String?>(
                          value: c,
                          child: Text(c, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      onQueryChanged(query.copyWith(country: val));
                    },
                  ),
                ),
                FilterChip(
                  avatar: Icon(
                    query.includeDeleted ? Icons.visibility : Icons.visibility_off,
                    size: 16,
                  ),
                  label: const Text('Удаленные поставщики'),
                  selected: query.includeDeleted,
                  onSelected: (val) {
                    onQueryChanged(query.copyWith(includeDeleted: val));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
