import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/breakpoints.dart';
import 'models/brand_query.dart';
import 'models/category_query.dart';
import 'models/customer_query.dart';
import 'models/product_query.dart';
import 'models/supplier_query.dart';
import 'screens/product_form_screen.dart';
import 'screens/product_list_screen.dart';
import 'sections/brands.dart' deferred as brands;
import 'sections/categories.dart' deferred as categories;
import 'sections/customers.dart' deferred as customers;
import 'sections/suppliers.dart' deferred as suppliers;
import 'widgets/deferred_page.dart';

final router = GoRouter(
  initialLocation: '/products',
  routes: [
    ShellRoute(
      builder:
          (context, state, child) =>
              AppShell(location: state.uri.path, child: child),
      routes: [
        GoRoute(
          path: '/products',
          builder: (context, state) {
            final q = state.uri.queryParameters;
            return ProductListScreen(
              initialQuery: ProductQuery(
                search: q['search'] ?? '',
                categoryId: int.tryParse(q['categoryId'] ?? ''),
                brandId: int.tryParse(q['brandId'] ?? ''),
                supplierId: int.tryParse(q['supplierId'] ?? ''),
                priceFrom: double.tryParse(q['priceFrom'] ?? ''),
                priceTo: double.tryParse(q['priceTo'] ?? ''),
                sortField: q['sort'] ?? 'name',
                sortAscending: q['asc'] != 'false',
                page: int.tryParse(q['page'] ?? '') ?? 1,
                size: int.tryParse(q['size'] ?? '') ?? 10,
                includeDeleted: q['includeDeleted'] == 'true',
              ),
            );
          },
          routes: [
            GoRoute(path: 'new', builder: (c, s) => const ProductFormScreen()),
            GoRoute(
              path: ':id/edit',
              builder:
                  (c, s) => ProductFormScreen(
                    id: int.tryParse(s.pathParameters['id'] ?? ''),
                  ),
            ),
          ],
        ),
        GoRoute(
          path: '/suppliers',
          builder: (context, state) {
            final q = state.uri.queryParameters;
            final query = SupplierQuery(
              search: q['search'] ?? '',
              country: q['country'],
              sortField: q['sort'] ?? 'name',
              sortAscending: q['asc'] != 'false',
              page: int.tryParse(q['page'] ?? '') ?? 1,
              size: int.tryParse(q['size'] ?? '') ?? 10,
              includeDeleted: q['includeDeleted'] == 'true',
            );
            return DeferredPage(
              loadLibrary: suppliers.loadLibrary,
              builder: (_) => suppliers.SupplierListScreen(initialQuery: query),
            );
          },
          routes: [
            GoRoute(
              path: 'new',
              builder:
                  (c, s) => DeferredPage(
                    loadLibrary: suppliers.loadLibrary,
                    builder: (_) => suppliers.SupplierFormScreen(),
                  ),
            ),
            GoRoute(
              path: ':id/edit',
              builder:
                  (c, s) => DeferredPage(
                    loadLibrary: suppliers.loadLibrary,
                    builder:
                        (_) => suppliers.SupplierFormScreen(
                          id: int.tryParse(s.pathParameters['id'] ?? ''),
                        ),
                  ),
            ),
          ],
        ),
        GoRoute(
          path: '/brands',
          builder: (context, state) {
            final q = state.uri.queryParameters;
            final query = BrandQuery(
              search: q['search'] ?? '',
              sortField: q['sort'] ?? 'name',
              sortAscending: q['asc'] != 'false',
              page: int.tryParse(q['page'] ?? '') ?? 1,
              size: int.tryParse(q['size'] ?? '') ?? 10,
              includeDeleted: q['includeDeleted'] == 'true',
            );
            return DeferredPage(
              loadLibrary: brands.loadLibrary,
              builder: (_) => brands.BrandListScreen(initialQuery: query),
            );
          },
          routes: [
            GoRoute(
              path: 'new',
              builder:
                  (c, s) => DeferredPage(
                    loadLibrary: brands.loadLibrary,
                    builder: (_) => brands.BrandFormScreen(),
                  ),
            ),
            GoRoute(
              path: ':id/edit',
              builder:
                  (c, s) => DeferredPage(
                    loadLibrary: brands.loadLibrary,
                    builder:
                        (_) => brands.BrandFormScreen(
                          id: int.tryParse(s.pathParameters['id'] ?? ''),
                        ),
                  ),
            ),
          ],
        ),
        GoRoute(
          path: '/categories',
          builder: (context, state) {
            final q = state.uri.queryParameters;
            final query = CategoryQuery(
              search: q['search'] ?? '',
              page: int.tryParse(q['page'] ?? '') ?? 1,
              size: int.tryParse(q['size'] ?? '') ?? 10,
              includeDeleted: q['includeDeleted'] == 'true',
            );
            return DeferredPage(
              loadLibrary: categories.loadLibrary,
              builder:
                  (_) => categories.CategoryListScreen(initialQuery: query),
            );
          },
          routes: [
            GoRoute(
              path: 'new',
              builder:
                  (c, s) => DeferredPage(
                    loadLibrary: categories.loadLibrary,
                    builder: (_) => categories.CategoryFormScreen(),
                  ),
            ),
            GoRoute(
              path: ':id/edit',
              builder:
                  (c, s) => DeferredPage(
                    loadLibrary: categories.loadLibrary,
                    builder:
                        (_) => categories.CategoryFormScreen(
                          id: int.tryParse(s.pathParameters['id'] ?? ''),
                        ),
                  ),
            ),
          ],
        ),
        GoRoute(
          path: '/customers',
          builder: (context, state) {
            final q = state.uri.queryParameters;
            final query = CustomerQuery(
              search: q['search'] ?? '',
              cardLevel: q['level'],
              sortField: q['sort'] ?? 'fullName',
              sortAscending: q['asc'] != 'false',
              page: int.tryParse(q['page'] ?? '') ?? 1,
              size: int.tryParse(q['size'] ?? '') ?? 10,
              includeDeleted: q['includeDeleted'] == 'true',
            );
            return DeferredPage(
              loadLibrary: customers.loadLibrary,
              builder: (_) => customers.CustomerListScreen(initialQuery: query),
            );
          },
          routes: [
            GoRoute(
              path: 'new',
              builder:
                  (c, s) => DeferredPage(
                    loadLibrary: customers.loadLibrary,
                    builder: (_) => customers.CustomerFormScreen(),
                  ),
            ),
            GoRoute(
              path: ':id/edit',
              builder:
                  (c, s) => DeferredPage(
                    loadLibrary: customers.loadLibrary,
                    builder:
                        (_) => customers.CustomerFormScreen(
                          id: int.tryParse(s.pathParameters['id'] ?? ''),
                        ),
                  ),
            ),
          ],
        ),
      ],
    ),
  ],
);

class AppShell extends StatelessWidget {
  final String location;
  final Widget child;

  const AppShell({super.key, required this.location, required this.child});

  int get _index {
    if (location.startsWith('/suppliers')) return 1;
    if (location.startsWith('/brands')) return 2;
    if (location.startsWith('/categories')) return 3;
    if (location.startsWith('/customers')) return 4;
    return 0;
  }

  void _go(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/products');
      case 1:
        context.go('/suppliers');
      case 2:
        context.go('/brands');
      case 3:
        context.go('/categories');
      case 4:
        context.go('/customers');
    }
  }

  static final _destinations = [
    NavigationRailDestination(
      icon: Tooltip(message: 'Товары', child: Icon(Icons.inventory_2_outlined)),
      selectedIcon: Icon(Icons.inventory_2),
      label: Text('Товары'),
    ),
    NavigationRailDestination(
      icon: Tooltip(
        message: 'Поставщики',
        child: Icon(Icons.business_outlined),
      ),
      selectedIcon: Icon(Icons.business),
      label: Text('Поставщики'),
    ),
    NavigationRailDestination(
      icon: Tooltip(message: 'Бренды', child: Icon(Icons.sell_outlined)),
      selectedIcon: Icon(Icons.sell),
      label: Text('Бренды'),
    ),
    NavigationRailDestination(
      icon: Tooltip(message: 'Категории', child: Icon(Icons.category_outlined)),
      selectedIcon: Icon(Icons.category),
      label: Text('Категории'),
    ),
    NavigationRailDestination(
      icon: Tooltip(message: 'Клиенты', child: Icon(Icons.people_outline)),
      selectedIcon: Icon(Icons.people),
      label: Text('Клиенты'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final phone = width < Breakpoints.phone;
    final desktop = width >= Breakpoints.desktop;

    final page = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Breakpoints.contentMax),
        child: child,
      ),
    );

    return Scaffold(
      body: Row(
        children: [
          if (!phone)
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => _go(context, i),
              extended: desktop,
              labelType: NavigationRailLabelType.none,
              leading: Padding(
                padding: EdgeInsets.symmetric(vertical: desktop ? 24 : 12),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: desktop ? 24 : 18,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(
                        Icons.pets,
                        size: desktop ? 28 : 20,
                        color: const Color(0xFF0F766E),
                        semanticLabel: 'ЗооМаг',
                      ),
                    ),
                    if (desktop) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'ЗооМаг',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              destinations: _destinations,
            ),
          if (!phone) const VerticalDivider(width: 1),
          Expanded(child: page),
        ],
      ),
      bottomNavigationBar:
          phone
              ? NavigationBar(
                selectedIndex: _index,
                onDestinationSelected: (i) => _go(context, i),
                labelBehavior:
                    NavigationDestinationLabelBehavior.onlyShowSelected,
                height: 64,
                destinations: [
                  NavigationDestination(
                    icon: Tooltip(
                      message: 'Товары',
                      child: Icon(Icons.inventory_2_outlined),
                    ),
                    label: 'Товары',
                  ),
                  NavigationDestination(
                    icon: Tooltip(
                      message: 'Поставщики',
                      child: Icon(Icons.business_outlined),
                    ),
                    label: 'Поставщики',
                  ),
                  NavigationDestination(
                    icon: Tooltip(
                      message: 'Бренды',
                      child: Icon(Icons.sell_outlined),
                    ),
                    label: 'Бренды',
                  ),
                  NavigationDestination(
                    icon: Tooltip(
                      message: 'Категории',
                      child: Icon(Icons.category_outlined),
                    ),
                    label: 'Категории',
                  ),
                  NavigationDestination(
                    icon: Tooltip(
                      message: 'Клиенты',
                      child: Icon(Icons.people_outline),
                    ),
                    label: 'Клиенты',
                  ),
                ],
              )
              : null,
    );
  }
}
