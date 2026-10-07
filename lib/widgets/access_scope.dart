import 'package:flutter/material.dart';

import '../core/permissions.dart';
import '../models/role.dart';

/// Текущая роль. Если область не задана, считается администратор —
/// так устроена учебная сессия, которая входит как admin.
class AccessScope extends InheritedWidget {
  final ShopRole role;

  const AccessScope({super.key, required this.role, required super.child});

  static ShopRole roleOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AccessScope>();
    return scope?.role ?? ShopRole.admin;
  }

  @override
  bool updateShouldNotify(AccessScope oldWidget) => role != oldWidget.role;
}

/// Прячет дочерний виджет, если роли не хватает на операцию.
class RoleGate extends StatelessWidget {
  final AppOperation operation;
  final Widget child;

  const RoleGate({super.key, required this.operation, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!Permissions.can(AccessScope.roleOf(context), operation)) {
      return const SizedBox.shrink();
    }
    return child;
  }
}
