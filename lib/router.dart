import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'models/brand_query.dart';
import 'models/category_query.dart';
import 'models/customer_query.dart';
import 'models/product_query.dart';
import 'models/supplier_query.dart';
import 'screens/brand_form_screen.dart';
import 'screens/brand_list_screen.dart';
import 'screens/category_form_screen.dart';
import 'screens/category_list_screen.dart';
import 'screens/customer_form_screen.dart';
import 'screens/customer_list_screen.dart';
import 'screens/product_form_screen.dart';
import 'screens/product_list_screen.dart';
import 'screens/supplier_form_screen.dart';
import 'screens/supplier_list_screen.dart';

final router = GoRouter(
  initialLocation: '/products',
  routes: [
    ShellRoute(
      builder: (context, state, child) =>
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
            GoRoute(
              path: 'new',
              builder: (c, s) => const ProductFormScreen(),
            ),
            GoRoute(
              path: ':id/edit',
              builder: (c, s) => ProductFormScreen(
                id: int.tryParse(s.pathParameters['id'] ?? ''),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/suppliers',
          builder: (context, state) {
            final q = state.uri.queryParameters;
            return SupplierListScreen(
              initialQuery: SupplierQuery(
                search: q['search'] ?? '',
                country: q['country'],
                sortField: q['sort'] ?? 'name',
                sortAscending: q['asc'] != 'false',
                page: int.tryParse(q['page'] ?? '') ?? 1,
                size: int.tryParse(q['size'] ?? '') ?? 10,
                includeDeleted: q['includeDeleted'] == 'true',
              ),
            );
          },
          routes: [
            GoRoute(path: 'new', builder: (c, s) => const SupplierFormScreen()),
            GoRoute(
              path: ':id/edit',
              builder: (c, s) => SupplierFormScreen(
                id: int.tryParse(s.pathParameters['id'] ?? ''),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/brands',
          builder: (context, state) {
            final q = state.uri.queryParameters;
            return BrandListScreen(
              initialQuery: BrandQuery(
                search: q['search'] ?? '',
                sortField: q['sort'] ?? 'name',
                sortAscending: q['asc'] != 'false',
                page: int.tryParse(q['page'] ?? '') ?? 1,
                size: int.tryParse(q['size'] ?? '') ?? 10,
                includeDeleted: q['includeDeleted'] == 'true',
              ),
            );
          },
          routes: [
            GoRoute(path: 'new', builder: (c, s) => const BrandFormScreen()),
            GoRoute(
              path: ':id/edit',
              builder: (c, s) => BrandFormScreen(
                id: int.tryParse(s.pathParameters['id'] ?? ''),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/categories',
          builder: (context, state) {
            final q = state.uri.queryParameters;
            return CategoryListScreen(
              initialQuery: CategoryQuery(
                search: q['search'] ?? '',
                page: int.tryParse(q['page'] ?? '') ?? 1,
                size: int.tryParse(q['size'] ?? '') ?? 10,
                includeDeleted: q['includeDeleted'] == 'true',
              ),
            );
          },
          routes: [
            GoRoute(path: 'new', builder: (c, s) => const CategoryFormScreen()),
            GoRoute(
              path: ':id/edit',
              builder: (c, s) => CategoryFormScreen(
                id: int.tryParse(s.pathParameters['id'] ?? ''),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/customers',
          builder: (context, state) {
            final q = state.uri.queryParameters;
            return CustomerListScreen(
              initialQuery: CustomerQuery(
                search: q['search'] ?? '',
                cardLevel: q['level'],
                sortField: q['sort'] ?? 'fullName',
                sortAscending: q['asc'] != 'false',
                page: int.tryParse(q['page'] ?? '') ?? 1,
                size: int.tryParse(q['size'] ?? '') ?? 10,
                includeDeleted: q['includeDeleted'] == 'true',
              ),
            );
          },
          routes: [
            GoRoute(path: 'new', builder: (c, s) => const CustomerFormScreen()),
            GoRoute(
              path: ':id/edit',
              builder: (c, s) => CustomerFormScreen(
                id: int.tryParse(s.pathParameters['id'] ?? ''),
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

  static const _destinations = [
    NavigationRailDestination(
      icon: Icon(Icons.inventory_2_outlined),
      selectedIcon: Icon(Icons.inventory_2),
      label: Text('Товары'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.business_outlined),
      selectedIcon: Icon(Icons.business),
      label: Text('Поставщики'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.sell_outlined),
      selectedIcon: Icon(Icons.sell),
      label: Text('Бренды'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.category_outlined),
      selectedIcon: Icon(Icons.category),
      label: Text('Категории'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.people_outline),
      selectedIcon: Icon(Icons.people),
      label: Text('Клиенты'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;
    final isNarrow = width < 600;

    return Scaffold(
      body: Row(
        children: [
          if (isWide)
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => _go(context, i),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: const Icon(Icons.pets, size: 28, color: Color(0xFF0F766E)),
                    ),
                    const SizedBox(height: 8),
                    const Text('ЗооМаг', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
              destinations: _destinations,
            ),
          if (isWide) const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => _go(context, i),
              labelBehavior: isNarrow
                  ? NavigationDestinationLabelBehavior.onlyShowSelected
                  : NavigationDestinationLabelBehavior.alwaysShow,
              height: isNarrow ? 64 : 80,
              destinations: const [
                NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Товары'),
                NavigationDestination(icon: Icon(Icons.business_outlined), label: 'Поставщики'),
                NavigationDestination(icon: Icon(Icons.sell_outlined), label: 'Бренды'),
                NavigationDestination(icon: Icon(Icons.category_outlined), label: 'Категории'),
                NavigationDestination(icon: Icon(Icons.people_outline), label: 'Клиенты'),
              ],
            ),
    );
  }
}
