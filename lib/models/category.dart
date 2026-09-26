class ProductCategory {
  final int id;
  final String name;
  final String iconName;

  const ProductCategory({
    required this.id,
    required this.name,
    required this.iconName,
  });

  static const List<ProductCategory> defaultCategories = [
    ProductCategory(id: 1, name: 'Корма и лакомства', iconName: 'pets'),
    ProductCategory(id: 2, name: 'Игрушки и развлечения', iconName: 'sports_esports'),
    ProductCategory(id: 3, name: 'Аквариумистика', iconName: 'set_meal'),
    ProductCategory(id: 4, name: 'Ветаптека и уход', iconName: 'medical_services'),
    ProductCategory(id: 5, name: 'Амуниция и клетки', iconName: 'home'),
  ];

  static String getName(int id) {
    return defaultCategories.firstWhere((c) => c.id == id, orElse: () => ProductCategory(id: id, name: 'Категория $id', iconName: 'category')).name;
  }
}
