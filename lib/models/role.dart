/// Роли зоомагазина. На учебном сервере им соответствуют
/// учётки reader / librarian / admin.
enum ShopRole { customer, manager, admin }

extension ShopRoleRank on ShopRole {
  bool atLeast(ShopRole other) => index >= other.index;

  String get label => switch (this) {
    ShopRole.customer => 'Покупатель',
    ShopRole.manager => 'Менеджер',
    ShopRole.admin => 'Администратор',
  };
}
