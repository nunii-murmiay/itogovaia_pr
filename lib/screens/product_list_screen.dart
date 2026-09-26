import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/product_query.dart';
import '../models/seed_data.dart';
import '../models/supplier.dart';
import '../state/product_list_notifier.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/product_card.dart';
import '../widgets/search_filter_bar.dart';

class ProductListScreen extends StatefulWidget {
  final ProductQuery initialQuery;

  const ProductListScreen({
    super.key,
    required this.initialQuery,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = context.read<ProductListNotifier>();
      notifier.applyQuery(widget.initialQuery);
    });
  }

  @override
  void didUpdateWidget(covariant ProductListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialQuery != widget.initialQuery) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ProductListNotifier>().applyQuery(widget.initialQuery);
      });
    }
  }

  void _updateUrl(ProductQuery q) {
    final params = <String, String>{};
    if (q.search.isNotEmpty) params['search'] = q.search;
    if (q.categoryId != null) params['categoryId'] = q.categoryId.toString();
    if (q.supplierId != null) params['supplierId'] = q.supplierId.toString();
    if (q.priceFrom != null) params['priceFrom'] = q.priceFrom.toString();
    if (q.priceTo != null) params['priceTo'] = q.priceTo.toString();
    if (q.sortField != 'name') params['sort'] = q.sortField;
    if (!q.sortAscending) params['asc'] = 'false';
    if (q.page > 1) params['page'] = q.page.toString();
    if (q.size != 10) params['size'] = q.size.toString();
    if (q.includeDeleted) params['includeDeleted'] = 'true';

    final uri = Uri(path: '/products', queryParameters: params.isEmpty ? null : params);
    context.go(uri.toString());
  }

  void _onQueryChanged(ProductQuery next) {
    _updateUrl(next);
  }

  Future<void> _confirmBulkDelete(ProductListNotifier notifier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Подтверждение удаления'),
        content: Text(
          'Вы действительно хотите перенести ${notifier.selected.length} выбранных товаров в удаленные?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete),
            label: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await notifier.deleteSelected();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Выбранные товары успешно удалены')),
        );
      }
    }
  }

  Future<void> _confirmHardDelete(ProductListNotifier notifier, Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Окончательное удаление'),
        content: Text(
          'Вы действительно хотите безвозвратно удалить "${product.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить навсегда'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await notifier.hardDelete(product.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Товар "${product.name}" удален навсегда')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ProductListNotifier>();
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.pets, color: Color(0xFF0F766E)),
            SizedBox(width: 8),
            Text('Каталог товаров', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            tooltip: 'Фильтры',
            onPressed: () => setState(() => _showFilters = !_showFilters),
          ),
          IconButton(
            icon: const Icon(Icons.warning_amber),
            tooltip: 'Имитация ошибки (для проверки)',
            onPressed: () => notifier.simulateError(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить',
            onPressed: () => notifier.load(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/products/new'),
        icon: const Icon(Icons.add),
        label: const Text('Добавить товар'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search and Filter Header
            Row(
              children: [
                Expanded(
                  child: DebouncedSearchBar(
                    initialValue: notifier.query.search,
                    hintText: 'Поиск по названию или артикулу (PET-...)...',
                    onChanged: (text) {
                      _onQueryChanged(notifier.query.copyWith(search: text));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => setState(() => _showFilters = !_showFilters),
                  icon: Icon(_showFilters ? Icons.expand_less : Icons.expand_more),
                  label: Text(_showFilters ? 'Скрыть фильтры' : 'Фильтры'),
                ),
              ],
            ),

            if (_showFilters) ...[
              const SizedBox(height: 12),
              ProductFilterPanel(
                query: notifier.query,
                onQueryChanged: _onQueryChanged,
                onReset: () {
                  _onQueryChanged(const ProductQuery());
                },
              ),
            ],

            // Multi-selection bar
            if (notifier.hasSelection) ...[
              const SizedBox(height: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_box, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      'Выбрано элементов: ${notifier.selected.length}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const Spacer(),
                    if (notifier.query.includeDeleted)
                      TextButton.icon(
                        onPressed: () => notifier.restoreSelected(),
                        icon: const Icon(Icons.restore),
                        label: const Text('Восстановить выбранные'),
                      ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                      ),
                      onPressed: () => _confirmBulkDelete(notifier),
                      icon: const Icon(Icons.delete),
                      label: const Text('Удалить выбранные'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => notifier.clearSelection(),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Content States
            Expanded(
              child: _buildContentState(context, notifier, isMobile),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentState(BuildContext context, ProductListNotifier notifier, bool isMobile) {
    // State 1: Loading
    if (notifier.status == LoadStatus.loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Загрузка каталога зоомагазина...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // State 2: Error
    if (notifier.status == LoadStatus.error) {
      return Center(
        child: Card(
          color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                const Text(
                  'Произошла ошибка при загрузке данных',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  notifier.error ?? 'Неизвестная ошибка',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => notifier.load(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Повторить попытку'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // State 3: Empty Result
    if (notifier.result.items.isEmpty) {
      return Center(
        child: Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.search_off,
                  size: 72,
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Товары не найдены',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'По вашему запросу и критериям фильтрации ничего не найдено.\nПопробуйте изменить условия поиска.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => _onQueryChanged(const ProductQuery()),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Сбросить все фильтры'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // State 4: Success Result (Table or Cards view)
    final items = notifier.result.items;

    return Column(
      children: [
        Expanded(
          child: isMobile
              ? ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final supplier = seedSuppliers.firstWhere(
                      (s) => s.id == item.supplierId,
                      orElse: () => const Supplier(
                        id: 0,
                        name: 'Неизвестно',
                        country: '',
                        contactPerson: '',
                        phone: '',
                        email: '',
                        rating: 0,
                      ),
                    );

                    return ProductCard(
                      product: item,
                      supplierName: supplier.name,
                      isSelected: notifier.selected.contains(item.id),
                      onToggleSelect: notifier.toggleSelection,
                      onEdit: () => context.go('/products/${item.id}'),
                      onDelete: () => notifier.softDelete(item.id),
                      onRestore: () => notifier.restore(item.id),
                    );
                  },
                )
              : EntityTable<Product>(
                  items: items,
                  idOf: (p) => p.id,
                  selected: notifier.selected,
                  onToggleSelect: notifier.toggleSelection,
                  onToggleSelectAll: () {
                    notifier.toggleSelectAll(items.map((p) => p.id).toList());
                  },
                  sortField: notifier.query.sortField,
                  sortAscending: notifier.query.sortAscending,
                  isDeletedOf: (p) => p.isDeleted,
                  onSort: (field) {
                    _onQueryChanged(
                      notifier.query.copyWith(
                        sortField: field,
                        sortAscending: field == notifier.query.sortField
                            ? !notifier.query.sortAscending
                            : true,
                      ),
                    );
                  },
                  columns: [
                    TableColumnSpec(
                      label: 'Артикул',
                      sortField: 'sku',
                      build: (p) => Text(
                        p.sku,
                        style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
                      ),
                    ),
                    TableColumnSpec(
                      label: 'Название товара',
                      sortField: 'name',
                      build: (p) => Text(
                        p.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          decoration: p.isDeleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    TableColumnSpec(
                      label: 'Категория',
                      build: (p) => Chip(
                        label: Text(ProductCategory.getName(p.categoryId), style: const TextStyle(fontSize: 11)),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    TableColumnSpec(
                      label: 'Поставщик',
                      build: (p) {
                        final supp = seedSuppliers.firstWhere(
                          (s) => s.id == p.supplierId,
                          orElse: () => const Supplier(
                            id: 0,
                            name: '-',
                            country: '',
                            contactPerson: '',
                            phone: '',
                            email: '',
                            rating: 0,
                          ),
                        );
                        return Text(supp.name);
                      },
                    ),
                    TableColumnSpec(
                      label: 'Цена, ₽',
                      sortField: 'price',
                      numeric: true,
                      build: (p) => Text(
                        '${p.price.toStringAsFixed(0)} ₽',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    TableColumnSpec(
                      label: 'Склад',
                      sortField: 'stock',
                      numeric: true,
                      build: (p) => Text(
                        '${p.stock} шт.',
                        style: TextStyle(
                          color: p.stock < 15 ? Colors.red : Colors.green[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TableColumnSpec(
                      label: 'Рейтинг',
                      sortField: 'rating',
                      numeric: true,
                      build: (p) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text('${p.rating}'),
                        ],
                      ),
                    ),
                  ],
                  actions: (p) => [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Редактировать',
                      onPressed: () => context.go('/products/${p.id}'),
                    ),
                    if (p.isDeleted) ...[
                      IconButton(
                        icon: const Icon(Icons.restore_from_trash, size: 18),
                        tooltip: 'Восстановить',
                        color: Colors.green,
                        onPressed: () => notifier.restore(p.id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever, size: 18),
                        tooltip: 'Удалить навсегда',
                        color: Colors.red,
                        onPressed: () => _confirmHardDelete(notifier, p),
                      ),
                    ] else
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        tooltip: 'В корзину (soft delete)',
                        color: Theme.of(context).colorScheme.error,
                        onPressed: () => notifier.softDelete(p.id),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 16),

        // Pagination Bar
        PaginationBar(
          page: notifier.result.page,
          size: notifier.result.size,
          totalPages: notifier.result.totalPages,
          totalItems: notifier.result.total,
          hasPrevious: notifier.result.hasPrevious,
          hasNext: notifier.result.hasNext,
          onPageChanged: (newPage) {
            _onQueryChanged(notifier.query.copyWith(page: newPage));
          },
          onSizeChanged: (newSize) {
            _onQueryChanged(notifier.query.copyWith(size: newSize, page: 1));
          },
        ),
      ],
    );
  }
}
