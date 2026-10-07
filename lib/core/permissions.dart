import '../models/role.dart';

/// Операции интерфейса зоомагазина.
enum AppOperation {
  viewCatalog,
  manageCatalog,
  manageCustomers,
  createSale,
  hardDelete,
  restoreDeleted,
}

class Permissions {
  const Permissions._();

  static bool can(ShopRole role, AppOperation op) {
    return switch (op) {
      AppOperation.viewCatalog => true,
      AppOperation.manageCatalog => role.atLeast(ShopRole.manager),
      AppOperation.manageCustomers => role.atLeast(ShopRole.manager),
      AppOperation.createSale => role.atLeast(ShopRole.manager),
      AppOperation.hardDelete => role == ShopRole.admin,
      AppOperation.restoreDeleted => role == ShopRole.admin,
    };
  }

  /// Куда отправить пользователя, если маршрут ему недоступен.
  /// `null` — можно оставаться на месте.
  static String? redirectForPath({
    required String path,
    required bool authenticated,
    required ShopRole? role,
  }) {
    if (!authenticated) {
      if (path.startsWith('/login')) return null;
      final from = Uri.encodeComponent(path);
      return '/login?from=$from';
    }

    if (path.startsWith('/login')) return '/products';

    final needsManager =
        path.startsWith('/customers') ||
        path.startsWith('/suppliers') ||
        path.startsWith('/brands') ||
        path.startsWith('/categories') ||
        path.contains('/new') ||
        path.contains('/edit');
    if (needsManager && (role == null || !role.atLeast(ShopRole.manager))) {
      return '/denied';
    }
    return null;
  }
}
