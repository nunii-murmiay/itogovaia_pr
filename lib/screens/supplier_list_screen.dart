import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/supplier.dart';
import '../models/supplier_query.dart';
import '../state/product_list_notifier.dart';
import '../state/supplier_list_notifier.dart';
import '../widgets/entity_table.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/search_filter_bar.dart';
import '../widgets/supplier_card.dart';

class SupplierListScreen extends StatefulWidget {
  final SupplierQuery initialQuery;

  const SupplierListScreen({
    super.key,
    required this.initialQuery,
  });

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = context.read<SupplierListNotifier>();
      notifier.applyQuery(widget.initialQuery);
    });
  }

  @override
  void didUpdateWidget(covariant SupplierListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialQuery != widget.initialQuery) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<SupplierListNotifier>().applyQuery(widget.initialQuery);
      });
    }
  }

  void _updateUrl(SupplierQuery q) {
    final params = <String, String>{};
    if (q.search.isNotEmpty) params['search'] = q.search;
    if (q.country != null && q.country!.isNotEmpty) params['country'] = q.country!;
    if (q.sortField != 'name') params['sort'] = q.sortField;
    if (!q.sortAscending) params['asc'] = 'false';
    if (q.page > 1) params['page'] = q.page.toString();
    if (q.size != 10) params['size'] = q.size.toString();
    if (q.includeDeleted) params['includeDeleted'] = 'true';

    final uri = Uri(path: '/suppliers', queryParameters: params.isEmpty ? null : params);
    context.go(uri.toString());
  }

  void _onQueryChanged(SupplierQuery next) {
    _updateUrl(next);
  }

  Future<void> _confirmBulkDelete(SupplierListNotifier notifier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Подтверждение удаления'),
        content: Text(
          'Вы действительно хотите перенести ${notifier.selected.length} выбранных поставщиков в удаленные?',
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
          const SnackBar(content: Text('Выбранные поставщики удалены')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<SupplierListNotifier>();
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.business, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text('Поставщики и Бренды', style: TextStyle(fontWeight: FontWeight.bold)),
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
        onPressed: () => context.go('/suppliers/new'),
        icon: const Icon(Icons.add_business),
        label: const Text('Добавить поставщика'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DebouncedSearchBar(
                    initialValue: notifier.query.search,
                    hintText: 'Поиск поставщика по названию, стране, email...',
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
              SupplierFilterPanel(
                query: notifier.query,
                onQueryChanged: _onQueryChanged,
                onReset: () {
                  _onQueryChanged(const SupplierQuery());
                },
              ),
            ],

            if (notifier.hasSelection) ...[
              const SizedBox(height: 12),
              Container(
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

            Expanded(
              child: _buildContentState(context, notifier, isMobile),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentState(BuildContext context, SupplierListNotifier notifier, bool isMobile) {
    if (notifier.status == LoadStatus.loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Загрузка поставщиков...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

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
                  'Произошла ошибка при загрузке поставщиков',
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
                  Icons.business_center_outlined,
                  size: 72,
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Поставщики не найдены',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'По вашему запросу поставщики не найдены.\nПопробуйте изменить условия поиска.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => _onQueryChanged(const SupplierQuery()),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Сбросить все фильтры'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final items = notifier.result.items;

    return Column(
      children: [
        Expanded(
          child: isMobile
              ? ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return SupplierCard(
                      supplier: item,
                      isSelected: notifier.selected.contains(item.id),
                      onToggleSelect: notifier.toggleSelection,
                      onEdit: () => context.go('/suppliers/${item.id}'),
                      onDelete: () => notifier.softDelete(item.id),
                      onRestore: () => notifier.restore(item.id),
                    );
                  },
                )
              : EntityTable<Supplier>(
                  items: items,
                  idOf: (s) => s.id,
                  selected: notifier.selected,
                  onToggleSelect: notifier.toggleSelection,
                  onToggleSelectAll: () {
                    notifier.toggleSelectAll(items.map((s) => s.id).toList());
                  },
                  sortField: notifier.query.sortField,
                  sortAscending: notifier.query.sortAscending,
                  isDeletedOf: (s) => s.isDeleted,
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
                      label: 'Компания / Бренд',
                      sortField: 'name',
                      build: (s) => Text(
                        s.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: s.isDeleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    TableColumnSpec(
                      label: 'Страна',
                      sortField: 'country',
                      build: (s) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.flag_outlined, size: 14, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(s.country),
                        ],
                      ),
                    ),
                    TableColumnSpec(
                      label: 'Контактное лицо',
                      sortField: 'contactPerson',
                      build: (s) => Text(s.contactPerson),
                    ),
                    TableColumnSpec(
                      label: 'Телефон',
                      build: (s) => Text(s.phone, style: const TextStyle(fontFamily: 'monospace')),
                    ),
                    TableColumnSpec(
                      label: 'Email',
                      build: (s) => Text(s.email, style: const TextStyle(color: Colors.blue)),
                    ),
                    TableColumnSpec(
                      label: 'Рейтинг',
                      sortField: 'rating',
                      numeric: true,
                      build: (s) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text('${s.rating}'),
                        ],
                      ),
                    ),
                  ],
                  actions: (s) => [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Редактировать',
                      onPressed: () => context.go('/suppliers/${s.id}'),
                    ),
                    if (s.isDeleted) ...[
                      IconButton(
                        icon: const Icon(Icons.restore_from_trash, size: 18),
                        tooltip: 'Восстановить',
                        color: Colors.green,
                        onPressed: () => notifier.restore(s.id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever, size: 18),
                        tooltip: 'Удалить навсегда',
                        color: Colors.red,
                        onPressed: () => notifier.hardDelete(s.id),
                      ),
                    ] else
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        tooltip: 'Удалить',
                        color: Theme.of(context).colorScheme.error,
                        onPressed: () => notifier.softDelete(s.id),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 16),

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
