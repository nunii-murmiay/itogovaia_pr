import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'repositories/brand_repository.dart';
import 'repositories/category_repository.dart';
import 'repositories/customer_repository.dart';
import 'repositories/persistent_brand_repository.dart';
import 'repositories/persistent_category_repository.dart';
import 'repositories/persistent_customer_repository.dart';
import 'repositories/persistent_product_repository.dart';
import 'repositories/persistent_supplier_repository.dart';
import 'repositories/product_repository.dart';
import 'repositories/supplier_repository.dart';
import 'router.dart';
import 'state/brand_list_notifier.dart';
import 'state/category_list_notifier.dart';
import 'state/customer_list_notifier.dart';
import 'state/product_list_notifier.dart';
import 'state/supplier_list_notifier.dart';

final GlobalKey<ScaffoldMessengerState> rootMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  final prefs = await SharedPreferences.getInstance();

  void notice(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      rootMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
      );
    });
  }

  runApp(PetShopApp(prefs: prefs, onStorageNotice: notice));
}

class PetShopApp extends StatelessWidget {
  final SharedPreferences prefs;
  final void Function(String message) onStorageNotice;

  const PetShopApp({
    super.key,
    required this.prefs,
    required this.onStorageNotice,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ProductRepository>(
          create: (_) => PersistentProductRepository(prefs, onStorageNotice: onStorageNotice),
        ),
        Provider<SupplierRepository>(
          create: (_) => PersistentSupplierRepository(prefs, onStorageNotice: onStorageNotice),
        ),
        Provider<BrandRepository>(
          create: (_) => PersistentBrandRepository(prefs, onStorageNotice: onStorageNotice),
        ),
        Provider<CategoryRepository>(
          create: (_) => PersistentCategoryRepository(prefs, onStorageNotice: onStorageNotice),
        ),
        Provider<CustomerRepository>(
          create: (_) => PersistentCustomerRepository(prefs, onStorageNotice: onStorageNotice),
        ),
        ChangeNotifierProvider(
          create: (c) => ProductListNotifier(c.read<ProductRepository>())..load(),
        ),
        ChangeNotifierProvider(
          create: (c) => SupplierListNotifier(c.read<SupplierRepository>())..load(),
        ),
        ChangeNotifierProvider(
          create: (c) => BrandListNotifier(c.read<BrandRepository>())..load(),
        ),
        ChangeNotifierProvider(
          create: (c) => CategoryListNotifier(c.read<CategoryRepository>())..load(),
        ),
        ChangeNotifierProvider(
          create: (c) => CustomerListNotifier(c.read<CustomerRepository>())..load(),
        ),
      ],
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
          cardTheme: const CardTheme(
            elevation: 1,
            margin: EdgeInsets.zero,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            elevation: 0,
            scrolledUnderElevation: 2,
          ),
        ),
        routerConfig: router,
      ),
    );
  }
}
