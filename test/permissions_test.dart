import 'package:flutter_application_1/core/permissions.dart';
import 'package:flutter_application_1/models/role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Права ролей зоомагазина', () {
    test('покупатель видит каталог, но не управляет им', () {
      expect(
        Permissions.can(ShopRole.customer, AppOperation.viewCatalog),
        isTrue,
      );
      expect(
        Permissions.can(ShopRole.customer, AppOperation.manageCatalog),
        isFalse,
      );
    });

    test('покупатель не оформляет продажу и не удаляет навсегда', () {
      expect(
        Permissions.can(ShopRole.customer, AppOperation.createSale),
        isFalse,
      );
      expect(
        Permissions.can(ShopRole.customer, AppOperation.hardDelete),
        isFalse,
      );
    });

    test('менеджер ведёт каталог и продаёт, но не стирает запись', () {
      expect(
        Permissions.can(ShopRole.manager, AppOperation.manageCatalog),
        isTrue,
      );
      expect(
        Permissions.can(ShopRole.manager, AppOperation.createSale),
        isTrue,
      );
      expect(
        Permissions.can(ShopRole.manager, AppOperation.hardDelete),
        isFalse,
      );
      expect(
        Permissions.can(ShopRole.manager, AppOperation.restoreDeleted),
        isFalse,
      );
    });

    test('только администратор удаляет навсегда и восстанавливает', () {
      expect(Permissions.can(ShopRole.admin, AppOperation.hardDelete), isTrue);
      expect(
        Permissions.can(ShopRole.admin, AppOperation.restoreDeleted),
        isTrue,
      );
      expect(
        Permissions.can(ShopRole.admin, AppOperation.manageCustomers),
        isTrue,
      );
    });

    test('гость уходит на вход с обратным адресом', () {
      expect(
        Permissions.redirectForPath(
          path: '/products',
          authenticated: false,
          role: null,
        ),
        '/login?from=%2Fproducts',
      );
    });

    test('покупатель не открывает форму клиента', () {
      expect(
        Permissions.redirectForPath(
          path: '/customers/new',
          authenticated: true,
          role: ShopRole.customer,
        ),
        '/denied',
      );
    });

    test('менеджер остаётся в каталоге брендов', () {
      expect(
        Permissions.redirectForPath(
          path: '/brands',
          authenticated: true,
          role: ShopRole.manager,
        ),
        isNull,
      );
    });
  });
}
