import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'models/product_query.dart';
import 'models/supplier_query.dart';
import 'screens/product_detail_screen.dart';
import 'screens/product_list_screen.dart';
import 'screens/supplier_detail_screen.dart';
import 'screens/supplier_list_screen.dart';

final router = GoRouter(
  initialLocation: '/products',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return AppShell(location: state.uri.path, child: child);
      },
      routes: [
        GoRoute(
          path: '/products',
          builder: (context, state) {
            final query = ProductQuery(
              search: state.uri.queryParameters['search'] ?? '',
              categoryId: int.tryParse(state.uri.queryParameters['categoryId'] ?? ''),
              supplierId: int.tryParse(state.uri.queryParameters['supplierId'] ?? ''),
              priceFrom: double.tryParse(state.uri.queryParameters['priceFrom'] ?? ''),
              priceTo: double.tryParse(state.uri.queryParameters['priceTo'] ?? ''),
              sortField: state.uri.queryParameters['sort'] ?? 'name',
              sortAscending: state.uri.queryParameters['asc'] != 'false',
              page: int.tryParse(state.uri.queryParameters['page'] ?? '') ?? 1,
              size: int.tryParse(state.uri.queryParameters['size'] ?? '') ?? 10,
              includeDeleted: state.uri.queryParameters['includeDeleted'] == 'true',
            );
            return ProductListScreen(initialQuery: query);
          },
          routes: [
            GoRoute(
              path: 'new',
              builder: (context, state) => const ProductDetailScreen(),
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = int.tryParse(state.pathParameters['id'] ?? '');
                return ProductDetailScreen(productId: id);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/suppliers',
          builder: (context, state) {
            final query = SupplierQuery(
              search: state.uri.queryParameters['search'] ?? '',
              country: state.uri.queryParameters['country'],
              sortField: state.uri.queryParameters['sort'] ?? 'name',
              sortAscending: state.uri.queryParameters['asc'] != 'false',
              page: int.tryParse(state.uri.queryParameters['page'] ?? '') ?? 1,
              size: int.tryParse(state.uri.queryParameters['size'] ?? '') ?? 10,
              includeDeleted: state.uri.queryParameters['includeDeleted'] == 'true',
            );
            return SupplierListScreen(initialQuery: query);
          },
          routes: [
            GoRoute(
              path: 'new',
              builder: (context, state) => const SupplierDetailScreen(),
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = int.tryParse(state.pathParameters['id'] ?? '');
                return SupplierDetailScreen(supplierId: id);
              },
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

  const AppShell({
    super.key,
    required this.location,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      body: Row(
        children: [
          if (isWide)
            NavigationRail(
              selectedIndex: location.startsWith('/suppliers') ? 1 : 0,
              onDestinationSelected: (index) {
                if (index == 0) context.go('/products');
                if (index == 1) context.go('/suppliers');
              },
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
                    const Text(
                      'ЗооМаг',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
              destinations: const [
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
              ],
            ),
          if (isWide) const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : BottomNavigationBar(
              currentIndex: location.startsWith('/suppliers') ? 1 : 0,
              onTap: (index) {
                if (index == 0) context.go('/products');
                if (index == 1) context.go('/suppliers');
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.inventory_2_outlined),
                  activeIcon: Icon(Icons.inventory_2),
                  label: 'Товары',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.business_outlined),
                  activeIcon: Icon(Icons.business),
                  label: 'Поставщики',
                ),
              ],
            ),
    );
  }
}
