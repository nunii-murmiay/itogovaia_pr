import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/api_exceptions.dart';
import '../core/catalog_cache.dart';
import '../models/brand.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/product_query.dart';
import '../models/supplier.dart';
import '../repositories/api_customer_repository.dart';
import '../repositories/customer_repository.dart';
import '../state/product_list_notifier.dart';
import '../widgets/entity_table.dart';
import '../widgets/list_load_body.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/product_card.dart';
import '../widgets/responsive_chrome.dart';
import '../widgets/search_filter_bar.dart';

class ProductListScreen extends StatefulWidget {
  final ProductQuery initialQuery;
  const ProductListScreen({super.key, required this.initialQuery});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  bool _showFilters = false;
  List<Supplier> _suppliers = [];
  List<ProductCategory> _categories = [];
  List<Brand> _brands = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<ProductListNotifier>().applyQuery(widget.initialQuery);
      final cache = context.read<CatalogCache>();
      final suppliers = await cache.suppliers();
      final categories = await cache.categories();
      final brands = await cache.brands();
      if (mounted) {
        setState(() {
          _suppliers = suppliers;
          _categories = categories;
          _brands = brands;
        });
      }
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
    if (q.categoryId != null) params['categoryId'] = '${q.categoryId}';
    if (q.brandId != null) params['brandId'] = '${q.brandId}';
    if (q.supplierId != null) params['supplierId'] = '${q.supplierId}';
    if (q.priceFrom != null) params['priceFrom'] = '${q.priceFrom}';
    if (q.priceTo != null) params['priceTo'] = '${q.priceTo}';
    if (q.sortField != 'name') params['sort'] = q.sortField;
    if (!q.sortAscending) params['asc'] = 'false';
    if (q.page > 1) params['page'] = '${q.page}';
    if (q.size != 10) params['size'] = '${q.size}';
    if (q.includeDeleted) params['includeDeleted'] = 'true';
    context.go(
      Uri(path: '/products', queryParameters: params.isEmpty ? null : params)
          .toString(),
    );
  }

  String _supplierName(int id) =>
      _suppliers.where((s) => s.id == id).map((s) => s.name).firstOrNull ?? '—';

  String _categoriesLabel(Product p) {
    if (p.categoryNames.isNotEmpty) return p.categoryNames.join(', ');
    return p.categoryIds
        .map(
          (id) =>
              _categories
                  .where((c) => c.id == id)
                  .map((c) => c.name)
                  .firstOrNull ??
              '#$id',
        )
        .join(', ');
  }

  /// Демо конфликта 409: продажа при нулевом остатке.
  Future<void> _trySale(Product product) async {
    try {
      final customers = await context.read<CustomerRepository>().findAll();
      if (!mounted) return;
      if (customers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Нет клиентов для оформления продажи')),
        );
        return;
      }
      await context.read<ApiSalesRepository>().createSale(
            customerId: customers.first.id,
            productId: product.id,
            quantity: 1,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Продажа «${product.name}» оформлена')),
      );
      context.read<ProductListNotifier>().load();
    } on ConflictException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
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
            Text(
              'Каталог товаров',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить',
            onPressed: () => notifier.load(),
          ),
        ],
      ),
      floatingActionButton: ResponsiveAddButton(
        onPressed: () => context.go('/products/new'),
        label: 'Добавить товар',
      ),
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 8 : 16),
        child: Column(
          children: [
            ListToolbar(
              search: DebouncedSearchBar(
                initialValue: notifier.query.search,
                hintText: 'Поиск по названию или артикулу...',
                onChanged: (text) =>
                    _updateUrl(notifier.query.copyWith(search: text)),
              ),
              filtersOpen: _showFilters,
              onToggleFilters: () => setState(() => _showFilters = !_showFilters),
              filtersPanel: ProductFilterPanel(
                query: notifier.query,
                suppliers: _suppliers,
                categories: _categories,
                brands: _brands,
                onQueryChanged: _updateUrl,
                onReset: () => _updateUrl(const ProductQuery()),
              ),
            ),
            if (notifier.hasSelection) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text('Выбрано: ${notifier.selected.length}'),
                    const Spacer(),
                    if (notifier.query.includeDeleted)
                      TextButton(
                        onPressed: () => notifier.restoreSelected(),
                        child: const Text('Восстановить'),
                      ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                      ),
                      onPressed: () => notifier.deleteSelected(),
                      child: const Text('Удалить'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Expanded(child: _content(notifier, isMobile)),
          ],
        ),
      ),
    );
  }

  Widget _content(ProductListNotifier notifier, bool isMobile) {
    return ListLoadBody(
      status: notifier.status,
      error: notifier.error,
      isEmpty: notifier.result.items.isEmpty,
      emptyMessage: 'Товары не найдены',
      onRetry: () => notifier.load(),
      child: Builder(
        builder: (context) {
          final items = notifier.result.items;
          return Column(
            children: [
              Expanded(
                child: isMobile
                    ? ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final item = items[i];
                          return ProductCard(
                            product: item,
                            supplierName: _supplierName(item.supplierId),
                            isSelected: notifier.selected.contains(item.id),
                            onToggleSelect: notifier.toggleSelection,
                            onEdit: () =>
                                context.go('/products/${item.id}/edit'),
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
                        onToggleSelectAll: () => notifier
                            .toggleSelectAll(items.map((p) => p.id).toList()),
                        sortField: notifier.query.sortField,
                        sortAscending: notifier.query.sortAscending,
                        isDeletedOf: (p) => p.isDeleted,
                        onSort: (field) => _updateUrl(
                          notifier.query.copyWith(
                            sortField: field,
                            sortAscending: field == notifier.query.sortField
                                ? !notifier.query.sortAscending
                                : true,
                          ),
                        ),
                        columns: [
                          TableColumnSpec(
                            label: 'Артикул',
                            sortField: 'sku',
                            build: (p) => Text(p.sku),
                          ),
                          TableColumnSpec(
                            label: 'Название',
                            sortField: 'name',
                            build: (p) => Text(
                              p.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          TableColumnSpec(
                            label: 'Категории',
                            build: (p) => Text(_categoriesLabel(p)),
                          ),
                          TableColumnSpec(
                            label: 'Поставщик',
                            build: (p) => Text(
                              p.supplierName ?? _supplierName(p.supplierId),
                            ),
                          ),
                          TableColumnSpec(
                            label: 'Цена',
                            sortField: 'price',
                            numeric: true,
                            build: (p) =>
                                Text('${p.price.toStringAsFixed(0)} ₽'),
                          ),
                          TableColumnSpec(
                            label: 'Склад',
                            sortField: 'stock',
                            numeric: true,
                            build: (p) => Text('${p.stock}'),
                          ),
                        ],
                        actions: (p) => [
                          IconButton(
                            icon: const Icon(Icons.shopping_cart_outlined,
                                size: 18),
                            tooltip: 'Продать 1 шт. (демо 409)',
                            onPressed: () => _trySale(p),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () =>
                                context.go('/products/${p.id}/edit'),
                          ),
                          if (p.isDeleted)
                            IconButton(
                              icon: const Icon(Icons.restore, size: 18),
                              onPressed: () => notifier.restore(p.id),
                            )
                          else
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18),
                              onPressed: () => notifier.softDelete(p.id),
                            ),
                          if (p.isDeleted)
                            IconButton(
                              icon: const Icon(Icons.delete_forever, size: 18),
                              color: Colors.red,
                              onPressed: () => notifier.hardDelete(p.id),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              PaginationBar(
                page: notifier.result.page,
                size: notifier.result.size,
                totalPages: notifier.result.totalPages,
                totalItems: notifier.result.total,
                hasPrevious: notifier.result.hasPrevious,
                hasNext: notifier.result.hasNext,
                onPageChanged: (p) =>
                    _updateUrl(notifier.query.copyWith(page: p)),
                onSizeChanged: (s) =>
                    _updateUrl(notifier.query.copyWith(size: s, page: 1)),
              ),
            ],
          );
        },
      ),
    );
  }
}
