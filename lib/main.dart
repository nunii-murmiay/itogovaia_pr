import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'core/api_client.dart';
import 'core/auth_session.dart';
import 'core/catalog_cache.dart';
import 'repositories/api_brand_repository.dart';
import 'repositories/api_category_repository.dart';
import 'repositories/api_customer_repository.dart'
    show ApiCustomerRepository, ApiSalesRepository;
import 'repositories/api_product_repository.dart';
import 'repositories/api_supplier_repository.dart';
import 'repositories/brand_repository.dart';
import 'repositories/category_repository.dart';
import 'repositories/customer_repository.dart';
import 'repositories/product_repository.dart';
import 'repositories/supplier_repository.dart';
import 'models/role.dart';
import 'router.dart';
import 'widgets/access_scope.dart';
import 'state/brand_list_notifier.dart';
import 'state/category_list_notifier.dart';
import 'state/customer_list_notifier.dart';
import 'state/product_list_notifier.dart';
import 'state/supplier_list_notifier.dart';

final GlobalKey<ScaffoldMessengerState> rootMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  runApp(const PetShopApp());
}

class PetShopApp extends StatelessWidget {
  const PetShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    late final AuthSession session;
    final dio = buildDio(tokenProvider: () => session.accessToken);
    session = AuthSession(dio);

    final productRepo = ApiProductRepository(dio, session);
    final supplierRepo = ApiSupplierRepository(dio, session);
    final brandRepo = ApiBrandRepository(dio, session);
    final categoryRepo = ApiCategoryRepository(dio, session);
    final customerRepo = ApiCustomerRepository(dio, session);
    final salesRepo = ApiSalesRepository(dio, session);
    final catalog = CatalogCache(
      brands: brandRepo,
      categories: categoryRepo,
      suppliers: supplierRepo,
    );

    return MultiProvider(
      providers: [
        Provider<Dio>.value(value: dio),
        Provider<AuthSession>.value(value: session),
        Provider<ProductRepository>.value(value: productRepo),
        Provider<SupplierRepository>.value(value: supplierRepo),
        Provider<BrandRepository>.value(value: brandRepo),
        Provider<CategoryRepository>.value(value: categoryRepo),
        Provider<CustomerRepository>.value(value: customerRepo),
        Provider<ApiSalesRepository>.value(value: salesRepo),
        Provider<CatalogCache>.value(value: catalog),
        ChangeNotifierProvider(
          create: (_) => ProductListNotifier(productRepo)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => SupplierListNotifier(supplierRepo)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => BrandListNotifier(brandRepo)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoryListNotifier(categoryRepo)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => CustomerListNotifier(customerRepo)..load(),
        ),
      ],
      child: AccessScope(
        role: ShopRole.admin,
        child: MaterialApp.router(
          title: 'Зоомагазин «Лапки и Хвостики»',
          scaffoldMessengerKey: rootMessengerKey,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0F766E),
              primary: const Color(0xFF0F766E),
              secondary: const Color(0xFFD97706),
              brightness: Brightness.light,
            ),
            cardTheme: const CardTheme(elevation: 1, margin: EdgeInsets.zero),
            appBarTheme: const AppBarTheme(
              centerTitle: false,
              elevation: 0,
              scrolledUnderElevation: 2,
            ),
          ),
          routerConfig: router,
        ),
      ),
    );
  }
}
