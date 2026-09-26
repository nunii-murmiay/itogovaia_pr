import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'repositories/in_memory_product_repository.dart';
import 'repositories/in_memory_supplier_repository.dart';
import 'repositories/product_repository.dart';
import 'repositories/supplier_repository.dart';
import 'router.dart';
import 'state/product_list_notifier.dart';
import 'state/supplier_list_notifier.dart';

void main() {
  usePathUrlStrategy();
  runApp(const PetShopApp());
}

class PetShopApp extends StatelessWidget {
  const PetShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Repositories (DI Layer)
        Provider<ProductRepository>(
          create: (_) => InMemoryProductRepository(),
        ),
        Provider<SupplierRepository>(
          create: (_) => InMemorySupplierRepository(),
        ),

        // State Notifiers (State Layer)
        ChangeNotifierProvider(
          create: (context) => ProductListNotifier(context.read<ProductRepository>())..load(),
        ),
        ChangeNotifierProvider(
          create: (context) => SupplierListNotifier(context.read<SupplierRepository>())..load(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Зоомагазин «Лапки и Хвостики»',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0F766E), // Emerald Green
            primary: const Color(0xFF0F766E),
            secondary: const Color(0xFFD97706), // Amber
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
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0F766E),
            brightness: Brightness.dark,
          ),
        ),
        themeMode: ThemeMode.light,
        routerConfig: router,
      ),
    );
  }
}
